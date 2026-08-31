# ============================================================
# zona_reciclaje.gd — NIVEL 3: Manejo de Residuos
# Punto de donación de reciclables en el mapa del campus.
# Incluye llenado progresivo en el tiempo y servicio de recolección
# con trabajador animado caminando hacia la papelera.
# ============================================================
extends Area2D

@export var mision_id   : String = "reciclar_1"
@export var nombre_zona : String = "Punto de Donación"

signal reciclar_solicitado(zona: Area2D)
signal vaciado_servicio(xp: int, ec: int)

const RADIO_DETEC  : float = 55.0
const RADIO_VISUAL : float = 26.0
const TASA_LLENADO : float = 0.0025   # ~6 min de 0 a 100%

var _jugador_cerca : bool  = false
var _completada    : bool  = false
var _t             : float = 0.0

var nivel_llenado : float = 0.25   # 0.0 .. 1.0
var en_servicio   : bool  = false

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null
var _visual_node   : Node2D      = null


# ── Visual del recolector ─────────────────────────────────────
# Fases de animación (controladas externamente via 'fase'):
#   0 = caminando hacia la papelera
#   1 = agachándose (transición ~0.6 s)
#   2 = recogiendo / reciclando (mantenida)
#   3 = levantándose (transición ~0.5 s)
#   4 = retirándose caminando
class TrabajadorVisual extends Node2D:
	var _t_walk : float  = 0.0   # acumula delta para el swing de piernas/brazos
	var _t_fase : float  = 0.0   # tiempo dentro de la fase actual

	# Fase controlada externamente (0..4)
	var fase    : int    = 0
	# Cuánto de "agachado" está (0.0 = erguido, 1.0 = agachado al máximo)
	var _bend   : float  = 0.0
	# Ángulo del brazo derecho para el movimiento circular de reciclaje
	var _recycle_ang : float = 0.0

	# Duración de cada transición de inclinación
	const BEND_SPEED := 1.6   # unidades/seg hasta llegar a 1.0 o 0.0

	func _process(delta: float) -> void:
		_t_fase += delta
		_t_walk += delta

		match fase:
			0: # Caminando - piernas se mueven
				pass
			1: # Agacharse suavemente
				_bend = minf(_bend + BEND_SPEED * delta, 1.0)
			2: # Recogiendo - mover brazos en círculo lento de reciclaje
				_recycle_ang += delta * 2.2   # rotación lenta
			3: # Levantarse suavemente
				_bend = maxf(_bend - BEND_SPEED * delta, 0.0)
			4: # Caminando de vuelta - piernas se mueven
				pass

		queue_redraw()

	func _draw() -> void:
		var caminando : bool = (fase == 0 or fase == 4)

		# Oscilación de piernas solo al caminar
		var leg_swing : float = sin(_t_walk * 9.0) * 6.0 if caminando else 0.0

		# Offset vertical del cuerpo cuando está agachado (máx 10 px hacia abajo)
		var B : float = _bend * 10.0

		# ── Sombra ────────────────────────────────────────────────
		draw_arc(Vector2(0, 16 + B * 0.3), 12.0, 0.0, PI, 10,
				Color(0.0, 0.0, 0.0, 0.25 + _bend * 0.15), 4.0)

		# ── Piernas ───────────────────────────────────────────────
		# Al agacharse las rodillas se separan hacia fuera
		var knee_off : float = _bend * 4.0
		draw_line(Vector2(-4, 4 + B * 0.3),
				  Vector2(-4 - knee_off + leg_swing, 16), Color(0.35, 0.22, 0.12), 3.5)
		draw_line(Vector2(4, 4 + B * 0.3),
				  Vector2(4 + knee_off - leg_swing, 16), Color(0.35, 0.22, 0.12), 3.5)

		# ── Botas ─────────────────────────────────────────────────
		draw_circle(Vector2(-4 - knee_off + leg_swing, 16), 2.5, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(4 + knee_off - leg_swing, 16), 2.5, Color(0.1, 0.1, 0.1))

		# ── Cuerpo (chaqueta verde) ────────────────────────────────
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, -8 + B), Vector2(7, -8 + B),
			Vector2(8,  5  + B * 0.5), Vector2(-8, 5 + B * 0.5)
		]), Color(0.12, 0.48, 0.18))

		# Franja reflectiva amarilla
		draw_rect(Rect2(-7, -2 + B * 0.8, 14, 3), Color(0.92, 0.82, 0.08))

		# ── Brazos ────────────────────────────────────────────────
		if fase == 2:
			# Movimiento circular de reciclaje: los brazos giran como rueda
			var r : float = 10.0
			var ang_L : float = _recycle_ang + PI          # brazo izq opuesto
			var ang_R : float = _recycle_ang

			var tip_L := Vector2(cos(ang_L) * r - 6, sin(ang_L) * r + 8 + B)
			var tip_R := Vector2(cos(ang_R) * r + 6, sin(ang_R) * r + 8 + B)

			draw_line(Vector2(-6, -4 + B), tip_L, Color(0.12, 0.48, 0.18), 3.2)
			draw_line(Vector2(6, -4 + B), tip_R, Color(0.12, 0.48, 0.18), 3.2)

			# Manos / puños verdes oscuros
			draw_circle(tip_L, 3.0, Color(0.08, 0.32, 0.12))
			draw_circle(tip_R, 3.0, Color(0.08, 0.32, 0.12))

			# ── Símbolo ♻ animado sobre la papelera ───────────────
			var a_pulse : float = 0.55 + 0.35 * sin(_recycle_ang * 3.0)
			draw_arc(Vector2(0, -22 + B), 10.0,
					 _recycle_ang, _recycle_ang + TAU * 0.75, 18,
					 Color(0.22, 0.95, 0.28, a_pulse), 2.8)
			# Puntita de la flecha del ♻
			var tip_sym := Vector2(
				cos(_recycle_ang + TAU * 0.75) * 10.0,
				sin(_recycle_ang + TAU * 0.75) * 10.0
			) + Vector2(0, -22 + B)
			draw_circle(tip_sym, 2.5, Color(0.22, 0.95, 0.28, a_pulse))

			# Destellos de residuos subiendo desde la papelera
			for i in range(3):
				var off_x : float = cos(_recycle_ang * 1.7 + i * TAU / 3.0) * 14.0
				var off_y : float = -26.0 + B + sin(_recycle_ang * 2.0 + i) * 6.0
				draw_circle(Vector2(off_x, off_y), 2.0,
						Color(0.70, 0.92, 0.28, 0.55 + 0.3 * sin(_recycle_ang + i)))
		else:
			# Brazos caminando normalmente
			var arm_s : float = -sin(_t_walk * 9.0) * 7.0 if caminando else 0.0
			draw_line(Vector2(-7, -5 + B), Vector2(-11, 3.0 + arm_s + B * 0.4),
					  Color(0.12, 0.48, 0.18), 3.0)
			draw_line(Vector2(7, -5 + B), Vector2(11, 3.0 - arm_s + B * 0.4),
					  Color(0.12, 0.48, 0.18), 3.0)

		# ── Cabeza ────────────────────────────────────────────────
		var head_y : float = -14 + B * 1.15
		draw_circle(Vector2(0, head_y), 6.5, Color(0.88, 0.68, 0.48))

		# ── Gorra verde ───────────────────────────────────────────
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, head_y - 2), Vector2(8, head_y - 2),
			Vector2(9,  head_y - 6), Vector2(-9, head_y - 6)
		]), Color(0.08, 0.35, 0.12))
		draw_rect(Rect2(-10, head_y - 2, 15, 3), Color(0.06, 0.28, 0.10))  # Visera


# ── Visual del punto de donación ─────────────────────────────
class BinVisual extends Node2D:
	var completada : bool  = false
	var nivel_fill : float = 0.0
	var _t         : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		_draw_bin()
		if completada and nivel_fill < 0.2:
			_draw_completado_icon()

	func _draw_bin() -> void:
		var colores : Array = [
			Color(0.45, 0.22, 0.08),   # orgánico  (café)
			Color(0.94, 0.78, 0.04),   # plástico  (amarillo)
			Color(0.08, 0.28, 0.85),   # papel     (azul)
			Color(0.10, 0.68, 0.20),   # vidrio    (verde)
			Color(0.52, 0.52, 0.52),   # general   (gris)
		]
		var W : float = 8.0
		var H : float = 14.0
		var GAP : float = 2.0
		var total_w : float = colores.size() * W + (colores.size() - 1) * GAP
		var x0 : float = -total_w * 0.5

		# Sombra
		draw_arc(Vector2(0, 10), total_w * 0.55, 0.0, PI, 14, Color(0.0, 0.0, 0.0, 0.25), 5.0)

		for i in range(colores.size()):
			var cx : float = x0 + i * (W + GAP)
			var base_col : Color = colores[i]

			# Cuerpo de cada papelera pequeña
			draw_rect(Rect2(cx, -H * 0.5, W, H), base_col)
			draw_rect(Rect2(cx, -H * 0.5, W, H), Color(0, 0, 0, 0.7), false, 1.0)

			# Nivel de llenado en cada papelera
			if nivel_fill > 0.05:
				var fill_h := H * nivel_fill
				var fill_col := Color(0.95, 0.28, 0.20, 0.8) if nivel_fill > 0.75 else Color(0.95, 0.95, 0.95, 0.45)
				draw_rect(Rect2(cx + 1, H * 0.5 - fill_h, W - 2, fill_h), fill_col)

			# Tapa
			draw_rect(Rect2(cx - 0.5, -H * 0.5 - 3.0, W + 1, 3.5), base_col.darkened(0.25))
			draw_rect(Rect2(cx - 0.5, -H * 0.5 - 3.0, W + 1, 3.5), Color(0, 0, 0, 0.6), false, 0.8)

		# Anillo pulsante verde o rojo según estado de llenado
		if nivel_fill >= 0.75:
			var p := absf(sin(_t * 4.0))
			draw_arc(Vector2(0, 2), 26.0, 0.0, TAU, 24, Color(0.95, 0.20, 0.15, 0.5 + 0.4 * p), 2.0)
		else:
			var p2 := 0.45 + 0.25 * sin(_t * 2.2)
			draw_arc(Vector2(0, 2), 26.0, 0.0, TAU, 24, Color(0.22, 0.80, 0.28, p2), 1.5)

	func _draw_completado_icon() -> void:
		# Checkmark discreto
		draw_arc(Vector2(0, -18), 10.0, 0.0, TAU, 16, Color(0.22, 0.92, 0.28, 0.9), 2.5)
		draw_line(Vector2(-4, -18), Vector2(-1, -14), Color(0.22, 0.92, 0.28), 2.5)
		draw_line(Vector2(-1, -14), Vector2(5, -22), Color(0.22, 0.92, 0.28), 2.5)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("zona_reciclaje")
	nivel_llenado = randf_range(0.20, 0.50)
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
	_prompt_panel.custom_minimum_size = Vector2(260, 44)
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
	_prompt_lbl.add_theme_font_size_override("font_size", 12)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.88))
	_prompt_panel.add_child(_prompt_lbl)


func _process(delta: float) -> void:
	if not en_servicio:
		nivel_llenado = minf(nivel_llenado + TASA_LLENADO * delta, 1.0)
		if is_instance_valid(_visual_node):
			(_visual_node as BinVisual).nivel_fill = nivel_llenado

	if _jugador_cerca:
		_actualizar_prompt_texto()

	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-130, -80)
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_off   := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_off) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _actualizar_prompt_texto() -> void:
	if en_servicio:
		_prompt_lbl.text = "🧹 Servicio de limpieza en camino..."
		return
	var pct := int(nivel_llenado * 100)
	if not _completada:
		_prompt_lbl.text = "♻ [E] Clasificar residuos — %s (%d%%)" % [nombre_zona, pct]
	elif nivel_llenado >= 0.40:
		_prompt_lbl.text = "🧹 [E] Llamar servicio de limpieza (%d%% lleno)" % pct
	else:
		_prompt_lbl.text = "✅ Papelera limpia — %s (%d%%)" % [nombre_zona, pct]


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
	if not _jugador_cerca or en_servicio: return
	if not _completada:
		_prompt_panel.visible = false
		reciclar_solicitado.emit(self)
	elif nivel_llenado >= 0.35:
		solicitar_servicio_limpieza()


func solicitar_servicio_limpieza() -> void:
	if en_servicio: return
	en_servicio = true
	_actualizar_prompt_texto()

	# 1. Crear trabajador animado a 120 px a la izquierda, fase 0 = caminando
	var trabajador := TrabajadorVisual.new()
	trabajador.position = position + Vector2(-120, 0)
	trabajador.z_index  = 2
	trabajador.fase     = 0
	get_parent().add_child(trabajador)

	var tw := get_tree().create_tween()

	# ── Fase 0: caminar hasta la papelera (2.2 s) ─────────────
	tw.tween_property(trabajador, "position", position + Vector2(-22, 10), 2.2)

	# ── Fase 1: agacharse suavemente (0.7 s) ──────────────────
	tw.tween_callback(func(): trabajador.fase = 1)
	tw.tween_interval(0.7)

	# ── Fase 2: reciclar (brazos girando + ♻) (2.5 s) ─────────
	tw.tween_callback(func(): trabajador.fase = 2)
	tw.tween_interval(2.5)

	# Vaciar la papelera justo al terminar la fase de reciclaje
	tw.tween_callback(func():
		nivel_llenado = 0.0
		if is_instance_valid(_visual_node):
			(_visual_node as BinVisual).nivel_fill = 0.0
		vaciado_servicio.emit(18, 10)
	)

	# ── Fase 3: levantarse suavemente (0.6 s) ─────────────────
	tw.tween_callback(func(): trabajador.fase = 3)
	tw.tween_interval(0.6)

	# ── Fase 4: retirarse caminando (2.0 s) + desvanecer ──────
	tw.tween_callback(func(): trabajador.fase = 4)
	tw.tween_property(trabajador, "position", position + Vector2(-140, 0), 2.0)
	tw.tween_property(trabajador, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		trabajador.queue_free()
		en_servicio = false
		_actualizar_prompt_texto()
	)


func _marcar_completado() -> void:
	_completada = true
	if is_instance_valid(_visual_node):
		(_visual_node as BinVisual).completada = true
		_visual_node.modulate.a = 0.6   # atenuado tras completarse; sigue visible por el llenado ambiental
