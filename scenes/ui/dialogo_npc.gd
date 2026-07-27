# ============================================================
# dialogo_npc.gd - URBE Rangers: Eco-Quest
# Panel inferior mejorado: retrato de color, nombre del NPC,
# efecto typewriter letra a letra. Al terminar emite señal
# para lanzar el quiz del módulo.
# ============================================================
extends CanvasLayer

signal dialogo_terminado(mision_id: String)

# — Nodos (creados en _crear_ui) ————————————————————————————
var _retrato_nodo : RetratoNPC = null
var _nombre_lbl   : Label      = null
var _texto_lbl  : Label     = null
var _hint_lbl   : Label     = null

# — Estado del diálogo ————————————————————————————————————
var _dialogos  : PackedStringArray = []
var _indice    : int    = 0
var _mision_id : String = ""

# — Typewriter ————————————————————————————————————————————
var _texto_completo : String = ""
var _chars_vis      : int    = 0
var _timer          : float  = 0.0
var _escribiendo    : bool   = false
const CHARS_SEG     : float  = 38.0


# ════════════════════════════════════════════════════════════
# INNER CLASS — Retrato animado del NPC (90 × 116 px)
# Se dibuja proceduralmente con el color único de cada NPC.
# ════════════════════════════════════════════════════════════
class RetratoNPC extends Node2D:
	var col : Color = Color(0.5, 0.5, 0.5)
	var _t  : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var puls := 1.0 + 0.04 * sin(_t * 2.2)
		var bob  := sin(_t * 1.5) * 1.5

		# — Glow de fondo ─────────────────────────────────────
		var ga := 0.09 + 0.05 * sin(_t * 1.8)
		draw_circle(Vector2(45, 58), 50.0, Color(col.r, col.g, col.b, ga))

		# — Cuerpo ────────────────────────────────────────────
		var body_pts := PackedVector2Array([
			Vector2(22, 90), Vector2(68, 90),
			Vector2(72, 116), Vector2(18, 116)
		])
		draw_colored_polygon(body_pts, col.darkened(0.28))
		for i in body_pts.size():
			draw_line(body_pts[i], body_pts[(i + 1) % body_pts.size()],
					  col.lightened(0.22), 1.5)
		# Brillo en hombro
		draw_arc(Vector2(22, 92), 6.0, PI, PI * 1.6, 8, col.lightened(0.55), 2.0)

		# — Cuello ────────────────────────────────────────────
		draw_rect(Rect2(40, 82, 10, 10), col.darkened(0.10))

		# — Cabeza ────────────────────────────────────────────
		var hp := Vector2(45, bob + 62)
		draw_circle(hp, 22.0 * puls, col.lightened(0.08))
		draw_arc(hp, 22.0 * puls, 0.0, TAU, 32, col.lightened(0.35), 2.0)

		# — Ojos ──────────────────────────────────────────────
		var el := hp + Vector2(-7.5, -3.0)
		var er := hp + Vector2( 7.5, -3.0)
		draw_circle(el, 4.5, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(er, 4.5, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(el + Vector2( 0.5,  0.5), 2.5, Color(0.08, 0.04, 0.18))
		draw_circle(er + Vector2( 0.5,  0.5), 2.5, Color(0.08, 0.04, 0.18))
		draw_circle(el + Vector2( 2.0, -1.5), 1.0, Color(1.0, 1.0, 1.0, 0.88))
		draw_circle(er + Vector2( 2.0, -1.5), 1.0, Color(1.0, 1.0, 1.0, 0.88))

		# — Boca (sonrisa) ────────────────────────────────────
		draw_arc(hp + Vector2(0, 8.0), 7.5, 0.30, PI - 0.30, 10,
				 col.lightened(0.60), 2.0)

		# — Collar ────────────────────────────────────────────
		draw_arc(hp + Vector2(0, 17.0), 9.0, 0.40, PI - 0.40, 10,
				 col.lightened(0.45), 2.0)

		# — Marco circular decorativo ─────────────────────────
		draw_arc(Vector2(45, 58), 44.0, 0.0, TAU, 32,
				 Color(col.r, col.g, col.b, 0.38), 1.5)


func _ready() -> void:
	layer = 10
	add_to_group("ui_dialogo")
	_crear_ui()
	hide()


func _crear_ui() -> void:
	# ── Panel principal (ancho completo, pegado abajo) ────────
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = -185.0
	panel.offset_bottom =    0.0

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.055, 0.07, 0.11, 0.96)
	ps.border_color = Color(0.22, 0.72, 0.22)
	ps.set_border_width_all(2)
	ps.corner_radius_top_left  = 10
	ps.corner_radius_top_right = 10
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	# Franja de acento verde en el borde superior del panel
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 3)
	acento.offset_bottom       = 3.0
	acento.color               = Color(0.22, 0.80, 0.28, 0.65)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	panel.add_child(acento)

	# ── Margen interior ──────────────────────────────────────
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   16)
	mg.add_theme_constant_override("margin_right",  16)
	mg.add_theme_constant_override("margin_top",    10)
	mg.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(mg)

	# ── HBox: izquierda (retrato+nombre) | derecha (texto+hint)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	mg.add_child(hbox)

	# ── Columna izquierda ────────────────────────────────────
	var col_izq := VBoxContainer.new()
	col_izq.custom_minimum_size   = Vector2(102, 0)
	col_izq.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.alignment             = BoxContainer.ALIGNMENT_CENTER
	col_izq.add_theme_constant_override("separation", 5)
	hbox.add_child(col_izq)

	var retrato_cont := Control.new()
	retrato_cont.custom_minimum_size = Vector2(90, 116)
	retrato_cont.clip_contents       = true
	col_izq.add_child(retrato_cont)

	_retrato_nodo = RetratoNPC.new()
	retrato_cont.add_child(_retrato_nodo)

	_nombre_lbl = Label.new()
	_nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	_nombre_lbl.add_theme_font_size_override("font_size", 12)
	_nombre_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.45))
	col_izq.add_child(_nombre_lbl)

	# ── Separador vertical ───────────────────────────────────
	var vsep := VSeparator.new()
	var vs := StyleBoxFlat.new()
	vs.bg_color = Color(0.22, 0.72, 0.22, 0.40)
	vs.content_margin_left = 1.0
	vsep.add_theme_stylebox_override("separator", vs)
	hbox.add_child(vsep)

	# ── Columna derecha ──────────────────────────────────────
	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_der)

	_texto_lbl = Label.new()
	_texto_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_texto_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	_texto_lbl.add_theme_font_size_override("font_size", 16)
	_texto_lbl.add_theme_color_override("font_color", Color.WHITE)
	col_der.add_child(_texto_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.38, 0.90, 0.38))
	col_der.add_child(_hint_lbl)


# ── API pública ───────────────────────────────────────────────
func iniciar(nombre: String, textos: PackedStringArray,
			 mision_id: String = "", color: Color = Color.GRAY) -> void:
	_dialogos  = textos
	_indice    = 0
	_mision_id = mision_id
	if _retrato_nodo:
		_retrato_nodo.col = color
	_nombre_lbl.text = nombre
	_mostrar_linea()
	show()
	# Pista contextual: primera vez que se abre un diálogo
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_dialogo",
			"📖 Lee el mensaje del NPC y presiona [E] para continuar.")


# ── Internos ─────────────────────────────────────────────────
func _mostrar_linea() -> void:
	_texto_completo = _dialogos[_indice]
	_chars_vis      = 0
	_timer          = 0.0
	_escribiendo    = true
	_texto_lbl.text = ""
	var es_ultimo   := (_indice >= _dialogos.size() - 1)
	if es_ultimo and _mision_id != "":
		_hint_lbl.text = "[E] Continuar misión"
	elif es_ultimo:
		_hint_lbl.text = "[E] Cerrar"
	else:
		_hint_lbl.text = "[E] Continuar"


func _process(delta: float) -> void:
	if not visible or not _escribiendo:
		return
	_timer += delta
	var meta := int(_timer * CHARS_SEG)
	if meta > _chars_vis:
		_chars_vis      = mini(meta, _texto_completo.length())
		_texto_lbl.text = _texto_completo.substr(0, _chars_vis)
		if _chars_vis >= _texto_completo.length():
			_escribiendo = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("interactuar"):
		return
	get_viewport().set_input_as_handled()

	if _escribiendo:
		# Saltar typewriter: mostrar texto completo al instante
		_chars_vis      = _texto_completo.length()
		_texto_lbl.text = _texto_completo
		_escribiendo    = false
		return

	_indice += 1
	if _indice >= _dialogos.size():
		hide()
		_indice = 0
		dialogo_terminado.emit(_mision_id)
	else:
		_mostrar_linea()
