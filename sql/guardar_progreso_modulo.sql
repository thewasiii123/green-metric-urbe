-- ============================================================
-- guardar_progreso_modulo.sql — GreenMetric_URBE
--
-- ESTADO: APLICADO en el proyecto Supabase ikohikbpvtbvsgyumvbr
-- el 2026-09-02, en dos migraciones:
--   1. crear_misiones_estudiante
--   2. rpc_guardar_progreso_modulo_idempotente
--
-- Este archivo es la copia fiel de lo que corre en producción.
-- No lo edites sin aplicar el cambio en Supabase también.
-- ============================================================
--
-- POR QUÉ EXISTE
--
-- El cliente hacía POST directo a progreso_estudiante. Tres problemas,
-- en el orden en que se descubrieron:
--
--   1. Sin on_conflict, el INSERT chocaba con el índice único
--      (user_id, modulo_id) y devolvía 409 desde la segunda misión de
--      cada módulo. El progreso se perdía en silencio.
--
--   2. Con on_conflict, el upsert REEMPLAZABA los valores. 23 escrituras
--      dejaban 3 filas con el último valor de cada módulo.
--
--   3. Acumular en vez de reemplazar habría inflado el XP entre 2 y 4
--      veces. Los logs del servidor mostraron que cada misión dispara
--      entre 2 y 4 guardados: los tweens de interior_bloque.gd y
--      mision_solar.gd no tienen guard contra clics repetidos, así que
--      un jugador impaciente genera varias llamadas espaciadas por
--      segundos.
--
-- La solución es hacer la función IDEMPOTENTE por misión: se registra
-- (user_id, mision_id) en misiones_estudiante, y el XP se otorga solo
-- si esa inserción realmente ocurrió. Los duplicados incrementan
-- intentos y actualizan el porcentaje, pero no suman XP.
--
-- Esto además provee el estado por misión que progreso_estudiante no
-- tenía (solo guarda agregados por módulo), necesario para repoblar
-- NivelManager desde el servidor cuando el estudiante cambia de máquina.
--
-- ------------------------------------------------------------
-- SEMÁNTICA DE CADA COLUMNA
-- ------------------------------------------------------------
--   xp_ganada        — SUMA, pero solo del XP de misiones nuevas.
--                      El cliente manda el XP fijo de LA misión recién
--                      completada (un delta, no una foto acumulada).
--   puntaje_obtenido — GREATEST, nunca suma. El cliente manda
--                      NivelManager.pct_nivel(modulo)*100, un porcentaje
--                      recalculado desde cero en cada llamada. GREATEST
--                      evita que un dispositivo con progreso local
--                      desactualizado pise un porcentaje más alto ya
--                      guardado — el escenario real de un estudiante
--                      que cambia de máquina.
--   completado       — OR. Una vez true, queda true para siempre.
--   fecha_completado — coalesce: se fija la primera vez que completado
--                      pasa a true, nunca se vuelve a tocar.
--   intentos         — cuenta TODAS las llamadas, incluidos duplicados.
--                      Útil para detectar los tweens sin guard.
--   estudiantes.xp_total — += solo el XP realmente otorgado, en la misma
--                      operación atómica. El cliente Godot nunca escribe
--                      en la tabla estudiantes.
--
-- ------------------------------------------------------------
-- SEGURIDAD
-- ------------------------------------------------------------
-- auth.uid() se resuelve DENTRO de la función; no se recibe user_id
-- como parámetro, así que nadie puede escribir en la fila de otro
-- usuario aunque modifique el cliente.
--
-- security definer es necesario porque el plan es revocarle al cliente
-- la escritura directa sobre progreso_estudiante y estudiantes.xp_total.
-- Con security invoker, la función se quedaría sin permisos en ese
-- momento. set search_path = public cierra el vector de secuestro de
-- función que reporta el linter de Supabase.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Tabla de estado por misión (deduplicación + repoblado)
-- ------------------------------------------------------------

create table if not exists public.misiones_estudiante (
  user_id       uuid    not null references public.estudiantes(id) on delete cascade,
  modulo_id     integer not null,
  mision_id     text    not null,
  xp_otorgada   integer not null default 0,
  completada_at timestamptz not null default now(),
  primary key (user_id, mision_id)
);

alter table public.misiones_estudiante enable row level security;

-- El estudiante lee las suyas (necesario para repoblar NivelManager).
drop policy if exists "Ver misiones propias" on public.misiones_estudiante;
create policy "Ver misiones propias" on public.misiones_estudiante
  for select using ((select auth.uid()) = user_id);

-- Nadie escribe directo: solo la RPC.
revoke insert, update, delete, truncate on public.misiones_estudiante
  from anon, authenticated;

create index if not exists idx_misiones_user_modulo
  on public.misiones_estudiante (user_id, modulo_id);

-- Columna nueva en progreso_estudiante.
alter table public.progreso_estudiante
  add column if not exists intentos integer not null default 0;


-- ------------------------------------------------------------
-- 2. La RPC
-- ------------------------------------------------------------

create or replace function public.guardar_progreso_modulo(
  p_modulo_id       int,
  p_mision_id       text,
  p_xp_delta        int,
  p_completitud_pct int,
  p_completado      boolean
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user      uuid := auth.uid();
  v_xp        int  := 0;
  v_insertada boolean := false;
begin
  if v_user is null then
    raise exception 'No autenticado' using errcode = '42501';
  end if;

  if p_mision_id is null or trim(p_mision_id) = '' then
    raise exception 'mision_id requerido' using errcode = '22023';
  end if;

  if not exists (select 1 from estudiantes where id = v_user) then
    raise exception 'Perfil de estudiante no encontrado' using errcode = '23503';
  end if;

  -- Solo otorga XP la primera vez que se registra esta misión.
  insert into misiones_estudiante (user_id, modulo_id, mision_id, xp_otorgada)
  values (v_user, p_modulo_id, trim(p_mision_id), greatest(coalesce(p_xp_delta, 0), 0))
  on conflict (user_id, mision_id) do nothing;

  get diagnostics v_insertada = row_count;

  if v_insertada then
    v_xp := greatest(coalesce(p_xp_delta, 0), 0);
  end if;

  insert into progreso_estudiante
    (user_id, modulo_id, xp_ganada, puntaje_obtenido, completado, fecha_completado, intentos)
  values
    (v_user, p_modulo_id, v_xp, coalesce(p_completitud_pct, 0), coalesce(p_completado, false),
     case when coalesce(p_completado, false) then now() else null end, 1)
  on conflict (user_id, modulo_id) do update set
    xp_ganada        = progreso_estudiante.xp_ganada + v_xp,
    puntaje_obtenido = greatest(progreso_estudiante.puntaje_obtenido, excluded.puntaje_obtenido),
    completado       = progreso_estudiante.completado or excluded.completado,
    fecha_completado = coalesce(progreso_estudiante.fecha_completado, excluded.fecha_completado),
    intentos         = progreso_estudiante.intentos + 1;

  if v_xp > 0 then
    update estudiantes set xp_total = xp_total + v_xp where id = v_user;
  end if;

  return jsonb_build_object(
    'xp_otorgada',   v_xp,
    'ya_registrada', not v_insertada
  );
end;
$$;

revoke all on function public.guardar_progreso_modulo(int, text, int, int, boolean)
  from public, anon;
grant execute on function public.guardar_progreso_modulo(int, text, int, int, boolean)
  to authenticated;


-- ============================================================
-- CÓDIGOS DE ERROR QUE PUEDE DEVOLVER
-- ============================================================
--   42501 — No autenticado. Sesión vencida o ausente.
--   22023 — mision_id vacío o nulo.
--   23503 — El perfil del estudiante no existe en la tabla estudiantes.
--            No debería pasar: el trigger on_auth_user_created lo crea
--            al registrarse. Si aparece, hay un problema en ese trigger.
--
-- ============================================================
-- VERIFICACIÓN EJECUTADA AL APLICAR (2026-09-02)
-- ============================================================
-- Seis llamadas simulando clics repetidos: 3 misiones distintas de
-- 40 XP más 3 duplicados.
--
--   xp_ganada        = 120   (no 240)
--   estudiantes.xp_total = 120
--   misiones_estudiante  = 3 filas
--   puntaje_obtenido = 100  (un duplicado con pct 20 no lo bajó)
--   completado       = true (un duplicado con false no lo revirtió)
--   fecha_completado = poblada
--   intentos         = 6
-- ============================================================
