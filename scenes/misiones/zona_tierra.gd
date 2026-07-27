# ============================================================
# zona_tierra.gd — NIVEL 1 Infraestructura y Entorno
# Zona de tierra en áreas verdes del campus.
# El jugador se acerca y presiona E para iniciar la misión
# de plantación correspondiente.
# ============================================================
extends Area2D

@export var mision_id     : String = "plantar_1"
@export var nombre_zona   : String = "Jardín Norte"
@export var indice_mision : int    = 0   # 0, 1 ó 2 → qué datos de plantación usar

signal plantar_solicitado(zona: Area2D)

const RADIO_TIERRA  : float = 34.0   # en espacio del padre (no inner class)
const RADIO_DETEC   : float = 60.0

var _jugador_cerca  : bool  = false
var _completada     : bool  = false
var _t              : float = 0.0

var _prompt_canvas  : CanvasLayer = null
var _prompt_panel   : Panel       = null
var _prompt_lbl     : Label       = null

# Planta visual que aparece cuando la misión está completada
var _planta_visual  : Node2D  = null


class TierraVisual extends Node2D:
	const RADIO_TIERRA = 34.0
	var completada : bool  = false
	var tipo_planta: String = ""
	var _t         : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if completada:
			_draw_completada()
		else:
			_draw_tierra()

	func _draw_tierra() -> void:
		# Sombra
		draw_arc(Vector2(0, 6), RADIO_TIERRA * 1.1, 0.0, PI, 20,
				 Color(0.0, 0.0, 0.0, 0.18), 8.0)
		# Parche de tierra (elipse marrón)
		var puntos := PackedVector2Array()
		for i in 28:
			var a := float(i) / 28.0 * TAU
			puntos.append(Vector2(cos(a) * RADIO_TIERRA, sin(a) * RADIO_TIERRA * 0.55))
		draw_colored_polygon(puntos, Color(0.38, 0.24, 0.10))
		# Borde grass
		draw_arc(Vector2(0, 0), RADIO_TIERRA, 0.0, TAU, 28,
				 Color(0.22, 0.55, 0.14, 0.7), 4.0)
		# Textura de tierra (motas)
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for _i in 14:
			var px := rng.randf_range(-RADIO_TIERRA * 0.7, RADIO_TIERRA * 0.7)
			var py := rng.randf_range(-RADIO_TIERRA * 0.28, RADIO_TIERRA * 0.25)
			draw_circle(Vector2(px, py), rng.randf_range(1.5, 3.5),
						Color(0.28, 0.16, 0.06, 0.55))
		# Hoyo central pulsante (indica dónde plantar)
		var puls := 1.0 + 0.12 * sin(_t * 3.0)
		draw_circle(Vector2(0, 0), 7.0 * puls, Color(0.20, 0.11, 0.04))
		draw_arc(Vector2(0, 0), 7.5 * puls, 0.0, TAU, 16,
				 Color(0.55, 0.88, 0.25, 0.6 + 0.3 * sin(_t * 2.5)), 1.5)

	func _draw_completada() -> void:
		# Tierra completada con planta crecida
		var puntos := PackedVector2Array()
		for i in 28:
			var a := float(i) / 28.0 * TAU
			puntos.append(Vector2(cos(a) * RADIO_TIERRA, sin(a) * RADIO_TIERRA * 0.55))
		draw_colored_polygon(puntos, Color(0.32, 0.20, 0.08))
		# Borde verde brillante (planta saludable)
		draw_arc(Vector2(0, 0), RADIO_TIERRA, 0.0, TAU, 28,
				 Color(0.15, 0.75, 0.20, 0.85), 4.0)
		# Halo de éxito pulsante
		var ga := 0.10 + 0.08 * sin(_t * 2.0)
		draw_circle(Vector2(0, -10), 30.0, Color(0.20, 0.80, 0.25, ga))
		# Planta simplificada (árbol o arbusto)
		_draw_planta_simple()
		# Chispas verdes girando
		for i in 6:
			var angle := _t * 1.2 + float(i) / 6.0 * TAU
			var r := 36.0 + sin(_t * 2.0 + i) * 4.0
			var p := Vector2(cos(angle) * r, sin(angle) * r * 0.5 - 10)
			draw_circle(p, 2.2, Color(0.20, 0.90, 0.30, 0.6))

	func _draw_planta_simple() -> void:
		# usa RADIO_TIERRA de esta clase (inner class const)
		# Tronco
		draw_rect(Rect2(-3, -6, 6, 14), Color(0.40, 0.25, 0.10))
		# Copa (árbol genérico verde)
		draw_circle(Vector2(0, -18), 16.0, Color(0.15, 0.62, 0.18))
		draw_circle(Vector2(-9, -12), 11.0, Color(0.18, 0.68, 0.20))
		draw_circle(Vector2( 9, -12), 11.0, Color(0.18, 0.68, 0.20))
		draw_circle(Vector2(0, -26), 12.0, Color(0.22, 0.72, 0.22))

func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("zona_tierra")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(1, mision_id):
		_marcar_completada()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	_planta_visual = TierraVisual.new()
	(_planta_visual as TierraVisual).completada = false
	_planta_visual.z_index = 1
	add_child(_planta_visual)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(200, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.10, 0.06, 0.93)
	ps.border_color = Color(0.22, 0.88, 0.30)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.10, 0.50, 0.15, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if not _prompt_panel.visible: return
	# Posición sobre la zona (en pantalla, no en mundo)
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-100, -80)
	var vp_size := get_viewport().get_visible_rect().size
	var cam_zoom := cam.zoom
	var cam_offset := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_offset) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	if _completada: return
	_prompt_lbl.text = "🌱 [E]  Plantar en %s" % nombre_zona
	_prompt_panel.modulate.a = 0.0
	_prompt_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 1.0, 0.20)


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = false
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func(): _prompt_panel.visible = false)


func intentar_interactuar() -> void:
	if not _jugador_cerca or _completada: return
	_prompt_panel.visible = false
	plantar_solicitado.emit(self)


func _marcar_completada() -> void:
	_completada = true
	if is_instance_valid(_planta_visual):
		(_planta_visual as TierraVisual).completada = true
	_prompt_panel.visible = false
