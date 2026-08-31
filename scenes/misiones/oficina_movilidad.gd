# ============================================================
# oficina_movilidad.gd — NIVEL 5: Transporte Sostenible
# Único punto en el mapa que da acceso a los 6 escenarios de
# decisión de movilidad (mision_movilidad.gd). Cada visita
# ofrece el siguiente escenario sin responder.
# ============================================================
extends Area2D

const MISION_MOVILIDAD_ESCENA := preload("res://scenes/misiones/mision_movilidad.gd")

@export var nombre_punto : String = "Oficina de Movilidad Sostenible"

signal movilidad_solicitada(punto: Area2D, mision_id: String)

const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool  = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null


# ── Icono visual: caseta con letrero ──────────────────────────
class KioskIcon extends Node2D:
	var completo : bool  = false
	var _t        : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2(0, 12), 16.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		var glow_a := 0.10 + 0.08 * sin(_t * 2.0)
		draw_circle(Vector2.ZERO, 30.0, Color(0.20, 0.55, 0.92, glow_a))
		# Caseta
		var col_base : Color = Color(0.15, 0.45, 0.85) if not completo else Color(0.18, 0.85, 0.35)
		draw_rect(Rect2(-16, -6, 32, 22), col_base.darkened(0.4))
		draw_rect(Rect2(-16, -6, 32, 22), col_base, false, 2.0)
		# Techo
		draw_colored_polygon(PackedVector2Array([
			Vector2(-20, -6), Vector2(20, -6), Vector2(16, -18), Vector2(-16, -18)
		]), col_base.darkened(0.2))
		# Letrero con ícono de bici
		draw_rect(Rect2(-9, -30, 18, 12), Color(0.04, 0.10, 0.18))
		draw_circle(Vector2(-4, -21), 3.5, Color.TRANSPARENT)
		draw_arc(Vector2(-4, -21), 3.0, 0.0, TAU, 10, Color(0.55, 0.85, 1.0), 1.2)
		draw_arc(Vector2(4, -21), 3.0, 0.0, TAU, 10, Color(0.55, 0.85, 1.0), 1.2)
		draw_line(Vector2(-4, -21), Vector2(0, -26), Color(0.55, 0.85, 1.0), 1.2)
		draw_line(Vector2(0, -26), Vector2(4, -21), Color(0.55, 0.85, 1.0), 1.2)
		if completo:
			draw_line(Vector2(-4, 4), Vector2(-1, 8), Color.WHITE, 2.2)
			draw_line(Vector2(-1, 8), Vector2(6, -2), Color.WHITE, 2.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("oficina_movilidad")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	_actualizar_icono()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := KioskIcon.new()
	icon.z_index = 1
	add_child(icon)
	set_meta("kiosk_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(320, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.06, 0.10, 0.93)
	ps.border_color = Color(0.20, 0.55, 0.92)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.05, 0.25, 0.50, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 12)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	_prompt_panel.add_child(_prompt_lbl)


func _process(_delta: float) -> void:
	if _jugador_cerca:
		_actualizar_prompt_texto()
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-160, -90)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _proximo_escenario_id() -> String:
	var nm = _nivel_mgr()
	for esc : Dictionary in MISION_MOVILIDAD_ESCENA.ESCENARIOS_MOVILIDAD:
		var id : String = esc["id"]
		if not (nm and nm.mision_completada_q(5, id)):
			return id
	return ""


func _actualizar_prompt_texto() -> void:
	var restante := _proximo_escenario_id()
	if restante.is_empty():
		_prompt_lbl.text = "✅ Ya resolviste todas las decisiones de movilidad"
	else:
		var n_hechas := MISION_MOVILIDAD_ESCENA.ESCENARIOS_MOVILIDAD.size() - _contar_pendientes()
		_prompt_lbl.text = "🚲 [E] Decisión de movilidad (%d/%d) — %s" % [
			n_hechas + 1, MISION_MOVILIDAD_ESCENA.ESCENARIOS_MOVILIDAD.size(), nombre_punto]


func _contar_pendientes() -> int:
	var nm = _nivel_mgr()
	var n := 0
	for esc : Dictionary in MISION_MOVILIDAD_ESCENA.ESCENARIOS_MOVILIDAD:
		if not (nm and nm.mision_completada_q(5, esc["id"])):
			n += 1
	return n


func _actualizar_icono() -> void:
	var icon = get_meta("kiosk_icon", null)
	if icon and is_instance_valid(icon):
		icon.completo = _proximo_escenario_id().is_empty()


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
	if not _jugador_cerca: return
	var siguiente := _proximo_escenario_id()
	if siguiente.is_empty(): return
	_prompt_panel.visible = false
	movilidad_solicitada.emit(self, siguiente)


func _notificar_escenario_resuelto() -> void:
	_actualizar_icono()
	if _jugador_cerca:
		_actualizar_prompt_texto()
