# ============================================================
# SceneMapaMundo.gd — URBE Rangers: Eco-Quest
# Compatible con la estructura de nodos ACTUAL de la escena.
# Mapa: 1408 x 768 px
# ============================================================
extends Node2D

# ── Constantes del mundo ────────────────────────────────────
const MAPA_ANCHO : float = 1408.0
const MAPA_ALTO  : float = 768.0

# Spawn en la Entrada URBE (centro-inferior del mapa)
const SPAWN_X    : float = 694.0
const SPAWN_Y    : float = 650.0

# ── Referencias — rutas que SÍ existen en tu escena ─────────
@onready var jugador      : CharacterBody2D = $Jugador
@onready var camara       : Camera2D        = $Jugador/Camera2D
@onready var zonas_campus : Node2D          = $ZonasCampus

# HUD superior
@onready var label_nombre : Label           = $CanvasLayer/PanelContainer/HBoxContainer/LabelNombre
@onready var label_xp     : Label           = $CanvasLayer/PanelContainer/HBoxContainer/LabelXP

# Panel de zona (el que ya tienes con LabelZona)
@onready var panel_zona   : PanelContainer  = $CanvasLayer/PanelZona
@onready var label_zona   : Label           = $CanvasLayer/PanelZona/LabelZona

# ── Estado interno ───────────────────────────────────────────
var _xp_total      : int    = 0
var _modulo_activo : int    = -1
var _nombre_activo : String = ""


func _ready() -> void:
	print("✅ Campus URBE cargado — %dx%d" % [MAPA_ANCHO, MAPA_ALTO])
	print("👤 UID: " + SupabaseManager.user_id)

	# ── Spawn del jugador ────────────────────────────────────
	jugador.global_position = Vector2(SPAWN_X, SPAWN_Y)

	# ── Límites de cámara ────────────────────────────────────
	camara.limit_left   = 0
	camara.limit_top    = 0
	camara.limit_right  = int(MAPA_ANCHO)
	camara.limit_bottom = int(MAPA_ALTO)
	camara.zoom         = Vector2(1.5, 1.5)

	# ── HUD inicial ──────────────────────────────────────────
	panel_zona.visible = false
	_actualizar_hud()

	# ── Señales de zonas ─────────────────────────────────────
	if $ZonasCampus:
		zonas_campus.zona_activada.connect(_on_zona_activada)
		zonas_campus.zona_salida.connect(_on_zona_salida)

	# ── Supabase ─────────────────────────────────────────────
	SupabaseManager.modulos_cargados.connect(_on_modulos_cargados)
	SupabaseManager.progreso_cargado.connect(_on_progreso_cargado)
	SupabaseManager.cargar_modulos()
	SupabaseManager.cargar_progreso()


# ── Callbacks Supabase ───────────────────────────────────────
func _on_modulos_cargados(lista: Array) -> void:
	print("📦 Módulos cargados: %d" % lista.size())

func _on_progreso_cargado(lista: Array) -> void:
	for entrada in lista:
		_xp_total += entrada.get("xp_ganada", 0)
	_actualizar_hud()
	print("📊 XP total cargada: %d" % _xp_total)


# ── Zonas del campus ─────────────────────────────────────────
func _on_zona_activada(modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo
	label_zona.text    = "📍 " + nombre_modulo + "\n[E] para comenzar misión"
	panel_zona.visible = true
	print("🏛 Zona activa: %s (M%d)" % [nombre_modulo, modulo_id])

func _on_zona_salida() -> void:
	panel_zona.visible = false
	_modulo_activo     = -1
	_nombre_activo     = ""


# ── Input: tecla E ───────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and _modulo_activo != -1:
			print("🎮 Iniciando módulo: " + _nombre_activo)
			# get_tree().change_scene_to_file("res://scenes/minijuego/SceneMinijuego.tscn")


# ── HUD ──────────────────────────────────────────────────────
func _actualizar_hud() -> void:
	var uid := SupabaseManager.user_id
	var nombre_corto := uid.substr(0, 8) if uid.length() >= 8 else "Ranger"
	label_nombre.text = "🌿 " + nombre_corto
	label_xp.text     = "XP: %d" % _xp_total
