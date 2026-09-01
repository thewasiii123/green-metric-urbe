-- ============================================================
-- eventos_aprendizaje.sql — GreenMetric_URBE
-- Ejecutar UNA VEZ en el SQL Editor del proyecto de Supabase
-- (https://supabase.com/dashboard/project/<tu-proyecto>/sql/new).
--
-- Registro de PROCESO de aprendizaje (cada elección, acierto, fallo
-- e intento, con timestamp) — complementa a progreso_estudiante, que
-- solo guarda el resultado final por módulo. Ver commit
-- "telemetría de aprendizaje" en autoload/SupabaseManager.gd para
-- el código que escribe en esta tabla (SupabaseManager.registrar_evento).
--
-- Para analizar los datos como investigador: consulta esta tabla desde
-- el SQL Editor o la API de Supabase con tu propia sesión de owner del
-- proyecto (el service_role key, no el anon key) — eso ignora las
-- políticas RLS de abajo, que solo restringen al cliente del juego.
-- ============================================================

create table eventos_aprendizaje (
  id           bigint generated always as identity primary key,
  user_id      uuid references auth.users(id),
  session_id   text not null,        -- una por cada vez que se abre el juego
  nivel        int  not null,
  mision_id    text not null,
  tipo_evento  text not null,        -- 'mision_iniciada' | 'opcion_elegida' | 'opcion_quitada' | 'mision_completada'
  correcto     boolean,              -- null si no aplica (ej. mision_iniciada)
  intento_num  int,                  -- 1er intento, 2do, etc. (para medir aprendizaje por repetición)
  detalle      jsonb,                -- texto de la opción elegida, costo, alcance, etc.
  creado_en    timestamptz not null default now()
);

-- Para que cada estudiante solo pueda insertar/leer sus propios eventos
-- desde el juego (cliente anon + su propio JWT).
alter table eventos_aprendizaje enable row level security;

create policy "insertar_propios_eventos" on eventos_aprendizaje
  for insert with check (auth.uid() = user_id);

create policy "leer_propios_eventos" on eventos_aprendizaje
  for select using (auth.uid() = user_id);

-- índice para consultas típicas de análisis ("evolución de X por usuario/misión")
create index idx_eventos_user_mision on eventos_aprendizaje (user_id, mision_id, creado_en);
