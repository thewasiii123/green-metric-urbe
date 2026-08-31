# ============================================================
# punto_bicicletero.gd — NIVEL 5: Transporte Sostenible
# Punto interactivo en el mapa que abre mision_bicicletero.gd
# (instalación de un bicicletero techado).
# ============================================================
extends Area2D

@export var mision_id     : String = "bicicletero_1"
@export var nombre_punto  : String = "Bicicletero"
@export var indice_mision : int    = 0

signal bicicletero_solicitado(punto: Area2D)

const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool  = false
var _completado    : bool  = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


# ── Inner class: icono visual en el mapa ─────────────────────
class RackIcon extends Node2D:
	var completado : bool  = false
	var _t          : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2(0, 12), 14.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		var glow_a := 0.10 + 0.08 * sin(_t * 2.2)
		draw_circle(Vector2.ZERO, 28.0, Color(0.20, 0.80, 0.40, glow_a))
		var col : Color = Color(0.18, 0.55, 0.30) if not completado else Color(0.18, 0.85, 0.35)
		# Techo del bicicletero
		draw_rect(Rect2(-20, -20, 40, 4), col.darkened(0.2))
		draw_rect(Rect2(-20, -18, 3, 30), Color(0.45, 0.42, 0.38))
		draw_rect(Rect2(17, -18, 3, 30), Color(0.45, 0.42, 0.38))
		# Soportes de bici (forma de "U" invertida x3)
		for i in 3:
			var x := -12.0 + float(i) * 12.0
			draw_arc(Vector2(x, 8), 6.0, PI, TAU, 10, Color(0.55, 0.55, 0.60), 2.0)
		if completado:
			# Bicicletas estacionadas: rueda simple por soporte
			for i in 3:
				var x := -12.0 + float(i) * 12.0
				draw_circle(Vector2(x, 8), 5.0, Color.TRANSPARENT)
				draw_arc(Vector2(x, 8), 5.0, 0.0, TAU, 12, col.lightened(0.3), 1.4)
			draw_line(Vector2(-5, 3), Vector2(-2, 7), Color.WHITE, 2.2)
			draw_line(Vector2(-2, 7), Vector2(5, -3), Color.WHITE, 2.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_bicicletero")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(5, mision_id):
		_marcar_completado()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := RackIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("rack_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(300, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.03, 0.08, 0.05, 0.93)
	ps.border_color = Color(0.20, 0.75, 0.40)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.05, 0.35, 0.15, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.80, 1.0, 0.85))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if _jugador_cerca:
		_actualizar_prompt_texto()
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-150, -90)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _actualizar_prompt_texto() -> void:
	if _completado:
		_prompt_lbl.text = "✅ Bicicletero instalado — %s" % nombre_punto
	else:
		_prompt_lbl.text = "🚲 [E] Instalar bicicletero — %s" % nombre_punto


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	_actualizar_prompt_texto()
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
	if not _jugador_cerca or _completado: return
	_prompt_panel.visible = false
	bicicletero_solicitado.emit(self)


func _marcar_completado() -> void:
	_completado = true
	var icon = get_meta("rack_icon", null)
	if icon and is_instance_valid(icon):
		icon.completado = true
		icon.modulate.a = 0.5
