# ============================================================
# zona_verde.gd — URBE Rangers: Eco-Quest
# Áreas verdes adoptables del campus.
# El jugador presiona E cerca para adoptar y recibe XP pasiva.
# ============================================================
extends Node2D

@export var nombre_zona : String = "Área Verde"
@export var modulo_id   : int    = 1
@export var radio       : float  = 44.0

signal zona_adoptada(nombre_zona: String, modulo_id: int)

var adoptado_por : String = ""
var _xp_timer   : float  = 0.0
var _pulso_t    : float  = 0.0
var _label      : Label  = null

const XP_PASIVA   : float = 60.0
const XP_CANTIDAD : int   = 3


func _ready() -> void:
	add_to_group("zonas_verdes")
	_crear_label()


func _crear_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color(0.90, 1.0, 0.90))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 2)
	_label.position = Vector2(-55.0, -radio - 24.0)
	_label.size     = Vector2(110.0, 20.0)
	_label.visible  = false
	add_child(_label)


func _process(delta: float) -> void:
	_pulso_t += delta
	queue_redraw()
	if adoptado_por.is_empty():
		return
	_xp_timer += delta
	if _xp_timer >= XP_PASIVA:
		_xp_timer = 0.0
		var escena = get_tree().get_first_node_in_group("scene_mapa")
		if escena and escena.has_method("_aplicar_xp"):
			escena._aplicar_xp(XP_CANTIDAD, "zona_verde_%d" % modulo_id)


func _draw() -> void:
	var t    : float = _pulso_t
	var col  : Color = _color_modulo()
	var alfa : float = 0.16 + 0.07 * sin(t * 1.6)
	var r2   : float = radio + 5.0 * sin(t * 2.0)

	# Círculo pulsante de fondo
	draw_circle(Vector2.ZERO, r2, Color(col.r, col.g, col.b, alfa))

	# Anillo exterior
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 48,
			 Color(col.r, col.g, col.b, 0.45 + 0.18 * sin(t * 1.8)), 2.5)

	# Icono de hoja si está adoptada
	if not adoptado_por.is_empty():
		draw_circle(Vector2.ZERO, 7.0, Color(0.28, 0.92, 0.40, 0.90))
		# Cruz verde interna
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color.WHITE, 2.0)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color.WHITE, 2.0)
	else:
		# Indicador "E" para interactuar
		var dist : float = _dist_jugador()
		if dist < radio * 1.5:
			draw_circle(Vector2(0, -radio + 8), 8.0, Color(0.95, 0.90, 0.18, 0.85))


func _dist_jugador() -> float:
	var jugadores := get_tree().get_nodes_in_group("jugador")
	if jugadores.is_empty():
		return 9999.0
	var j : Node2D = jugadores[0]
	return global_position.distance_to(j.global_position)


func intentar_adoptar(nombre_jugador: String) -> bool:
	if not adoptado_por.is_empty():
		return false
	adoptado_por   = nombre_jugador
	_label.text    = "♥ " + nombre_jugador
	_label.visible = true
	_xp_timer      = 0.0
	zona_adoptada.emit(nombre_zona, modulo_id)
	return true


func esta_adoptada() -> bool:
	return not adoptado_por.is_empty()


func _color_modulo() -> Color:
	match modulo_id:
		1: return Color(0.18, 0.80, 0.28)
		2: return Color(0.95, 0.62, 0.05)
		3: return Color(0.90, 0.78, 0.05)
		4: return Color(0.05, 0.55, 0.92)
		5: return Color(0.15, 0.35, 0.92)
		6: return Color(0.58, 0.05, 0.88)
	return Color(0.35, 0.80, 0.38)
