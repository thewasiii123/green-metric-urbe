-- ============================================================
-- guardar_progreso_modulo.sql — GreenMetric_URBE
-- Ejecutar UNA VEZ en el SQL Editor del proyecto de Supabase.
--
-- Reemplaza el INSERT directo que hacía el cliente contra
-- progreso_estudiante (que solo podía REEMPLAZAR xp_ganada y
-- puntaje_obtenido, nunca acumularlos — y sin on_conflict, ni siquiera
-- eso: chocaba con 409 desde la segunda misión de cada módulo).
--
-- Semántica confirmada mission por misión contra el código del cliente
-- (autoload/SupabaseManager.gd, scenes/mapa/SceneMapaMundo.gd) y contra
-- la fila real existente (xp_ganada:16, puntaje_obtenido:40 tras 1/6
-- misiones de Nivel 1 — coincide con int(1/6*100)=16 y
-- XP_POR_MISION[1]=40, así se detectó el cruce de columnas):
--
--   - xp_ganada        → SUMA. El cliente manda el XP fijo de LA
--                         MISIÓN que se acaba de completar (ej. 40 para
--                         cualquier misión de Nivel 1) — es un delta,
--                         no una foto acumulada. Sumarlo reconstruye el
--                         XP real total del módulo.
--   - puntaje_obtenido → GREATEST, nunca suma. El cliente manda
--                         NivelManager.pct_nivel(modulo)*100 — un % ya
--                         completo y recalculado desde cero en cada
--                         llamada, no un delta. GREATEST evita que un
--                         dispositivo con progreso local desactualizado
--                         (el escenario real que motiva esto: un
--                         estudiante que cambia de máquina) pise un %
--                         más alto ya guardado.
--   - completado       → OR. Una vez true, queda true para siempre.
--   - fecha_completado → se fija la primera vez que completado pasa a
--                         true (coalesce), nunca se vuelve a tocar.
--   - intentos         → nueva columna, cuenta cuántas veces se llamó
--                         esta función para ese módulo. Se agrega sola
--                         si no existía.
--   - estudiantes.xp_total → += p_xp_delta, en la misma operación
--                         atómica. El cliente Godot nunca toca la tabla
--                         estudiantes (confirmado: cero referencias en
--                         todo el proyecto) — por eso sigue en 0 hoy.
--
-- SUPUESTO SIN VERIFICAR — revisar antes de correr: que estudiantes.id
-- = auth.uid() (así lo describe el trigger on_auth_user_created de este
-- mismo proyecto Supabase, según el brief de migración de la otra
-- función del juego — no lo confirmé yo mismo, no tengo acceso a la
-- base en esta sesión). Si el nombre de columna o la PK son otros,
-- ajustá el UPDATE de abajo. Si la fila en estudiantes no existe
-- todavía para ese usuario, el UPDATE simplemente no afecta ninguna
-- fila — no rompe la función, pero tampoco avisa. Decime si preferís
-- que sí avise (ej. un RAISE WARNING) en vez de fallar en silencio.
--
-- auth.uid() se usa DENTRO de la función — no se recibe user_id como
-- parámetro — así nadie puede escribir en la fila de otro usuario
-- aunque modifique el cliente. La función NO es security definer: corre
-- con los mismos permisos que ya tiene el cliente autenticado (las
-- políticas RLS actuales ya permiten este INSERT/UPDATE en
-- progreso_estudiante — el POST directo del cliente ya lo demostró con
-- un 201 real). Si estudiantes tiene RLS que bloquee este UPDATE para
-- el rol authenticated, va a hacer falta security definer — no lo puse
-- por defecto para no ampliar permisos sin que lo decidas vos.
-- ============================================================

alter table progreso_estudiante
  add column if not exists intentos int not null default 0;

create or replace function guardar_progreso_modulo(
  p_modulo_id       int,
  p_xp_delta        int,
  p_completitud_pct int,
  p_completado      boolean
) returns void
language plpgsql
as $$
begin
  insert into progreso_estudiante
    (user_id, modulo_id, xp_ganada, puntaje_obtenido, completado, fecha_completado, intentos)
  values
    (auth.uid(), p_modulo_id, p_xp_delta, p_completitud_pct, p_completado,
     case when p_completado then now() else null end, 1)
  on conflict (user_id, modulo_id) do update set
    xp_ganada        = progreso_estudiante.xp_ganada + excluded.xp_ganada,
    puntaje_obtenido = greatest(progreso_estudiante.puntaje_obtenido, excluded.puntaje_obtenido),
    completado       = progreso_estudiante.completado or excluded.completado,
    fecha_completado = coalesce(progreso_estudiante.fecha_completado, excluded.fecha_completado),
    intentos         = progreso_estudiante.intentos + 1;

  update estudiantes
    set xp_total = xp_total + p_xp_delta
    where id = auth.uid();
end;
$$;

-- Los clientes autenticados pueden llamar la función (sujeto a las
-- mismas políticas RLS de siempre, ver nota arriba).
grant execute on function guardar_progreso_modulo(int, int, int, boolean) to authenticated;
