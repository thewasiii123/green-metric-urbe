# ============================================================
# SceneMapaMundo.gd
# Escena principal del campus URBE.
# Recibe señales de ZonasCampus y muestra el HUD correspondiente.
# ============================================================
extends Node2D

@onready var label_nombre : Label = $CanvasLayer/PanelContainer/HBoxContainer/LabelNombre
@onready var label_xp     : Label = $CanvasLayer/PanelContainer/HBoxContainer/LabelXP
@onready var zonas_campus : Node2D = $ZonasCampus

# Panel que aparece al entrar a una zona
@onready var panel_zona   : PanelContainer = $CanvasLayer/PanelZona
@onready var label_zona   : Label          = $CanvasLayer/PanelZona/LabelZona


func _ready() -> void:
	print("✅ Campus URBE cargado")
	print("👤 Jugador: " + SupabaseManager.user_id)

	# Conectar señales de las zonas
	zonas_campus.zona_activada.connect(_on_zona_activada)
	zonas_campus.zona_salida.connect(_on_zona_salida)

	# Ocultar panel de zona al inicio
	if panel_zona:
		panel_zona.visible = false

	# Cargar módulos desde Supabase
	SupabaseManager.modulos_cargados.connect(_on_modulos_cargados)
	SupabaseManager.cargar_modulos()


func _on_modulos_cargados(lista: Array) -> void:
	print("📦 Módulos cargados: " + str(lista.size()))


func _on_zona_activada(modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	print("🎯 Zona activa: " + nombre_modulo + " (M" + str(modulo_id) + ")")
	if panel_zona:
		label_zona.text = "📍 " + nombre_modulo + "\nPresiona E para jugar"
		panel_zona.visible = true

	# Detectar tecla E para entrar al minijuego
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo


func _on_zona_salida() -> void:
	if panel_zona:
		panel_zona.visible = false
	_modulo_activo = -1


# Variables de estado
var _modulo_activo : int    = -1
var _nombre_activo : String = ""


func _input(event: InputEvent) -> void:
	# Presionar E estando en una zona lanza el minijuego
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and _modulo_activo != -1:
			print("🎮 Iniciando minijuego: " + _nombre_activo)
			# get_tree().change_scene_to_file("res://scenes/minijuego/SceneMinijuego.tscn")
