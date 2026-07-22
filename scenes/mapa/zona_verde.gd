# ============================================================
# zona_verde.gd — URBE Rangers: Eco-Quest
# Áreas verdes adoptables del campus con sistema de niveles.
# Nivel 1: adopción base  |  2: jardín  |  3: bosque urbano
# ============================================================
extends Node2D

@export var nombre_zona : String = "Área Verde"
@export var modulo_id   : int    = 1
@export var radio       : float  = 44.0

signal zona_adoptada(nombre_zona: String, modulo_id: int)

var adoptado_por : String = ""
var nivel        : int    = 1
var _xp_timer    : float  = 0.0
var _pulso_t     : float  = 0.0
var _label       : Label  = null

const INTERVALO_XP  : float       = 60.0
const XP_POR_NIVEL  : Array[int]  = [3,  6,  12]    # XP pasiva cada 60 s
const COSTO_MEJORA  : Array[int]  = [50, 150]        # EC para subir a nivel 2 y 3
const XP_MEJORA_INM : Array[int]  = [20, 40]         # XP inmediata al mejorar
const PROG_MEJORA   : Array       = [0.08, 0.12]     # % módulo inmediato al mejorar
const NOMBRES_NIVEL : Array       = ["Plántula", "Jardín", "Bosque Urbano"]


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
	_label.position = Vector2(-55.0, -(radio + 24.0))
	_label.size     = Vector2(110.0, 20.0)
	_label.visible  = false
	add_child(_label)


func _process(delta: float) -> void:
	_pulso_t += delta
	queue_redraw()
	if adoptado_por.is_empty():
		return
	_xp_timer += delta
	if _xp_timer >= INTERVALO_XP:
		_xp_timer = 0.0
		var escena = get_tree().get_first_node_in_group("scene_mapa")
		if escena and escena.has_method("_aplicar_xp"):
			escena._aplicar_xp(xp_pasiva_actual(), "zona_verde_%d" % modulo_id)


func _draw() -> void:
	var t    : float = _pulso_t
	var col  : Color = _color_modulo()
	var lvl  : int   = nivel

	# Intensidad visual crece con el nivel
	var alfa_base : float = 0.10 + 0.06 * float(lvl)
	var alfa      : float = alfa_base + 0.05 * sin(t * 1.6)
	var r2        : float = radio + float(lvl) * 2.0 * sin(t * 2.0)

	# Círculo pulsante de fondo
	draw_circle(Vector2.ZERO, r2, Color(col.r, col.g, col.b, alfa))

	# Anillo exterior (más grueso según nivel)
	var grosor : float = 1.5 + float(lvl) * 0.8
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 48,
			 Color(col.r, col.g, col.b, 0.40 + 0.15 * sin(t * 1.8)), grosor)

	if not adoptado_por.is_empty():
		# Orbes giratorios por nivel (2 × nivel)
		var n_orbes : int   = lvl * 2
		var r_orbe  : float = 3.0 + float(lvl) * 0.5
		for i in n_orbes:
			var ang : float  = (TAU / float(n_orbes)) * float(i) + t * 0.8
			var dp  : Vector2 = Vector2(cos(ang), sin(ang)) * (radio - r_orbe - 2.0)
			draw_circle(dp, r_orbe, Color(col.r, col.g, col.b, 0.90))

		# Centro: corazón (círculo + símbolo de nivel)
		var col_centro : Color = Color(0.28, 0.92, 0.40, 0.90)
		if   lvl == 2: col_centro = Color(0.92, 0.80, 0.10, 0.90)
		elif lvl == 3: col_centro = Color(0.92, 0.40, 0.10, 0.90)
		draw_circle(Vector2.ZERO, 6.0 + float(lvl) * 1.5, col_centro)
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color.WHITE, 2.0)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color.WHITE, 2.0)
	else:
		# Indicador "E" al acercarse
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
	adoptado_por = nombre_jugador
	nivel        = 1
	_actualizar_label()
	_xp_timer = 0.0
	zona_adoptada.emit(nombre_zona, modulo_id)
	return true


func puede_mejorar() -> bool:
	return nivel < 3


func costo_siguiente() -> int:
	if nivel >= 3: return 0
	return COSTO_MEJORA[nivel - 1]


func xp_pasiva_actual() -> int:
	return XP_POR_NIVEL[nivel - 1]


func nombre_nivel_actual() -> String:
	return NOMBRES_NIVEL[nivel - 1]


func aplicar_mejora() -> void:
	if nivel >= 3: return
	nivel += 1
	_actualizar_label()
	queue_redraw()


func esta_adoptada() -> bool:
	return not adoptado_por.is_empty()


func es_mia(nombre_jugador: String) -> bool:
	return adoptado_por == nombre_jugador


func _actualizar_label() -> void:
	var icono : String = ["🌱", "🌿", "🌳"][nivel - 1]
	_label.text    = icono + " Nv.%d %s" % [nivel, adoptado_por]
	_label.visible = true


func _color_modulo() -> Color:
	match modulo_id:
		1: return Color(0.18, 0.80, 0.28)
		2: return Color(0.95, 0.62, 0.05)
		3: return Color(0.90, 0.78, 0.05)
		4: return Color(0.05, 0.55, 0.92)
		5: return Color(0.15, 0.35, 0.92)
		6: return Color(0.58, 0.05, 0.88)
	return Color(0.35, 0.80, 0.38)
