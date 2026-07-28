# ============================================================
# zona_reciclaje.gd — NIVEL 3: Manejo de Residuos
# Punto de donación de reciclables en el mapa del campus.
# El jugador se acerca y presiona E para iniciar la clasificación.
# ============================================================
extends Area2D

@export var mision_id   : String = "reciclar_1"
@export var nombre_zona : String = "Punto de Donación"

signal reciclar_solicitado(zona: Area2D)

const RADIO_DETEC  : float = 55.0
const RADIO_VISUAL : float = 26.0

var _jugador_cerca : bool  = false
var _completada    : bool  = false
var _t             : float = 0.0

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null
var _visual_node   : Node2D      = null


# ── Visual del punto de donación ─────────────────────────────
class BinVisual extends Node2D:
	var completada : bool  = false
	var _t         : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if completada:
			_draw_completado()
		else:
			_draw_bin()

	func _draw_bin() -> void:
		var pulse := 1.0 + 0.09 * sin(_t * 2.8)
		# Sombra
		draw_arc(Vector2(0, 24), 22.0, 0.0, PI, 14, Color(0.0, 0.0, 0.0, 0.18), 6.0)
		# Cuerpo del contenedor
		draw_colored_polygon(PackedVector2Array([
			Vector2(-18, -4), Vector2(18, -4),
			Vector2(14,  26), Vector2(-14, 26)
		]), Color(0.12, 0.42, 0.16))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-18, -4), Vector2(18, -4),
			Vector2(14,  26), Vector2(-14, 26)
		]), Color(0.18, 0.72, 0.22, 0.18), false)
		# Tapa
		draw_rect(Rect2(-20, -12, 40, 9), Color(0.10, 0.35, 0.13))
		draw_rect(Rect2(-20, -12, 40, 9), Color(0.22, 0.72, 0.26, 0.55), false, 1.5)
		# Franja amarilla reciclaje
		draw_rect(Rect2(-18, 4, 36, 5), Color(0.88, 0.78, 0.08))
		# Símbolo ♻ simplificado con arcos
		var rc := Color(0.22, 0.95, 0.28, 0.8 + 0.18 * sin(_t * 3.0))
		draw_arc(Vector2(0, 12), 9.0 * pulse, 0.0, TAU, 20, rc, 2.5)
		draw_line(Vector2(-4, 3), Vector2(4, 3), rc, 2.0)
		draw_line(Vector2(-4, 21), Vector2(4, 21), rc, 2.0)
		# Pulsación de detección de jugador
		var d := 0.45 + 0.25 * sin(_t * 2.2)
		draw_arc(Vector2(0, 10), 30.0, 0.0, TAU, 24, Color(0.22, 0.80, 0.28, d), 1.5)

	func _draw_completado() -> void:
		# Contenedor lleno y clasificado
		draw_colored_polygon(PackedVector2Array([
			Vector2(-18, -4), Vector2(18, -4),
			Vector2(14,  26), Vector2(-14, 26)
		]), Color(0.06, 0.26, 0.09))
		draw_rect(Rect2(-20, -12, 40, 9), Color(0.05, 0.20, 0.07))
		# Checkmark
		var gsize := 1.0 + 0.04 * sin(_t * 2.0)
		draw_arc(Vector2(0, 10), 18.0 * gsize, 0.0, TAU, 24,
				 Color(0.22, 0.92, 0.28, 0.88), 3.0)
		draw_line(Vector2(-8, 10), Vector2(-2, 18), Color(0.22, 0.92, 0.28), 3.5)
		draw_line(Vector2(-2, 18), Vector2(10, 0),  Color(0.22, 0.92, 0.28), 3.5)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("zona_reciclaje")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(3, mision_id):
		_marcar_completado()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	_visual_node = BinVisual.new()
	_visual_node.z_index = 1
	add_child(_visual_node)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(240, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.05, 0.93)
	ps.border_color = Color(0.80, 0.70, 0.10)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.50, 0.42, 0.02, 0.35)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.88))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-120, -80)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	if _completada:
		_prompt_lbl.text = "✅ [E]  Clasificación completa — %s" % nombre_zona
	else:
		_prompt_lbl.text = "♻ [E]  Clasificar reciclables — %s" % nombre_zona
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
	reciclar_solicitado.emit(self)


func _marcar_completado() -> void:
	_completada = true
	if is_instance_valid(_visual_node):
		(_visual_node as BinVisual).completada = true
	_prompt_panel.visible = false
