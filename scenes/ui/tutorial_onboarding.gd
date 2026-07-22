# ============================================================
# tutorial_onboarding.gd — URBE Rangers: Eco-Quest
# Tutorial interactivo de 7 pasos para la primera sesión.
# Typewriter, puntos de progreso, tecla [E] para avanzar.
# ============================================================
extends CanvasLayer

signal tutorial_completado()

const PASOS : Array = [
	{
		"emoji": "🌍",
		"titulo": "¡Bienvenido a URBE Rangers: Eco-Quest!",
		"texto": "Eres un estudiante de URBE comprometido con la sostenibilidad del campus. Tu misión: mejorar la posición de la universidad en el ranking internacional UI GreenMetric.",
	},
	{
		"emoji": "📊",
		"titulo": "¿Qué es UI GreenMetric?",
		"texto": "UI GreenMetric evalúa universidades del mundo en 6 módulos de sostenibilidad: Entorno, Energía, Residuos, Agua, Transporte y Educación. URBE necesita tu ayuda para subir de posición.",
	},
	{
		"emoji": "🕹️",
		"titulo": "Movimiento del Avatar",
		"texto": "Usa las teclas WASD o las flechas del teclado para moverte por el campus.\n\n     W — Arriba\n A — Izquierda     D — Derecha\n     S — Abajo",
	},
	{
		"emoji": "👤",
		"titulo": "Interacción con NPCs",
		"texto": "Acércate a los personajes del campus (profesores, coordinadores, técnicos) y presiona [E] para interactuar. Cada NPC tiene misiones únicas relacionadas con un módulo GreenMetric.",
	},
	{
		"emoji": "📍",
		"titulo": "Zonas del Campus",
		"texto": "Al entrar a un edificio o zona marcada, aparece un panel en la parte inferior. Presiona [E] para aceptar la misión de esa zona. Cada misión mejora un módulo específico.",
	},
	{
		"emoji": "🏛️",
		"titulo": "ImpactRating — Estado del Campus",
		"texto": "Cada edificio muestra un indicador de color según el desempeño del módulo que representa:\n\n   🔴 Rojo = Estado crítico (< 40%%)\n   🟡 Amarillo = En riesgo (< 75%%)\n   🟢 Verde = Óptimo (≥ 75%%)\n\nTu objetivo es llevar todos los edificios a Verde.",
	},
	{
		"emoji": "🏆",
		"titulo": "¡Comienza tu Eco-Misión!",
		"texto": "Dirígete al Rectorado (zona central) y habla con el Rector Morales para recibir tu primera misión oficial. Completa los 6 módulos para convertirte en EcoLíder de URBE.\n\nPresiona [E] o el botón para comenzar.",
	},
]

const CHARS_SEG : float = 40.0

var _paso_actual    : int    = 0
var _texto_completo : String = ""
var _chars_vis      : int    = 0
var _timer_tw       : float  = 0.0
var _escribiendo    : bool   = false

var _overlay        : ColorRect      = null
var _panel          : Panel          = null
var _emoji_lbl      : Label          = null
var _titulo_lbl     : Label          = null
var _texto_lbl      : Label          = null
var _dots_row       : HBoxContainer  = null
var _btn_siguiente  : Button         = null
var _btn_saltar     : Button         = null
var _hint_lbl       : Label          = null


func _ready() -> void:
	layer = 20
	add_to_group("ui_tutorial")
	_crear_ui()
	hide()


func iniciar() -> void:
	_paso_actual = 0
	show()
	_mostrar_paso()


func _mostrar_paso() -> void:
	var p  : Dictionary = PASOS[_paso_actual]
	_emoji_lbl.text  = p["emoji"]
	_titulo_lbl.text = p["titulo"]
	_texto_completo  = p["texto"]
	_chars_vis       = 0
	_timer_tw        = 0.0
	_escribiendo     = true
	_texto_lbl.text  = ""

	var es_ultimo : bool = (_paso_actual == PASOS.size() - 1)
	_btn_siguiente.text = "  ¡Comenzar!  " if es_ultimo else "  Siguiente →  "

	_actualizar_dots()

	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _process(delta: float) -> void:
	if not visible or not _escribiendo: return
	_timer_tw += delta
	var meta : int = int(_timer_tw * CHARS_SEG)
	if meta > _chars_vis:
		_chars_vis      = mini(meta, _texto_completo.length())
		_texto_lbl.text = _texto_completo.substr(0, _chars_vis)
		if _chars_vis >= _texto_completo.length():
			_escribiendo = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		if _escribiendo:
			_chars_vis      = _texto_completo.length()
			_texto_lbl.text = _texto_completo
			_escribiendo    = false
		else:
			_on_siguiente()


func _on_siguiente() -> void:
	_paso_actual += 1
	if _paso_actual >= PASOS.size():
		_finalizar()
	else:
		_mostrar_paso()


func _finalizar() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func():
		hide()
		tutorial_completado.emit())


func _actualizar_dots() -> void:
	var hijos := _dots_row.get_children()
	for i in hijos.size():
		var d : ColorRect = hijos[i]
		d.color = Color(0.25, 0.90, 0.25) if i == _paso_actual else Color(0.18, 0.28, 0.40)


# ── Construcción UI ───────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.80)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 440)
	_panel.offset_left   = -350.0
	_panel.offset_top    = -220.0
	_panel.offset_right  =  350.0
	_panel.offset_bottom =  220.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.13, 0.98)
	ps.border_color = Color(0.22, 0.78, 0.22)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.10, 0.60, 0.18, 0.50)
	ps.shadow_size  = 28
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 34)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	_emoji_lbl = Label.new()
	_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_lbl.add_theme_font_size_override("font_size", 44)
	vbox.add_child(_emoji_lbl)

	_titulo_lbl = Label.new()
	_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	_titulo_lbl.add_theme_font_size_override("font_size", 19)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.28, 0.95, 0.28))
	vbox.add_child(_titulo_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	_texto_lbl = Label.new()
	_texto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_texto_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	_texto_lbl.add_theme_font_size_override("font_size", 14)
	_texto_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_texto_lbl)

	_dots_row = HBoxContainer.new()
	_dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_row.add_theme_constant_override("separation", 10)
	for _i in PASOS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.color = Color(0.18, 0.28, 0.40)
		_dots_row.add_child(dot)
	vbox.add_child(_dots_row)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_btn_saltar = Button.new()
	_btn_saltar.text = "Saltar tutorial"
	_btn_saltar.add_theme_font_size_override("font_size", 12)
	_btn_saltar.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	var s_skip := StyleBoxFlat.new()
	s_skip.bg_color     = Color(0.08, 0.10, 0.16)
	s_skip.border_color = Color(0.22, 0.28, 0.42)
	s_skip.set_border_width_all(1)
	s_skip.set_corner_radius_all(8)
	_btn_saltar.add_theme_stylebox_override("normal", s_skip)
	_btn_saltar.pressed.connect(_finalizar)
	btn_row.add_child(_btn_saltar)

	_btn_siguiente = Button.new()
	_btn_siguiente.text = "  Siguiente →  "
	_btn_siguiente.custom_minimum_size = Vector2(210, 46)
	_btn_siguiente.add_theme_font_size_override("font_size", 15)
	var s_next := StyleBoxFlat.new()
	s_next.bg_color     = Color(0.06, 0.34, 0.08)
	s_next.border_color = Color(0.22, 0.84, 0.22)
	s_next.set_border_width_all(2)
	s_next.set_corner_radius_all(12)
	_btn_siguiente.add_theme_stylebox_override("normal", s_next)
	var s_next_h := s_next.duplicate()
	s_next_h.bg_color = Color(0.10, 0.48, 0.12)
	_btn_siguiente.add_theme_stylebox_override("hover", s_next_h)
	_btn_siguiente.pressed.connect(_on_siguiente)
	btn_row.add_child(_btn_siguiente)

	_hint_lbl = Label.new()
	_hint_lbl.text = "[E] para avanzar"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 10)
	_hint_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	vbox.add_child(_hint_lbl)
