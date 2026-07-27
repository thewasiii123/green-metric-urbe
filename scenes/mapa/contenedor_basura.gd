# contenedor_basura.gd — URBE Rangers: Eco-Quest
# Contenedor de basura interactivo que se llena con el tiempo.
extends Node2D

signal vaciado(xp_ganado: int)

const TASA_LLENADO : float = 0.0028   # por segundo → 0→100% en ~6 min
const ANCHO        : float = 20.0
const ALTO         : float = 26.0

var nombre_bin    : String = "Contenedor"
var nivel_llenado : float  = 0.0      # 0.0..1.0
var en_servicio   : bool   = false

var _pulse_t : float = 0.0
var _label   : Label = null


func _ready() -> void:
	nivel_llenado = randf_range(0.10, 0.55)
	_crear_label()
	queue_redraw()


func _crear_label() -> void:
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 9)
	_label.position             = Vector2(-16.0, -ALTO * 0.5 - 14.0)
	_label.custom_minimum_size  = Vector2(32.0, 14.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	_actualizar_label()


func _process(delta: float) -> void:
	if en_servicio:
		return
	var prev : float = nivel_llenado
	nivel_llenado = minf(nivel_llenado + TASA_LLENADO * delta, 1.0)
	var tick : bool = int(prev * 25) != int(nivel_llenado * 25)
	if nivel_llenado >= 0.8:
		_pulse_t += delta
		var pulso : bool = int(_pulse_t * 2.0) != int((_pulse_t - delta) * 2.0)
		if tick or pulso:
			queue_redraw()
			_actualizar_label()
	elif tick:
		queue_redraw()
		_actualizar_label()


func _draw() -> void:
	var hw : float = ANCHO * 0.5
	var hh : float = ALTO  * 0.5

	if en_servicio:
		draw_rect(Rect2(-hw, -hh, ANCHO, ALTO), Color(0.12, 0.14, 0.18), true)
		draw_rect(Rect2(-hw, -hh, ANCHO, ALTO), Color(0.40, 0.42, 0.48), false, 1.5)
		return

	# Cuerpo del contenedor
	draw_rect(Rect2(-hw, -hh, ANCHO, ALTO), Color(0.16, 0.16, 0.20), true)

	# Relleno (crece de abajo hacia arriba)
	if nivel_llenado > 0.01:
		var fill_h : float = ALTO * nivel_llenado
		draw_rect(Rect2(-hw, hh - fill_h, ANCHO, fill_h), _color_nivel(), true)

	# Tapa
	draw_rect(Rect2(-hw - 2.0, -hh - 5.0, ANCHO + 4.0, 5.0), Color(0.22, 0.22, 0.28), true)
	draw_rect(Rect2(-hw - 2.0, -hh - 5.0, ANCHO + 4.0, 5.0), Color(0.48, 0.48, 0.52), false, 1.0)

	# Contorno — pulsa rojo cuando ≥80%
	var borde : Color
	if nivel_llenado >= 0.8:
		var p : float = absf(sin(_pulse_t * PI * 2.0))
		borde = Color(0.88 + 0.12 * p, 0.10, 0.10)
	elif nivel_llenado >= 0.5:
		borde = Color(0.88, 0.70, 0.08)
	else:
		borde = Color(0.28, 0.70, 0.28)
	draw_rect(Rect2(-hw, -hh, ANCHO, ALTO), borde, false, 1.5)

	# Ranuras decorativas
	draw_line(Vector2(-hw * 0.33, -hh + 3.0), Vector2(-hw * 0.33, hh - 3.0),
			Color(0.28, 0.28, 0.32), 0.8)
	draw_line(Vector2( hw * 0.33, -hh + 3.0), Vector2( hw * 0.33, hh - 3.0),
			Color(0.28, 0.28, 0.32), 0.8)


func _color_nivel() -> Color:
	if nivel_llenado <= 0.5:
		return Color(0.20, 0.75, 0.20).lerp(Color(0.88, 0.75, 0.08), nivel_llenado * 2.0)
	return Color(0.88, 0.75, 0.08).lerp(Color(0.88, 0.12, 0.08), (nivel_llenado - 0.5) * 2.0)


func _actualizar_label() -> void:
	if not is_instance_valid(_label):
		return
	if en_servicio:
		_label.text = "🧹..."
		_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		return
	var pct   : int    = int(nivel_llenado * 100)
	var icono : String = "⚠" if nivel_llenado >= 0.8 else "🗑"
	_label.text = "%s%d%%" % [icono, pct]
	_label.add_theme_color_override("font_color",
			Color(1.0, 0.28, 0.28) if nivel_llenado >= 0.8 else Color(0.85, 0.85, 0.85))


func porcentaje() -> int:
	return int(nivel_llenado * 100)


func esta_lleno() -> bool:
	return nivel_llenado >= 0.8


func solicitar_servicio() -> void:
	if en_servicio:
		return
	en_servicio = true
	queue_redraw()
	_actualizar_label()
	get_tree().create_timer(4.0).timeout.connect(_servicio_completado, CONNECT_ONE_SHOT)


func _servicio_completado() -> void:
	var xp : int = _calcular_xp()
	nivel_llenado = 0.0
	en_servicio   = false
	_pulse_t      = 0.0
	queue_redraw()
	_actualizar_label()
	vaciado.emit(xp)


func _calcular_xp() -> int:
	if nivel_llenado >= 0.90: return 20
	if nivel_llenado >= 0.70: return 15
	if nivel_llenado >= 0.50: return 10
	if nivel_llenado >= 0.30: return 7
	return 5
