# ============================================================
# dialogo_npc.gd - URBE Rangers: Eco-Quest
# Panel inferior mejorado: retrato de color, nombre del NPC,
# efecto typewriter letra a letra. Al terminar emite señal
# para lanzar el quiz del módulo.
# ============================================================
extends CanvasLayer

signal dialogo_terminado(mision_id: String)

# — Nodos (creados en _crear_ui) ————————————————————————————
var _retrato    : ColorRect = null
var _nombre_lbl : Label     = null
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

	_retrato = ColorRect.new()
	_retrato.custom_minimum_size = Vector2(90, 116)
	_retrato.color = Color(0.3, 0.3, 0.3)
	col_izq.add_child(_retrato)

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
	_retrato.color   = color
	_nombre_lbl.text = nombre
	_mostrar_linea()
	show()


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
