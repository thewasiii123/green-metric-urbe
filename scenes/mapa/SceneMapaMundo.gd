# ============================================================
# SceneMapaMundo.gd — URBE Rangers: Eco-Quest
# Controlador principal del mapa.
# Una zona → una misión única → un NPC propio.
# ============================================================
extends Node2D

const MAPA_ANCHO : float = 1408.0
const MAPA_ALTO  : float =  768.0
const SPAWN_X    : float =  672.0
const SPAWN_Y    : float =  736.0   # avenida principal

const NPC_ESCENA                := preload("res://scenes/mapa/npc_base.tscn")
const QUIZ_ESCENA               := preload("res://scenes/ui/quiz_npc.tscn")
const DIALOGO_ESCENA            := preload("res://scenes/ui/dialogo_npc.tscn")
const MISION_INICIO_ESCENA      := preload("res://scenes/ui/mision_inicio.gd")
const MINIJUEGO_RESIDUOS_ESCENA := preload("res://scenes/ui/minijuego_residuos.gd")
const TUTORIAL_ESCENA           := preload("res://scenes/ui/tutorial_onboarding.gd")
const CRISIS_ESCENA             := preload("res://scenes/ui/crisis_evento.gd")
const LEADERBOARD_ESCENA        := preload("res://scenes/ui/leaderboard.gd")
const SIMULADOR_ESCENA          := preload("res://scenes/ui/simulador_decision.gd")
const RESULTADOS_ESCENA         := preload("res://scenes/ui/resultados_greenmetric.gd")
const ZONA_VERDE_ESCENA         := preload("res://scenes/mapa/zona_verde.gd")

# ── Sistema de niveles ───────────────────────────────────────
const NIVELES : Array = [
	{"nombre": "Semilla",      "xp_min": 0,     "xp_max": 500},
	{"nombre": "Brote",        "xp_min": 500,   "xp_max": 1500},
	{"nombre": "Árbol",        "xp_min": 1500,  "xp_max": 3500},
	{"nombre": "Estratega",    "xp_min": 3500,  "xp_max": 7000},
	{"nombre": "Investigador", "xp_min": 7000,  "xp_max": 12000},
	{"nombre": "EcoLíder",     "xp_min": 12000, "xp_max": 12000},
]

# ── Datos de los NPCs (uno por zona) ─────────────────────────
var DATOS_NPCS : Array = [
	# ── M6 Educación ────────────────────────────────────────
	{
		"nombre":    "Rector Morales",
		"mision_id": "mision_rector",
		"pos":       Vector2(672, 592),   # paso fila 2→3 (32px), frente norte Rectorado
		"color":     Color(0.5, 0.1, 0.9),
		"dialogos":  PackedStringArray([
			"Bienvenido, Eco-Ranger. Soy el Rector de URBE.",
			"Nuestro campus participa en el ranking UI GreenMetric, que evalua sostenibilidad universitaria.",
			"Necesito que hables con los coordinadores del campus y recopiles el reporte de cada modulo.",
			"El ranking evalua 6 modulos: Entorno, Energia, Residuos, Agua, Transporte y Educacion."
		])
	},
	{
		"nombre":    "Dra. Luna",
		"mision_id": "mision_educacion",
		"pos":       Vector2(1128, 656),   # camino vertical derecho, junto a Área Servicios
		"color":     Color(0.35, 0.0, 0.65),
		"dialogos":  PackedStringArray([
			"Por fin llegas! Soy la Dra. Luna, coordinadora de Educacion e Investigacion.",
			"Este modulo evalua materias de sostenibilidad, publicaciones cientificas e iniciativas del campus.",
			"URBE tiene 3 asignaturas ambientales, pero necesitamos mas investigacion publicada en revistas.",
			"Responde este cuestionario final sobre el modulo de Educacion e Investigacion."
		])
	},
	# ── M2 Energía ──────────────────────────────────────────
	{
		"nombre":    "Prof. González",
		"mision_id": "mision_bloque_a",
		"pos":       Vector2(520, 384),   # paso fila 1→2 (32px), frente norte Bloque A
		"color":     Color(0.9, 0.45, 0.0),
		"dialogos":  PackedStringArray([
			"Hola! Soy el Prof. Gonzalez, docente del Bloque A.",
			"Este bloque concentra aulas con alto consumo de electricidad por aire acondicionado.",
			"Segun GreenMetric, debemos apagar los equipos al salir y optar por iluminacion LED.",
			"Responde este cuestionario sobre eficiencia energetica en aulas universitarias."
		])
	},
	{
		"nombre":    "Dr. Pérez",
		"mision_id": "mision_bloque_b",
		"pos":       Vector2(648, 488),   # entre Bloque A y Bloque B
		"color":     Color(0.85, 0.35, 0.0),
		"dialogos":  PackedStringArray([
			"Doctor Perez, coordinador de Energia y Cambio Climatico.",
			"El Bloque B aloja laboratorios con equipos de alto consumo electrico.",
			"GreenMetric penaliza el uso de energias no renovables y las altas emisiones de CO2.",
			"Responde estas preguntas sobre energia y cambio climatico en el campus."
		])
	},
	{
		"nombre":    "Ing. Herrera",
		"mision_id": "mision_bloque_c",
		"pos":       Vector2(440, 656),   # camino centro-izq, junto a Bloque C
		"color":     Color(0.95, 0.55, 0.0),
		"dialogos":  PackedStringArray([
			"Buenas! Soy la Ing. Herrera, tecnica del Bloque C.",
			"El Bloque C tiene problemas de iluminacion: muchas luces incandescentes sin control de horario.",
			"Cambiar a LED y usar sensores de movimiento reduciria el consumo un 40%.",
			"Pon a prueba lo que sabes sobre gestion energetica en edificios universitarios."
		])
	},
	{
		"nombre":    "Técn. Ruiz",
		"mision_id": "mision_bloque_d",
		"pos":       Vector2(440, 488),   # camino centro-izq, junto a Bloque D
		"color":     Color(0.80, 0.40, 0.0),
		"dialogos":  PackedStringArray([
			"Hola! Soy el Tecn. Ruiz, responsable de instalaciones del Bloque D.",
			"Hemos instalado paneles solares en el techo del Bloque D este semestre.",
			"Segun GreenMetric, el uso de energias renovables mejora significativamente el puntaje.",
			"Demuestra tus conocimientos sobre energias renovables y sostenibilidad campus."
		])
	},
	{
		"nombre":    "Coord. Salinas",
		"mision_id": "mision_bloque_e",
		"pos":       Vector2(768, 190),   # camino superior, frente a Bloque E
		"color":     Color(0.90, 0.50, 0.05),
		"dialogos":  PackedStringArray([
			"Soy la Coord. Salinas, encargada del Bloque E norte del campus.",
			"El Bloque E tiene laboratorios de computo con alto consumo energetico.",
			"Necesitamos medir el consumo exacto de cada equipo para el reporte GreenMetric.",
			"Responde sobre el modulo de Energia y Cambio Climatico del campus."
		])
	},
	# ── M1 Entorno e Infraestructura ────────────────────────
	{
		"nombre":    "Ing. Ramírez",
		"mision_id": "mision_bloque_f",
		"pos":       Vector2(1128, 392),   # camino vertical derecho, junto a Bloque F
		"color":     Color(0.2, 0.7, 0.2),
		"dialogos":  PackedStringArray([
			"Hola! Soy la Ing. Ramirez, coordinadora de Entorno e Infraestructura.",
			"El Bloque F es el edificio mas grande del campus, con jardines circundantes.",
			"GreenMetric exige que al menos el 25% del campus sea area verde con politica ambiental.",
			"Responde este cuestionario sobre el modulo de Entorno e Infraestructura."
		])
	},
	{
		"nombre":    "Arq. Fernández",
		"mision_id": "mision_bloque_g",
		"pos":       Vector2(216, 488),   # camino izquierdo, junto a Bloque G
		"color":     Color(0.25, 0.75, 0.25),
		"dialogos":  PackedStringArray([
			"Hola! Soy el Arq. Fernandez, supervisor de infraestructura del Bloque G.",
			"El Bloque G tiene jardines internos que contribuyen al area verde del campus.",
			"GreenMetric valora los espacios verdes y las certificaciones ecologicas institucionales.",
			"Responde sobre infraestructura sostenible y areas verdes en la universidad."
		])
	},
	{
		"nombre":    "Sr. Blanco",
		"mision_id": "mision_fotocopiado",
		"pos":       Vector2(168, 656),   # entre Fotocopiado y camino izquierdo
		"color":     Color(0.3, 0.65, 0.3),
		"dialogos":  PackedStringArray([
			"Buenas! Soy el Sr. Blanco, del Centro de Fotocopiado.",
			"Imprimimos miles de hojas diarias, generando residuos de papel que afectan el puntaje.",
			"GreenMetric evalua las politicas de reduccion de papel y consumo responsable de recursos.",
			"Responde sobre el manejo del papel y recursos en el campus universitario."
		])
	},
	# ── M4 Agua ─────────────────────────────────────────────
	{
		"nombre":    "Lic. Torres",
		"mision_id": "mision_agua",
		"pos":       Vector2(568, 190),   # camino superior, frente a Biblioteca
		"color":     Color(0.0, 0.55, 0.75),
		"dialogos":  PackedStringArray([
			"Buenas, soy la Lic. Torres, responsable del modulo de Agua.",
			"GreenMetric evalua si el campus tiene programas de conservacion hidrica y medidores de consumo.",
			"Problema: la Biblioteca consume mucha agua pero no tenemos hidrometros instalados.",
			"Responde este cuestionario sobre gestion del agua en el campus universitario."
		])
	},
	# ── M5 Transporte ───────────────────────────────────────
	{
		"nombre":    "Carlos",
		"mision_id": "mision_transporte",
		"pos":       Vector2(216, 288),   # camino izquierdo, junto a Estacionamiento
		"color":     Color(0.1, 0.3, 0.8),
		"dialogos":  PackedStringArray([
			"Hola! Soy Carlos, coordinador de Transporte Sostenible.",
			"GreenMetric mide cuantos estudiantes usan transporte publico, bicicleta o caminan al campus.",
			"Actualmente el 78% llega en vehiculo privado. Tenemos el Estacionamiento M5 siempre lleno.",
			"Responde sobre movilidad sostenible y el modulo de Transporte del campus."
		])
	},
	# ── M3 Residuos ─────────────────────────────────────────
	{
		"nombre":    "Yulimar",
		"mision_id": "mision_residuos",
		"pos":       Vector2(440, 288),   # camino centro-izq, junto a Cafetín
		"color":     Color(0.85, 0.75, 0.0),
		"dialogos":  PackedStringArray([
			"Eco-Ranger! Soy Yulimar, del comite estudiantil de reciclaje.",
			"El campus genera residuos diariamente, pero solo el 30% se clasifica correctamente.",
			"GreenMetric penaliza la falta de contenedores diferenciados y programas de compostaje.",
			"Ahora pon a prueba tus conocimientos clasificando los residuos del campus."
		])
	},
]

# ── Zona → misión (lookup directo por zona_key, sin ambigüedad) ─
var ZONA_A_MISION : Dictionary = {
	"ZonaRectorado":       {"mision_id": "mision_rector",      "modulo_id": 6, "npc": "Rector Morales", "progreso": 0.55},
	"ZonaAreaServicios":   {"mision_id": "mision_educacion",   "modulo_id": 6, "npc": "Dra. Luna",      "progreso": 0.55},
	"ZonaBloqueA":         {"mision_id": "mision_bloque_a",    "modulo_id": 2, "npc": "Prof. González", "progreso": 0.38},
	"ZonaBloqueB":         {"mision_id": "mision_bloque_b",    "modulo_id": 2, "npc": "Dr. Pérez",      "progreso": 0.42},
	"ZonaBloqueC":         {"mision_id": "mision_bloque_c",    "modulo_id": 2, "npc": "Ing. Herrera",   "progreso": 0.35},
	"ZonaBloqueD":         {"mision_id": "mision_bloque_d",    "modulo_id": 2, "npc": "Técn. Ruiz",     "progreso": 0.45},
	"ZonaBloqueE":         {"mision_id": "mision_bloque_e",    "modulo_id": 2, "npc": "Coord. Salinas", "progreso": 0.40},
	"ZonaBloqueF":         {"mision_id": "mision_bloque_f",    "modulo_id": 1, "npc": "Ing. Ramírez",   "progreso": 0.35},
	"ZonaBloqueG":         {"mision_id": "mision_bloque_g",    "modulo_id": 1, "npc": "Arq. Fernández", "progreso": 0.40},
	"ZonaFotocopiado":     {"mision_id": "mision_fotocopiado", "modulo_id": 1, "npc": "Sr. Blanco",     "progreso": 0.25},
	"ZonaBiblioteca":      {"mision_id": "mision_agua",        "modulo_id": 4, "npc": "Lic. Torres",    "progreso": 0.45},
	"ZonaEstacionamiento": {"mision_id": "mision_transporte",  "modulo_id": 5, "npc": "Carlos",         "progreso": 0.22},
	"ZonaCafetin":         {"mision_id": "mision_residuos",    "modulo_id": 3, "npc": "Yulimar",        "progreso": 0.30},
}

# ── Quiz por misión ──────────────────────────────────────────
const QUIZ_POR_MISION : Dictionary = {
	# M6 - Educación
	"mision_rector": [
		{"pregunta": "¿Cuántos módulos evalúa el ranking UI GreenMetric?",
		 "opciones": ["3 módulos", "6 módulos", "10 módulos"], "correcta": 1},
		{"pregunta": "¿Qué evalúa principalmente el ranking UI GreenMetric?",
		 "opciones": ["La calidad académica", "Los deportes universitarios", "La sostenibilidad universitaria"], "correcta": 2},
		{"pregunta": "¿Qué institución participa en GreenMetric en este juego?",
		 "opciones": ["UCV", "URBE", "UCAB"], "correcta": 1}
	],
	"mision_educacion": [
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Educación?",
		 "opciones": ["Deportes universitarios", "Idiomas impartidos", "Asignaturas de sostenibilidad e investigación"], "correcta": 2},
		{"pregunta": "¿Cuántas asignaturas ambientales tiene URBE actualmente?",
		 "opciones": ["3 asignaturas", "10 asignaturas", "0 asignaturas"], "correcta": 0},
		{"pregunta": "¿Qué necesita URBE para mejorar en el módulo de Educación?",
		 "opciones": ["Más estacionamientos", "Nuevas canchas deportivas", "Más investigación publicada en revistas"], "correcta": 2}
	],
	# M2 - Energía (preguntas únicas por bloque)
	"mision_bloque_a": [
		{"pregunta": "¿Qué equipo en las aulas consume más electricidad en el campus?",
		 "opciones": ["Computadoras", "Aire acondicionado", "Iluminación LED"], "correcta": 1},
		{"pregunta": "¿Qué hábito reduce el consumo eléctrico en aulas universitarias?",
		 "opciones": ["Dejar equipos en espera", "Apagar luces y equipos al salir", "Aumentar la ventilación"], "correcta": 1},
		{"pregunta": "¿Qué tipo de iluminación recomienda GreenMetric para edificios?",
		 "opciones": ["Incandescente", "Fluorescente", "LED de bajo consumo"], "correcta": 2}
	],
	"mision_bloque_b": [
		{"pregunta": "¿Por qué los laboratorios consumen más energía que las aulas normales?",
		 "opciones": ["Tienen más ventanas", "Usan equipos especializados de alto consumo", "Tienen más estudiantes"], "correcta": 1},
		{"pregunta": "¿Qué gas de efecto invernadero se reduce al usar energías renovables?",
		 "opciones": ["Oxígeno", "CO₂", "Nitrógeno"], "correcta": 1},
		{"pregunta": "¿Qué tipo de energía favorece GreenMetric para campus universitarios?",
		 "opciones": ["Combustibles fósiles", "Energías renovables como solar y eólica", "Energía nuclear"], "correcta": 1}
	],
	"mision_bloque_c": [
		{"pregunta": "¿Cuántos bloques de aulas principales tiene el campus URBE?",
		 "opciones": ["3 bloques", "5 bloques (A, B, C, D y E)", "7 bloques"], "correcta": 1},
		{"pregunta": "¿Qué impacto tiene el aire acondicionado sin mantenimiento?",
		 "opciones": ["Ahorra energía", "Aumenta el consumo hasta un 30% más", "No tiene impacto"], "correcta": 1},
		{"pregunta": "¿Qué sensor reduce el consumo de iluminación en pasillos vacíos?",
		 "opciones": ["Sensor de movimiento", "Sensor de temperatura", "Sensor de humedad"], "correcta": 0}
	],
	"mision_bloque_d": [
		{"pregunta": "¿Qué tecnología permite al Bloque D generar energía limpia?",
		 "opciones": ["Turbinas de viento", "Paneles solares fotovoltaicos", "Generadores diésel"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Energía y Cambio Climático?",
		 "opciones": ["Consumo eléctrico, renovables y emisiones de CO₂", "Número de estudiantes", "Velocidad del internet"], "correcta": 0},
		{"pregunta": "¿Cuánto puede reducir el consumo un edificio con energía solar?",
		 "opciones": ["Nada", "Hasta un 40% del consumo total", "Exactamente un 100%"], "correcta": 1}
	],
	"mision_bloque_e": [
		{"pregunta": "¿Qué tipo de equipos tiene el Bloque E que aumentan el consumo?",
		 "opciones": ["Equipos de jardinería", "Laboratorios de cómputo", "Gimnasio universitario"], "correcta": 1},
		{"pregunta": "¿Qué herramienta mide el consumo exacto de energía por equipo?",
		 "opciones": ["Termómetro", "Vatímetro (medidor de vatios)", "Barómetro"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric sobre el Cambio Climático en universidades?",
		 "opciones": ["Las emisiones de CO₂ del campus", "La temperatura del salón", "La lluvia anual"], "correcta": 0}
	],
	# M1 - Entorno e Infraestructura
	"mision_bloque_f": [
		{"pregunta": "¿Qué evalúa GreenMetric en Entorno e Infraestructura?",
		 "opciones": ["Espacios verdes y políticas ambientales", "Número de laboratorios", "Tamaño de las aulas"], "correcta": 0},
		{"pregunta": "¿Cuál es el edificio principal al este del campus URBE?",
		 "opciones": ["Biblioteca", "Bloque F", "Estacionamiento M5"], "correcta": 1},
		{"pregunta": "¿Qué mejora la puntuación en infraestructura según GreenMetric?",
		 "opciones": ["Más cafeterías", "Certificaciones ambientales", "Más plazas de parqueo"], "correcta": 1}
	],
	"mision_bloque_g": [
		{"pregunta": "¿Qué beneficio ambiental aportan los jardines internos de un edificio?",
		 "opciones": ["Aumentan la temperatura", "Reducen CO₂ y mejoran la biodiversidad", "Solo decoración"], "correcta": 1},
		{"pregunta": "¿Cuánta área verde mínima requiere GreenMetric en un campus sostenible?",
		 "opciones": ["Al menos el 5%", "Al menos el 25%", "Al menos el 60%"], "correcta": 1},
		{"pregunta": "¿Qué certifica una política ambiental institucional?",
		 "opciones": ["El número de edificios", "El compromiso formal con la sostenibilidad", "El tamaño del campus"], "correcta": 1}
	],
	"mision_fotocopiado": [
		{"pregunta": "¿Cuántos árboles se necesitan para producir 1 tonelada de papel?",
		 "opciones": ["2 árboles", "17 árboles", "50 árboles"], "correcta": 1},
		{"pregunta": "¿Qué práctica reduce el impacto ambiental del papel en la universidad?",
		 "opciones": ["Imprimir más en papel reciclado", "Usar documentos digitales y reducir impresiones", "Usar papel de mayor gramaje"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric sobre el consumo de papel en el campus?",
		 "opciones": ["Solo la cantidad de impresoras", "Las políticas de reducción y uso eficiente de recursos", "El precio del papel"], "correcta": 1}
	],
	# M4 - Agua
	"mision_agua": [
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Agua?",
		 "opciones": ["Tamaño de la piscina", "Programas de conservación hídrica y medidores", "Número de bebederos"], "correcta": 1},
		{"pregunta": "¿Qué instrumento mide el consumo de agua en un edificio?",
		 "opciones": ["Termómetro", "Barómetro", "Hidrómetro"], "correcta": 2},
		{"pregunta": "¿Cuál es el problema del agua en la Biblioteca?",
		 "opciones": ["No tiene agua potable", "Tiene la piscina cerrada", "Consume mucha agua sin hidrómetros"], "correcta": 2}
	],
	# M5 - Transporte
	"mision_transporte": [
		{"pregunta": "¿Qué porcentaje de estudiantes llega al campus en vehículo privado?",
		 "opciones": ["50%", "78%", "30%"], "correcta": 1},
		{"pregunta": "¿Qué tipo de transporte favorece GreenMetric?",
		 "opciones": ["Solo automóviles privados", "Motocicletas particulares", "Transporte público y bicicleta"], "correcta": 2},
		{"pregunta": "¿Qué propone Carlos para mejorar la movilidad sostenible?",
		 "opciones": ["Ampliar el estacionamiento M5", "Crear ciclovías en el campus", "Prohibir el transporte público"], "correcta": 1}
	],
	# M3 - Residuos → usa minijuego, pero quiz se define por si acaso
	"mision_residuos": [
		{"pregunta": "¿Cuál de estos es un residuo reciclable?",
		 "opciones": ["Cáscara de banana", "Botella de plástico PET", "Papel mojado con aceite"], "correcta": 1},
		{"pregunta": "¿Qué color de contenedor corresponde a residuos orgánicos?",
		 "opciones": ["Azul", "Rojo", "Marrón/Verde"], "correcta": 2},
		{"pregunta": "¿Qué porcentaje de residuos se clasifica correctamente en el campus?",
		 "opciones": ["30%", "75%", "90%"], "correcta": 0}
	],
}

# ── Referencias a nodos ──────────────────────────────────────
@onready var jugador      : CharacterBody2D = $Jugador
@onready var camara       : Camera2D        = $Jugador/Camera2D
@onready var zonas_campus : Node2D          = $ZonasCampus
@onready var mapa_campus  : Node2D          = $FondoCampus

# ── Estado ───────────────────────────────────────────────────
var _xp_total           : int         = 0
var _nivel_actual       : int         = 0
var _modulo_activo      : int         = -1
var _nombre_activo      : String      = ""
var _zona_activa        : String      = ""
var _mision_activa      : String      = ""
var _quiz_ui            : CanvasLayer = null
var _mision_ui          : CanvasLayer = null
var _dialogo_ui         : CanvasLayer = null
var _minijuego_residuos : CanvasLayer = null

# ── HUD principal ────────────────────────────────────────────
var _hud_canvas      : CanvasLayer = null
var _hud_nombre_lbl  : Label       = null
var _hud_nivel_lbl   : Label       = null
var _hud_barra_bg    : ColorRect   = null
var _hud_barra_fill  : ColorRect   = null
var _hud_xp_lbl      : Label       = null
var _zona_panel      : Panel       = null
var _zona_icono_lbl  : Label       = null
var _zona_nombre_lbl : Label       = null
var _zona_hint_lbl   : Label       = null
var _celebracion_lbl : Label       = null

# ── Sidebar de módulos ────────────────────────────────────────
var _sidebar_fills  : Array = []   # Array[ColorRect]
var _sidebar_pcts   : Array = []   # Array[Label]

# ── Notificación de zona ──────────────────────────────────────
var _notif_zona_lbl : Label = null

# ── Panel de misión completada ────────────────────────────────
var _complete_panel  : Panel  = null
var _complete_titulo : Label  = null
var _complete_xp     : Label  = null
var _complete_barra  : ColorRect = null

# ── Contador de XP flotante ───────────────────────────────────
var _xp_float_offset : int = 0

# ── Sistemas EVA ─────────────────────────────────────────────
var _tutorial_ui      : CanvasLayer = null
var _crisis_ui        : CanvasLayer = null
var _leaderboard_ui   : CanvasLayer = null
var _sim_decision_ui  : CanvasLayer = null
var _resultados_ui    : CanvasLayer = null
var _zonas_verdes     : Array       = []   # Array[Node2D]
var _timer_crisis     : float       = 0.0
const _CRISIS_MIN     : float       = 90.0
const _CRISIS_MAX     : float       = 180.0
var _hud_creditos_lbl : Label       = null
var _hud_energia_lbl  : Label       = null
var _insignia_lbl     : Label       = null

# ── Progreso de módulos (copia local para sidebar) ────────────
var _progreso_modulos : Dictionary = {1: 0.35, 2: 0.40, 3: 0.30, 4: 0.45, 5: 0.22, 6: 0.55}

const SIDEBAR_MODULOS : Array = [
	{"id": 1, "icono": "🌿", "nombre": "Entorno",    "color": Color(0.18, 0.55, 0.20)},
	{"id": 2, "icono": "⚡", "nombre": "Energía",    "color": Color(0.90, 0.50, 0.00)},
	{"id": 3, "icono": "♻", "nombre": "Residuos",   "color": Color(0.80, 0.65, 0.00)},
	{"id": 4, "icono": "💧", "nombre": "Agua",       "color": Color(0.00, 0.45, 0.75)},
	{"id": 5, "icono": "🚲", "nombre": "Transporte", "color": Color(0.10, 0.30, 0.80)},
	{"id": 6, "icono": "📚", "nombre": "Educación",  "color": Color(0.40, 0.00, 0.70)},
]


func _ready() -> void:
	jugador.global_position = Vector2(SPAWN_X, SPAWN_Y)
	jugador.z_index = 2

	camara.limit_left   = 0
	camara.limit_top    = 0
	camara.limit_right  = int(MAPA_ANCHO)
	camara.limit_bottom = int(MAPA_ALTO)
	camara.zoom         = Vector2(1.5, 1.5)

	_construir_hud()
	_construir_sidebar()
	_construir_notificacion_zona()
	_construir_panel_completado()
	_actualizar_hud()

	# Conectar señal de interacción del jugador para efecto de cámara
	jugador.interaccion_iniciada.connect(_on_interaccion_iniciada)

	if $ZonasCampus:
		zonas_campus.zona_activada.connect(_on_zona_activada)
		zonas_campus.zona_salida.connect(_on_zona_salida)

	_spawn_npcs()

	_mision_ui = MISION_INICIO_ESCENA.new()
	add_child(_mision_ui)
	_mision_ui.mision_aceptada.connect(_on_mision_aceptada)
	_mision_ui.mision_cancelada.connect(_on_mision_cancelada)

	_dialogo_ui = DIALOGO_ESCENA.instantiate()
	add_child(_dialogo_ui)
	_dialogo_ui.dialogo_terminado.connect(_on_dialogo_terminado)

	_quiz_ui = QUIZ_ESCENA.instantiate()
	add_child(_quiz_ui)
	_quiz_ui.quiz_completado.connect(_on_quiz_completado)

	_minijuego_residuos = MINIJUEGO_RESIDUOS_ESCENA.new()
	add_child(_minijuego_residuos)
	_minijuego_residuos.minijuego_completado.connect(_on_minijuego_completado)

	if has_node("CanvasLayer"):
		$CanvasLayer.visible = false

	SupabaseManager.modulos_cargados.connect(_on_modulos_cargados)
	SupabaseManager.progreso_cargado.connect(_on_progreso_cargado)
	SupabaseManager.cargar_modulos()
	SupabaseManager.cargar_progreso()

	_init_sistemas_eva()


# ── HUD ──────────────────────────────────────────────────────
func _construir_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 5
	add_child(_hud_canvas)

	var panel_top := Panel.new()
	panel_top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_top.offset_right  = 310.0
	panel_top.offset_bottom = 78.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.10, 0.92)
	ps.border_color = Color(0.20, 0.68, 0.20)
	ps.set_border_width_all(2)
	ps.corner_radius_bottom_left  = 10
	ps.corner_radius_bottom_right = 10
	panel_top.add_theme_stylebox_override("panel", ps)
	_hud_canvas.add_child(panel_top)

	_hud_nombre_lbl = Label.new()
	_hud_nombre_lbl.position = Vector2(10, 6)
	_hud_nombre_lbl.add_theme_font_size_override("font_size", 13)
	_hud_nombre_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 0.25))
	_hud_canvas.add_child(_hud_nombre_lbl)

	_hud_nivel_lbl = Label.new()
	_hud_nivel_lbl.position = Vector2(130, 6)
	_hud_nivel_lbl.add_theme_font_size_override("font_size", 11)
	_hud_nivel_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	_hud_canvas.add_child(_hud_nivel_lbl)

	_hud_barra_bg = ColorRect.new()
	_hud_barra_bg.position = Vector2(10, 32)
	_hud_barra_bg.size     = Vector2(240, 12)
	_hud_barra_bg.color    = Color(0.10, 0.14, 0.20)
	_hud_canvas.add_child(_hud_barra_bg)

	_hud_barra_fill = ColorRect.new()
	_hud_barra_fill.position = Vector2(10, 32)
	_hud_barra_fill.size     = Vector2(0, 12)
	_hud_barra_fill.color    = Color(0.18, 0.78, 0.28)
	_hud_canvas.add_child(_hud_barra_fill)

	_hud_xp_lbl = Label.new()
	_hud_xp_lbl.position = Vector2(256, 30)
	_hud_xp_lbl.add_theme_font_size_override("font_size", 10)
	_hud_xp_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	_hud_canvas.add_child(_hud_xp_lbl)

	# Panel de zona (centro inferior)
	_zona_panel = Panel.new()
	_zona_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_zona_panel.offset_top    = -72.0
	_zona_panel.offset_bottom =   0.0
	_zona_panel.offset_left   = 200.0
	_zona_panel.offset_right  = -200.0
	var zps := StyleBoxFlat.new()
	zps.bg_color     = Color(0.04, 0.07, 0.10, 0.90)
	zps.border_color = Color(0.20, 0.68, 0.20)
	zps.set_border_width_all(2)
	zps.corner_radius_top_left  = 10
	zps.corner_radius_top_right = 10
	_zona_panel.add_theme_stylebox_override("panel", zps)
	_zona_panel.visible = false
	_hud_canvas.add_child(_zona_panel)

	_zona_icono_lbl = Label.new()
	_zona_icono_lbl.position = Vector2(14, 8)
	_zona_icono_lbl.add_theme_font_size_override("font_size", 22)
	_zona_panel.add_child(_zona_icono_lbl)

	_zona_nombre_lbl = Label.new()
	_zona_nombre_lbl.position = Vector2(48, 8)
	_zona_nombre_lbl.add_theme_font_size_override("font_size", 13)
	_zona_nombre_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 0.25))
	_zona_panel.add_child(_zona_nombre_lbl)

	_zona_hint_lbl = Label.new()
	_zona_hint_lbl.position = Vector2(48, 36)
	_zona_hint_lbl.add_theme_font_size_override("font_size", 11)
	_zona_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.55))
	_zona_hint_lbl.text = "[E] Comenzar misión"
	_zona_panel.add_child(_zona_hint_lbl)

	_celebracion_lbl = Label.new()
	_celebracion_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_celebracion_lbl.offset_left   = -220
	_celebracion_lbl.offset_top    =  70
	_celebracion_lbl.offset_right  =  220
	_celebracion_lbl.offset_bottom =  130
	_celebracion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_celebracion_lbl.add_theme_font_size_override("font_size", 24)
	_celebracion_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.10))
	_celebracion_lbl.visible = false
	_hud_canvas.add_child(_celebracion_lbl)


func _spawn_npcs() -> void:
	for datos in DATOS_NPCS:
		var npc : Area2D = NPC_ESCENA.instantiate()
		npc.nombre_npc = datos["nombre"]
		npc.mision_id  = datos["mision_id"]
		npc.dialogos   = datos["dialogos"]
		npc.color      = datos["color"]
		npc.position   = datos["pos"]
		npc.z_index    = 1
		npc.get_node("Visual").modulate = datos["color"]
		add_child(npc)
	print("✅ %d NPCs instanciados" % DATOS_NPCS.size())


# ── Supabase ─────────────────────────────────────────────────
func _on_modulos_cargados(lista: Array) -> void:
	print("📦 Módulos cargados: %d" % lista.size())

func _on_progreso_cargado(lista: Array) -> void:
	for entrada in lista:
		_xp_total += entrada.get("xp_ganada", 0)
	_actualizar_hud()


# ── Zonas ────────────────────────────────────────────────────
const ZONA_ICONOS : Dictionary = {1: "🌿", 2: "⚡", 3: "♻", 4: "💧", 5: "🚲", 6: "📚"}

func _on_zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	_zona_activa   = zona_key
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo
	_zona_icono_lbl.text  = ZONA_ICONOS.get(modulo_id, "🌍")
	_zona_nombre_lbl.text = nombre_modulo
	_zona_panel.visible   = true
	# Notificación de zona en pantalla
	var icono_txt : String = ZONA_ICONOS.get(modulo_id, "🌍")
	var col : Color = _color
	for info : Dictionary in SIDEBAR_MODULOS:
		if int(info["id"]) == modulo_id:
			col = info["color"]
			break
	_mostrar_notificacion_zona(icono_txt, nombre_modulo, col)

func _on_zona_salida() -> void:
	_zona_panel.visible = false
	_zona_activa        = ""
	_modulo_activo      = -1
	_nombre_activo      = ""


# ── Input ────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_E:
		return
	if (_dialogo_ui and _dialogo_ui.visible) or (_quiz_ui and _quiz_ui.visible):
		return
	if _mision_ui and _mision_ui.visible:
		return
	if _minijuego_residuos and _minijuego_residuos.visible:
		return
	if _zona_activa != "":
		_mostrar_pantalla_mision()
	else:
		_verificar_zona_verde_cercana()


# ── Pantalla de misión ───────────────────────────────────────
func _mostrar_pantalla_mision() -> void:
	if not ZONA_A_MISION.has(_zona_activa):
		return
	var info = ZONA_A_MISION[_zona_activa]
	_mision_ui.mostrar(info["modulo_id"], _nombre_activo, info["npc"], info["mision_id"], info["progreso"])


func _on_mision_aceptada(mision_id: String) -> void:
	_mision_activa = mision_id
	for datos in DATOS_NPCS:
		if datos["mision_id"] == mision_id:
			if _dialogo_ui:
				_dialogo_ui.iniciar(datos["nombre"], datos["dialogos"], mision_id, datos["color"])
			return

func _on_mision_cancelada() -> void:
	pass


# ── Diálogo → lanza quiz o minijuego según misión ────────────
func _on_dialogo_terminado(mision_id: String) -> void:
	if mision_id == "":
		return

	# M3 Residuos → minijuego de clasificación
	if mision_id == "mision_residuos":
		if _minijuego_residuos:
			_minijuego_residuos.iniciar()
		return

	# Resto de misiones → quiz
	if not is_instance_valid(_quiz_ui):
		return
	if not QUIZ_POR_MISION.has(mision_id):
		return
	var nombre : String = "NPC"
	for d in DATOS_NPCS:
		if d["mision_id"] == mision_id:
			nombre = d["nombre"]
			break
	_quiz_ui.iniciar(QUIZ_POR_MISION[mision_id], nombre)


# ── Callbacks de completado ───────────────────────────────────
func _on_quiz_completado(xp: int) -> void:
	_aplicar_xp(xp, _mision_activa)
	EconomiaManager.on_modulo_completado(_modulo_activo, xp, 30)

func _on_minijuego_completado(xp: int) -> void:
	_aplicar_xp(xp, "mision_residuos")
	EconomiaManager.ganar_creditos(xp / 5)

func _aplicar_xp(xp: int, mision_id: String) -> void:
	var nivel_antes := _nivel_actual
	_xp_total += xp
	_actualizar_hud()
	if xp > 0:
		_flotar_xp(xp)
		_sfx("xp_bonus" if xp >= 20 else "xp")

	print("✅ XP ganada: %d  |  Total: %d  |  Misión: %s" % [xp, _xp_total, mision_id])

	if _nivel_actual > nivel_antes:
		_mostrar_celebracion(NIVELES[_nivel_actual]["nombre"])
		_sfx("nivel")

	# Actualiza progreso de la zona/misión completada y refresca mapa
	for zona_key in ZONA_A_MISION.keys():
		var info : Dictionary = ZONA_A_MISION[zona_key]
		if info["mision_id"] == mision_id:
			var nuevo : float = clampf(float(info["progreso"]) + 0.20, 0.0, 1.0)
			ZONA_A_MISION[zona_key]["progreso"] = nuevo
			var mod_id : int = int(info["modulo_id"])
			if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
				mapa_campus.actualizar_modulo(mod_id, nuevo)
			# Actualiza dict de progreso para sidebar y persiste
			_progreso_modulos[mod_id] = nuevo
			_actualizar_sidebar()
			_mostrar_mision_completada(mision_id, xp)
			# Persistir en Supabase
			if SupabaseManager and SupabaseManager.has_method("guardar_progreso"):
				SupabaseManager.guardar_progreso(mod_id, xp, int(nuevo * 100), nuevo >= 1.0)
			_sfx("mision")
			_verificar_misiones_completadas()
			break


# ── Celebración ──────────────────────────────────────────────
func _mostrar_celebracion(nombre_nivel: String) -> void:
	if not _celebracion_lbl:
		return
	_celebracion_lbl.text     = "⭐ ¡NIVEL SUBIDO!\n%s" % nombre_nivel.to_upper()
	_celebracion_lbl.modulate = Color(1, 1, 0.2, 0.0)
	_celebracion_lbl.scale    = Vector2(0.5, 0.5)
	_celebracion_lbl.visible  = true

	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_celebracion_lbl, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_celebracion_lbl, "scale", Vector2(1.15, 1.15), 0.22)
	tw.tween_property(_celebracion_lbl, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_interval(2.0)
	tw.tween_property(_celebracion_lbl, "modulate", Color(1, 0.85, 0.0, 0.0), 0.55)
	tw.tween_callback(func(): _celebracion_lbl.visible = false; _celebracion_lbl.scale = Vector2(1, 1))

	# Estrellas flotantes extra para el nivel up
	for i in 4:
		_flotar_estrella(i)


# ── Actualizar HUD ───────────────────────────────────────────
func _actualizar_hud() -> void:
	var nivel_idx : int = 0
	for i in range(NIVELES.size()):
		if _xp_total >= NIVELES[i]["xp_min"]:
			nivel_idx = i
	_nivel_actual = nivel_idx

	var nivel_data : Dictionary = NIVELES[nivel_idx]
	var es_max     : bool       = (nivel_idx == NIVELES.size() - 1)

	if _hud_nombre_lbl:
		_hud_nombre_lbl.text = "🌿 Eco-Ranger"
	if _hud_nivel_lbl:
		_hud_nivel_lbl.text = "Nv.%d  %s" % [nivel_idx + 1, nivel_data["nombre"]]

	if _hud_barra_fill and _hud_xp_lbl:
		var xp_en_nivel : int
		var xp_para_sig : int
		if es_max:
			xp_en_nivel = 1
			xp_para_sig = 1
			_hud_xp_lbl.text = "MAX ✓"
		else:
			var sig : Dictionary = NIVELES[nivel_idx + 1]
			xp_en_nivel = _xp_total - nivel_data["xp_min"]
			xp_para_sig = sig["xp_min"] - nivel_data["xp_min"]
			_hud_xp_lbl.text = "%d / %d XP" % [_xp_total, sig["xp_min"]]

		var pct : float = clampf(float(xp_en_nivel) / float(xp_para_sig), 0.0, 1.0)
		_hud_barra_fill.size = Vector2(240.0 * pct, 12)

		var colores_barra : Array = [
			Color(0.18, 0.78, 0.28),
			Color(0.28, 0.88, 0.38),
			Color(0.20, 0.60, 0.88),
			Color(0.88, 0.65, 0.08),
			Color(0.78, 0.28, 0.88),
			Color(0.98, 0.78, 0.08),
		]
		_hud_barra_fill.color = colores_barra[nivel_idx]


# ════════════════════════════════════════════════════════════
# SIDEBAR DE MÓDULOS (lado derecho, siempre visible)
# ════════════════════════════════════════════════════════════
func _construir_sidebar() -> void:
	var ANCHO : float = 175.0
	var ALTO  : float = float(SIDEBAR_MODULOS.size()) * 34.0 + 30.0

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left   = -ANCHO
	panel.offset_top    = 0.0
	panel.offset_right  = 0.0
	panel.offset_bottom = ALTO
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.10, 0.88)
	ps.border_color = Color(0.20, 0.62, 0.20)
	ps.set_border_width_all(2)
	ps.corner_radius_bottom_left  = 10
	ps.corner_radius_top_left     = 0
	panel.add_theme_stylebox_override("panel", ps)
	_hud_canvas.add_child(panel)

	var titulo := Label.new()
	titulo.text = "GreenMetric"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 6)
	titulo.size     = Vector2(ANCHO, 18)
	titulo.add_theme_font_size_override("font_size", 10)
	titulo.add_theme_color_override("font_color", Color(0.40, 0.85, 0.42))
	panel.add_child(titulo)

	var sep := ColorRect.new()
	sep.position = Vector2(8, 22)
	sep.size     = Vector2(ANCHO - 16, 1)
	sep.color    = Color(0.20, 0.62, 0.20, 0.50)
	panel.add_child(sep)

	for i in SIDEBAR_MODULOS.size():
		var info : Dictionary = SIDEBAR_MODULOS[i]
		var ry : float = 28.0 + i * 34.0
		var col : Color = info["color"]

		# Icono + nombre
		var icono_lbl := Label.new()
		icono_lbl.text = info["icono"]
		icono_lbl.position = Vector2(6, ry)
		icono_lbl.add_theme_font_size_override("font_size", 12)
		panel.add_child(icono_lbl)

		var nombre_lbl := Label.new()
		nombre_lbl.text = info["nombre"]
		nombre_lbl.position = Vector2(24, ry)
		nombre_lbl.size = Vector2(ANCHO - 30, 14)
		nombre_lbl.add_theme_font_size_override("font_size", 9)
		nombre_lbl.add_theme_color_override("font_color", Color(0.78, 0.88, 0.80))
		panel.add_child(nombre_lbl)

		# Barra de progreso
		var barra_bg := ColorRect.new()
		barra_bg.position = Vector2(6, ry + 15)
		barra_bg.size     = Vector2(ANCHO - 20, 8)
		barra_bg.color    = Color(0.10, 0.14, 0.20)
		panel.add_child(barra_bg)

		var barra_fill := ColorRect.new()
		barra_fill.position = Vector2(0, 0)
		barra_fill.size     = Vector2(0, 8)
		barra_fill.color    = col
		barra_bg.add_child(barra_fill)
		_sidebar_fills.append(barra_fill)

		# Porcentaje
		var pct_lbl := Label.new()
		pct_lbl.position = Vector2(ANCHO - 28, ry + 14)
		pct_lbl.size     = Vector2(22, 12)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct_lbl.add_theme_font_size_override("font_size", 9)
		pct_lbl.add_theme_color_override("font_color", Color(0.60, 0.68, 0.62))
		panel.add_child(pct_lbl)
		_sidebar_pcts.append(pct_lbl)

	_actualizar_sidebar()


func _actualizar_sidebar() -> void:
	for i in SIDEBAR_MODULOS.size():
		var modulo_id : int   = SIDEBAR_MODULOS[i]["id"]
		var pct       : float = clampf(float(_progreso_modulos.get(modulo_id, 0.0)), 0.0, 1.0)
		var BAR_W     : float = 135.0   # ancho fijo de la barra bg
		if i < _sidebar_fills.size():
			var fill : ColorRect = _sidebar_fills[i]
			var tw := create_tween().set_ease(Tween.EASE_OUT)
			tw.tween_property(fill, "size:x", BAR_W * pct, 0.35)
		if i < _sidebar_pcts.size():
			var lbl : Label = _sidebar_pcts[i]
			lbl.text = "%d%%" % int(pct * 100)


# ════════════════════════════════════════════════════════════
# NOTIFICACIÓN DE ZONA (centro pantalla, aparece y desaparece)
# ════════════════════════════════════════════════════════════
func _construir_notificacion_zona() -> void:
	_notif_zona_lbl = Label.new()
	_notif_zona_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notif_zona_lbl.offset_left   = -250
	_notif_zona_lbl.offset_top    = 40
	_notif_zona_lbl.offset_right  =  250
	_notif_zona_lbl.offset_bottom =  90
	_notif_zona_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_zona_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_notif_zona_lbl.add_theme_font_size_override("font_size", 16)
	_notif_zona_lbl.add_theme_color_override("font_color", Color.WHITE)
	_notif_zona_lbl.modulate.a = 0.0
	_notif_zona_lbl.visible    = true
	_hud_canvas.add_child(_notif_zona_lbl)


func _mostrar_notificacion_zona(icono: String, nombre: String, col: Color) -> void:
	if not is_instance_valid(_notif_zona_lbl): return
	_notif_zona_lbl.text = "%s  %s" % [icono, nombre]
	_notif_zona_lbl.add_theme_color_override("font_color", col)
	var tw := create_tween()
	tw.tween_property(_notif_zona_lbl, "modulate:a", 1.0, 0.22)
	tw.tween_interval(1.4)
	tw.tween_property(_notif_zona_lbl, "modulate:a", 0.0, 0.35)


# ════════════════════════════════════════════════════════════
# PANEL DE MISIÓN COMPLETADA
# ════════════════════════════════════════════════════════════
func _construir_panel_completado() -> void:
	_complete_panel = Panel.new()
	_complete_panel.set_anchors_preset(Control.PRESET_CENTER)
	_complete_panel.custom_minimum_size = Vector2(420, 180)
	_complete_panel.offset_left   = -210
	_complete_panel.offset_top    = -90
	_complete_panel.offset_right  =  210
	_complete_panel.offset_bottom =  90
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.05, 0.97)
	ps.border_color = Color(0.28, 0.88, 0.32)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.18, 0.72, 0.22, 0.55)
	ps.shadow_size  = 20
	_complete_panel.add_theme_stylebox_override("panel", ps)
	_complete_panel.visible = false
	_hud_canvas.add_child(_complete_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   24)
	mg.add_theme_constant_override("margin_right",  24)
	mg.add_theme_constant_override("margin_top",    18)
	mg.add_theme_constant_override("margin_bottom", 18)
	_complete_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	_complete_titulo = Label.new()
	_complete_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_titulo.add_theme_font_size_override("font_size", 22)
	_complete_titulo.add_theme_color_override("font_color", Color(0.30, 1.00, 0.42))
	vbox.add_child(_complete_titulo)

	_complete_xp = Label.new()
	_complete_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_xp.add_theme_font_size_override("font_size", 15)
	_complete_xp.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	vbox.add_child(_complete_xp)

	var barra_bg := ColorRect.new()
	barra_bg.custom_minimum_size = Vector2(360, 12)
	barra_bg.color = Color(0.10, 0.16, 0.12)
	barra_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(barra_bg)

	_complete_barra = ColorRect.new()
	_complete_barra.size = Vector2(0, 12)
	_complete_barra.color = Color(0.28, 0.90, 0.35)
	barra_bg.add_child(_complete_barra)


func _mostrar_mision_completada(mision_id: String, xp_ganado: int) -> void:
	if not is_instance_valid(_complete_panel): return
	var nombre_mision : String = mision_id.replace("_", " ").capitalize()
	_complete_titulo.text = "✓ MISIÓN COMPLETADA\n" + nombre_mision
	_complete_xp.text     = "+%d XP   (Total: %d XP)" % [xp_ganado, _xp_total]

	_complete_panel.modulate.a = 0.0
	_complete_panel.scale      = Vector2(0.7, 0.7)
	_complete_panel.visible    = true
	_complete_barra.size.x     = 0.0

	var pct : float = clampf(float(_xp_total) / 12000.0, 0.0, 1.0)
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_complete_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_complete_panel, "scale", Vector2(1.0, 1.0), 0.28)
	tw.tween_property(_complete_barra, "size:x", 360.0 * pct, 0.55)
	tw.tween_interval(2.0)
	tw.tween_property(_complete_panel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): _complete_panel.visible = false)


# ════════════════════════════════════════════════════════════
# XP FLOTANTE
# ════════════════════════════════════════════════════════════
func _flotar_xp(cantidad: int) -> void:
	var lbl := Label.new()
	lbl.text = "+%d XP" % cantidad
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.28, 1.0, 0.42))
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var base_y : float = 34.0 + float(_xp_float_offset) * 24.0
	lbl.position = Vector2(258.0, base_y)
	_hud_canvas.add_child(lbl)
	_xp_float_offset = (_xp_float_offset + 1) % 4

	var tw := create_tween()
	tw.tween_property(lbl, "position:y", base_y - 36.0, 0.85).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


func _flotar_estrella(idx: int) -> void:
	var lbl := Label.new()
	lbl.text = "⭐"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	var spread_x : float = float(idx - 2) * 55.0
	lbl.offset_left   = spread_x - 12
	lbl.offset_top    = 0
	lbl.offset_right  = spread_x + 12
	lbl.offset_bottom = 30
	lbl.modulate.a    = 1.0
	_hud_canvas.add_child(lbl)

	var tw := create_tween()
	tw.tween_property(lbl, "offset_top",    -80.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "offset_bottom", -50.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


# ════════════════════════════════════════════════════════════
# EFECTO DE CÁMARA
# ════════════════════════════════════════════════════════════
func _on_interaccion_iniciada() -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(camara, "zoom", Vector2(1.7, 1.7), 0.22)
	tw.tween_interval(0.3)
	tw.tween_property(camara, "zoom", Vector2(1.5, 1.5), 0.40)


# ════════════════════════════════════════════════════════════
# SISTEMAS EVA — Tutorial, Crisis, Economía, Leaderboard
# ════════════════════════════════════════════════════════════
func _init_sistemas_eva() -> void:
	_tutorial_ui = TUTORIAL_ESCENA.new()
	add_child(_tutorial_ui)
	_tutorial_ui.tutorial_completado.connect(_on_tutorial_completado)

	_crisis_ui = CRISIS_ESCENA.new()
	add_child(_crisis_ui)
	_crisis_ui.crisis_resulta.connect(_on_crisis_resulta)
	_timer_crisis = _CRISIS_MIN

	_leaderboard_ui = LEADERBOARD_ESCENA.new()
	add_child(_leaderboard_ui)

	_sim_decision_ui = SIMULADOR_ESCENA.new()
	add_child(_sim_decision_ui)
	_sim_decision_ui.decision_tomada.connect(_on_decision_tomada)

	# Pantalla de resultados GreenMetric
	_resultados_ui = RESULTADOS_ESCENA.new()
	add_child(_resultados_ui)
	_resultados_ui.cerrar_resultados.connect(func(): pass)

	# Zonas verdes adoptables
	_spawn_zonas_verdes()

	# EcoCredits label (esquina superior derecha)
	_hud_creditos_lbl = Label.new()
	_hud_creditos_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_creditos_lbl.offset_left   =  10
	_hud_creditos_lbl.offset_top    =  58
	_hud_creditos_lbl.offset_right  = 190
	_hud_creditos_lbl.offset_bottom =  76
	_hud_creditos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_creditos_lbl.add_theme_font_size_override("font_size", 11)
	_hud_creditos_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	_hud_canvas.add_child(_hud_creditos_lbl)

	# Energía/Vidas label
	_hud_energia_lbl = Label.new()
	_hud_energia_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_energia_lbl.offset_left   = 190
	_hud_energia_lbl.offset_top    =  58
	_hud_energia_lbl.offset_right  = 308
	_hud_energia_lbl.offset_bottom =  76
	_hud_energia_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_energia_lbl.add_theme_font_size_override("font_size", 11)
	_hud_energia_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	_hud_canvas.add_child(_hud_energia_lbl)

	# Insignia flotante (abajo centro)
	_insignia_lbl = Label.new()
	_insignia_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_insignia_lbl.offset_left   = -220
	_insignia_lbl.offset_top    = -130
	_insignia_lbl.offset_right  =  220
	_insignia_lbl.offset_bottom = -76
	_insignia_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_insignia_lbl.add_theme_font_size_override("font_size", 15)
	_insignia_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.20))
	_insignia_lbl.visible = false
	_hud_canvas.add_child(_insignia_lbl)

	_crear_btn_mapa_calor()

	# Señales EconomiaManager
	EconomiaManager.ecocredits_cambiados.connect(_on_creditos_cambiados)
	EconomiaManager.energia_cambiada.connect(_on_energia_cambiada)
	EconomiaManager.insignia_obtenida.connect(_on_insignia_obtenida)

	_actualizar_hud_economia()

	# Tutorial en primera sesión (XP == 0)
	if _xp_total == 0:
		await get_tree().create_timer(0.6).timeout
		_tutorial_ui.iniciar()


func _process(delta: float) -> void:
	if _tutorial_ui and _tutorial_ui.visible: return
	if _crisis_ui and _crisis_ui.visible: return
	_timer_crisis -= delta
	if _timer_crisis <= 0.0 and _crisis_ui:
		_timer_crisis = randf_range(_CRISIS_MIN, _CRISIS_MAX)
		_crisis_ui.iniciar_aleatoria()


func _actualizar_hud_economia() -> void:
	if _hud_creditos_lbl:
		_hud_creditos_lbl.text = "💰 %d EC" % EconomiaManager.ecocredits
	if _hud_energia_lbl:
		var a : int = EconomiaManager.energia_actual
		var sv : String = ""
		for i in EconomiaManager.MAX_ENERGIA:
			sv += "♥" if i < a else "♡"
		_hud_energia_lbl.text = sv


func _on_creditos_cambiados(total: int) -> void:
	if _hud_creditos_lbl:
		_hud_creditos_lbl.text = "💰 %d EC" % total


func _on_energia_cambiada(actual: int, _maximo: int) -> void:
	if _hud_energia_lbl:
		var sv : String = ""
		for i in EconomiaManager.MAX_ENERGIA:
			sv += "♥" if i < actual else "♡"
		_hud_energia_lbl.text = sv


func _on_tutorial_completado() -> void:
	_timer_crisis = _CRISIS_MIN


func _on_crisis_resulta(modulo_id: int, exito: bool) -> void:
	var delta : float = 0.08 if exito else -0.06
	var nuevo : float = EconomiaManager.actualizar_impacto(modulo_id, delta)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	if exito:
		_aplicar_xp(25, "crisis_%d" % modulo_id)
		EconomiaManager.otorgar_insignia("crisis_resuelta")
	_timer_crisis = randf_range(_CRISIS_MIN, _CRISIS_MAX)


func _on_decision_tomada(modulo_id: int, delta: float) -> void:
	var nuevo : float = EconomiaManager.actualizar_impacto(modulo_id, delta)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	if delta > 0.0:
		EconomiaManager.ganar_creditos(15)


# ════════════════════════════════════════════════════════════
# HELPER AUDIO (compatible antes de que el IDE rescane project.godot)
# ════════════════════════════════════════════════════════════
func _sfx(nombre: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am:
		am.tocar(nombre)


# ════════════════════════════════════════════════════════════
# ZONAS VERDES ADOPTABLES
# ════════════════════════════════════════════════════════════
const DATOS_ZONAS_VERDES : Array = [
	{"nombre": "Lago URBE",        "pos": Vector2(200,  80), "mod": 4},
	{"nombre": "Jardín Bloque G",  "pos": Vector2( 96, 490), "mod": 1},
	{"nombre": "Plaza Central",    "pos": Vector2(752, 300), "mod": 1},
	{"nombre": "Área Cafetín",     "pos": Vector2(752, 490), "mod": 3},
	{"nombre": "Zona Deportiva",   "pos": Vector2(1260, 490), "mod": 5},
]

func _spawn_zonas_verdes() -> void:
	for dato : Dictionary in DATOS_ZONAS_VERDES:
		var zona := ZONA_VERDE_ESCENA.new()
		zona.nombre_zona = dato["nombre"]
		zona.modulo_id   = dato["mod"]
		zona.position    = dato["pos"]
		add_child(zona)
		zona.zona_adoptada.connect(_on_zona_verde_adoptada)
		_zonas_verdes.append(zona)


func _on_zona_verde_adoptada(nombre_zona: String, modulo_id: int) -> void:
	var delta : float = 0.06
	var nuevo : float = clampf(float(_progreso_modulos.get(modulo_id, 0.0)) + delta, 0.0, 1.0)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	_aplicar_xp(15, "adopcion_%s" % nombre_zona.to_lower().replace(" ", "_"))
	_mostrar_notificacion_zona("♥", "Adoptaste: " + nombre_zona, Color(0.28, 0.90, 0.40))
	_sfx("adoptar")
	EconomiaManager.ganar_creditos(10)


func _verificar_zona_verde_cercana() -> void:
	var radio_interaccion : float = 55.0
	for zona in _zonas_verdes:
		var z : Node2D = zona as Node2D
		if not is_instance_valid(z): continue
		if z.esta_adoptada(): continue
		if jugador.global_position.distance_to(z.global_position) <= radio_interaccion:
			var nombre_j : String = SupabaseManager.nombre_usuario
			if nombre_j.is_empty(): nombre_j = "Eco-Ranger"
			z.intentar_adoptar(nombre_j)
			return


# ════════════════════════════════════════════════════════════
# RESULTADOS GREENMETRIC
# ════════════════════════════════════════════════════════════
func _abrir_resultados() -> void:
	if not is_instance_valid(_resultados_ui): return
	_resultados_ui.actualizar_xp(_xp_total)
	_resultados_ui.mostrar(_progreso_modulos, _xp_total)


func _verificar_misiones_completadas() -> void:
	var total_completadas : int = 0
	for mod_id in _progreso_modulos.keys():
		if float(_progreso_modulos[mod_id]) >= 0.80:
			total_completadas += 1
	if total_completadas >= 6:
		await get_tree().create_timer(1.5).timeout
		_abrir_resultados()


# ════════════════════════════════════════════════════════════
# BOTÓN MAPA DE CALOR (HUD)
# ════════════════════════════════════════════════════════════
func _crear_btn_mapa_calor() -> void:
	# ── Barra de herramientas: 3 botones en esquina inferior izquierda ──
	var s_base := StyleBoxFlat.new()
	s_base.bg_color = Color(0.04, 0.08, 0.06, 0.92)
	s_base.set_border_width_all(2)
	s_base.set_corner_radius_all(8)

	var DEFS : Array = [
		{"emoji": "🌡", "tip": "Mapa de calor energético",  "borde": Color(0.85, 0.38, 0.08),
		 "accion": func():
			if mapa_campus and mapa_campus.has_method("toggle_mapa_calor"):
				mapa_campus.toggle_mapa_calor()
			_sfx("zona")},
		{"emoji": "📊", "tip": "Reporte GreenMetric",        "borde": Color(0.22, 0.80, 0.28),
		 "accion": func(): _abrir_resultados()},
		{"emoji": "🏆", "tip": "Tabla de clasificación",     "borde": Color(0.90, 0.72, 0.08),
		 "accion": func(): _leaderboard_ui.mostrar()},
	]

	for i in DEFS.size():
		var d  : Dictionary = DEFS[i]
		var sx : float      = 8.0 + i * 48.0
		var s  := s_base.duplicate() as StyleBoxFlat
		s.border_color = d["borde"]
		var btn := Button.new()
		btn.text                = d["emoji"]
		btn.tooltip_text        = d["tip"]
		btn.custom_minimum_size = Vector2(42, 42)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_stylebox_override("normal", s)
		btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		btn.offset_left   = sx
		btn.offset_top    = -50
		btn.offset_right  = sx + 42
		btn.offset_bottom = -8
		btn.pressed.connect(d["accion"])
		_hud_canvas.add_child(btn)


func _on_insignia_obtenida(_id: String, nombre: String, icono: String) -> void:
	if not _insignia_lbl: return
	_insignia_lbl.text    = "%s  ¡Insignia desbloqueada: %s!" % [icono, nombre]
	_insignia_lbl.modulate = Color(1, 1, 1, 0.0)
	_insignia_lbl.scale    = Vector2(0.75, 0.75)
	_insignia_lbl.visible  = true
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_insignia_lbl, "modulate:a", 1.0, 0.20)
	tw.parallel().tween_property(_insignia_lbl, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(_insignia_lbl, "modulate:a", 0.0, 0.40)
	tw.tween_callback(func():
		_insignia_lbl.visible = false
		_insignia_lbl.scale   = Vector2(1, 1))
