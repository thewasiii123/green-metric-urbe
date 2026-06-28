# ============================================================
# SceneMapaMundo.gd - URBE Rangers: Eco-Quest
# Mapa: 1408 x 768 px
# Instancia todos los NPCs por codigo al iniciar.
# ============================================================
extends Node2D

# -- Mapa ----------------------------------------------------
const MAPA_ANCHO : float = 1408.0
const MAPA_ALTO  : float = 768.0
const SPAWN_X    : float = 694.0
const SPAWN_Y    : float = 650.0

# -- Escena base NPC (instanciada por codigo) ----------------
const NPC_ESCENA := preload("res://scenes/mapa/npc_base.tscn")

# -- Datos de cada NPC del campus ----------------------------
# pos = posicion en el mapa (calibrada para imagen real)
# color = modulate del Sprite2D para distinguir personajes
var DATOS_NPCS : Array = [
	{
		"nombre":    "Rector Morales",
		"mision_id": "mision_rector",
		"pos":       Vector2(870, 555),
		"color":     Color(0.5, 0.1, 0.9),
		"dialogos":  PackedStringArray([
			"Bienvenido, Eco-Ranger. Soy el Rector de URBE.",
			"Nuestro campus participa en el ranking UI GreenMetric, que evalua sostenibilidad universitaria.",
			"Necesito que hables con los 5 coordinadores del campus y recopiles el reporte de cada modulo.",
			"Empieza por la Ing. Ramirez junto al Bloque A. El futuro verde de URBE esta en tus manos."
		])
	},
	{
		"nombre":    "Ing. Ramirez",
		"mision_id": "mision_infraestructura",
		"pos":       Vector2(395, 560),
		"color":     Color(0.2, 0.7, 0.2),
		"dialogos":  PackedStringArray([
			"Hola, soy la Ing. Ramirez, coordinadora de Entorno e Infraestructura.",
			"GreenMetric evalua nuestros espacios verdes, politicas y certificaciones ambientales.",
			"El campus tiene jardines y el Bloque F al este, pero necesito un informe de su estado.",
			"Mision: visita el Bloque F y el Area de Servicios y vuelve con el reporte."
		])
	},
	{
		"nombre":    "Dr. Perez",
		"mision_id": "mision_energia",
		"pos":       Vector2(548, 452),
		"color":     Color(0.9, 0.5, 0.0),
		"dialogos":  PackedStringArray([
			"Doctor Perez, coordinador de Energia y Cambio Climatico.",
			"Medimos consumo electrico, uso de energias renovables y emisiones de CO2 del campus.",
			"Los Bloques A, B, C, D y E son nuestros edificios de clases principales.",
			"Mision: recorre la zona de Bloques D y E al norte y confirma si los equipos estan activos."
		])
	},
	{
		"nombre":    "Yulimar",
		"mision_id": "mision_residuos",
		"pos":       Vector2(490, 640),
		"color":     Color(0.85, 0.75, 0.0),
		"dialogos":  PackedStringArray([
			"Eco-Ranger! Soy Yulimar, del comite estudiantil de reciclaje.",
			"El campus genera residuos diariamente, pero solo el 30% se clasifica correctamente.",
			"GreenMetric penaliza la falta de contenedores diferenciados y programas de compostaje.",
			"Mision: habla con la Dra. Luna en el Area de Servicios sobre mas puntos de reciclaje."
		])
	},
	{
		"nombre":    "Lic. Torres",
		"mision_id": "mision_agua",
		"pos":       Vector2(600, 345),
		"color":     Color(0.0, 0.55, 0.75),
		"dialogos":  PackedStringArray([
			"Buenas, soy la Lic. Torres, responsable del modulo de Agua.",
			"GreenMetric evalua si el campus tiene programas de conservacion hidrica y medidores de consumo.",
			"Problema: la Biblioteca consume mucha agua pero no tenemos hidrometros instalados.",
			"Mision: reporta al Rector Morales que necesitamos presupuesto para hidrometros."
		])
	},
	{
		"nombre":    "Carlos",
		"mision_id": "mision_transporte",
		"pos":       Vector2(355, 475),
		"color":     Color(0.1, 0.3, 0.8),
		"dialogos":  PackedStringArray([
			"Hola! Soy Carlos, coordinador de Transporte Sostenible.",
			"GreenMetric mide cuantos estudiantes usan transporte publico, bicicleta o caminan al campus.",
			"Actualmente el 78% llega en vehiculo privado. Tenemos el Estacionamiento M5 siempre lleno.",
			"Mision: habla con 2 coordinadores y preguntales si apoyan crear ciclovias en el campus."
		])
	},
	{
		"nombre":    "Dra. Luna",
		"mision_id": "mision_educacion",
		"pos":       Vector2(1120, 555),
		"color":     Color(0.35, 0.0, 0.65),
		"dialogos":  PackedStringArray([
			"Por fin llegas! Soy la Dra. Luna, coordinadora de Educacion e Investigacion.",
			"Este modulo evalua materias de sostenibilidad, publicaciones cientificas e iniciativas del campus.",
			"URBE tiene 3 asignaturas ambientales, pero necesitamos mas investigacion publicada en revistas.",
			"Mision final: reune los reportes de todos los coordinadores y llevelos al Rector para el informe GreenMetric."
		])
	},
]

# -- Referencias ---------------------------------------------
@onready var jugador      : CharacterBody2D = $Jugador
@onready var camara       : Camera2D        = $Jugador/Camera2D
@onready var zonas_campus : Node2D          = $ZonasCampus
@onready var label_nombre : Label           = $CanvasLayer/PanelContainer/HBoxContainer/LabelNombre
@onready var label_xp     : Label           = $CanvasLayer/PanelContainer/HBoxContainer/LabelXP
@onready var panel_zona   : PanelContainer  = $CanvasLayer/PanelZona
@onready var label_zona   : Label           = $CanvasLayer/PanelZona/LabelZona

# -- Estado --------------------------------------------------
var _xp_total      : int    = 0
var _modulo_activo : int    = -1
var _nombre_activo : String = ""


func _ready() -> void:
	jugador.global_position = Vector2(SPAWN_X, SPAWN_Y)
	jugador.z_index = 2

	camara.limit_left   = 0
	camara.limit_top    = 0
	camara.limit_right  = int(MAPA_ANCHO)
	camara.limit_bottom = int(MAPA_ALTO)
	camara.zoom         = Vector2(1.5, 1.5)

	panel_zona.visible = false
	_actualizar_hud()

	if $ZonasCampus:
		zonas_campus.zona_activada.connect(_on_zona_activada)
		zonas_campus.zona_salida.connect(_on_zona_salida)

	_spawn_npcs()

	SupabaseManager.modulos_cargados.connect(_on_modulos_cargados)
	SupabaseManager.progreso_cargado.connect(_on_progreso_cargado)
	SupabaseManager.cargar_modulos()
	SupabaseManager.cargar_progreso()


func _spawn_npcs() -> void:
	for datos in DATOS_NPCS:
		var npc : Area2D = NPC_ESCENA.instantiate()
		npc.nombre_npc   = datos["nombre"]
		npc.mision_id    = datos["mision_id"]
		npc.dialogos     = datos["dialogos"]
		npc.position     = datos["pos"]
		npc.z_index      = 1
		npc.get_node("Visual").modulate = datos["color"]
		add_child(npc)
	print("OK %d NPCs instanciados" % DATOS_NPCS.size())


# -- Callbacks Supabase --------------------------------------
func _on_modulos_cargados(lista: Array) -> void:
	print("Modulos cargados: %d" % lista.size())

func _on_progreso_cargado(lista: Array) -> void:
	for entrada in lista:
		_xp_total += entrada.get("xp_ganada", 0)
	_actualizar_hud()


# -- Zonas ---------------------------------------------------
func _on_zona_activada(modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo
	label_zona.text    = nombre_modulo + "\n[E] para comenzar mision"
	panel_zona.visible = true

func _on_zona_salida() -> void:
	panel_zona.visible = false
	_modulo_activo     = -1
	_nombre_activo     = ""


# -- Input: tecla E en zona ----------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and _modulo_activo != -1:
			var ui = get_tree().get_first_node_in_group("ui_dialogo")
			if ui and ui.visible:
				return
			print("Iniciando modulo: " + _nombre_activo)


# -- HUD -----------------------------------------------------
func _actualizar_hud() -> void:
	var uid          := SupabaseManager.user_id
	var nombre_corto := uid.substr(0, 8) if uid.length() >= 8 else "Ranger"
	label_nombre.text = nombre_corto
	label_xp.text     = "XP: %d" % _xp_total
