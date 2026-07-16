# ============================================================
# npc.gd — URBE Rangers: Eco-Quest
# NPC base: burbuja de nombre animada, indicador visual rico.
# ============================================================
extends Area2D

@export var nombre_npc : String            = "NPC"
@export var mision_id  : String            = ""
@export var dialogos   : PackedStringArray = PackedStringArray(["Hola."])
@export var color      : Color             = Color(0.5, 0.5, 0.5)

signal mision_iniciada(id: String)

var _burbuja       : Control  = null
var _jugador_cerca : bool     = false
var _tween_bounce  : Tween    = null


func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	_crear_burbuja()


func _crear_burbuja() -> void:
	_burbuja = Control.new()
	_burbuja.custom_minimum_size = Vector2(0, 40)
	_burbuja.visible = false
	add_child(_burbuja)

	# Fondo de la burbuja con el color del NPC
	var fondo := Panel.new()
	fondo.name = "Fondo"
	var sb := StyleBoxFlat.new()
	sb.bg_color   = color.darkened(0.35)
	sb.bg_color.a = 0.92
	sb.border_color = color.lightened(0.20)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size  = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left   = 8
	sb.content_margin_right  = 8
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	fondo.add_theme_stylebox_override("panel", sb)
	_burbuja.add_child(fondo)

	# Nombre del NPC
	var nombre_lbl := Label.new()
	nombre_lbl.name = "Nombre"
	nombre_lbl.text = nombre_npc
	nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_lbl.add_theme_font_size_override("font_size", 11)
	nombre_lbl.add_theme_color_override("font_color", Color.WHITE)
	fondo.add_child(nombre_lbl)

	# Medir tamaño
	await get_tree().process_frame
	if not is_instance_valid(nombre_lbl): return
	var ancho  : float = max(nombre_lbl.size.x + 18.0, 60.0)
	var alto   : float = 26.0
	fondo.position = Vector2(-ancho * 0.5, -alto - 30)
	fondo.size     = Vector2(ancho, alto)

	# Pequeño triángulo indicador
	var flecha := _crear_flecha(ancho, alto)
	fondo.add_child(flecha)

	# Animación de rebote suave
	_iniciar_bounce()


func _crear_flecha(ancho: float, alto: float) -> Node2D:
	var tri := Node2D.new()
	tri.position = Vector2(ancho * 0.5, alto - 1)
	return tri


func _iniciar_bounce() -> void:
	if not is_instance_valid(_burbuja): return
	if _tween_bounce: _tween_bounce.kill()
	_tween_bounce = create_tween().set_loops()
	_tween_bounce.tween_property(_burbuja, "position:y", -6.0, 0.42).set_ease(Tween.EASE_IN_OUT)
	_tween_bounce.tween_property(_burbuja, "position:y", -2.0, 0.42).set_ease(Tween.EASE_IN_OUT)


func _al_entrar(body: Node) -> void:
	if body.is_in_group("jugador"):
		body.npc_cercano = self
		_jugador_cerca   = true
		if is_instance_valid(_burbuja):
			_burbuja.modulate.a = 0.0
			_burbuja.visible    = true
			var tw := create_tween()
			tw.tween_property(_burbuja, "modulate:a", 1.0, 0.22)
			tw.parallel().tween_property(_burbuja, "scale",
										 Vector2(1.0, 1.0), 0.22).from(Vector2(0.5, 0.5))


func _al_salir(body: Node) -> void:
	if body.is_in_group("jugador") and body.npc_cercano == self:
		body.npc_cercano = null
		_jugador_cerca   = false
		if is_instance_valid(_burbuja):
			var tw := create_tween()
			tw.tween_property(_burbuja, "modulate:a", 0.0, 0.18)
			tw.tween_callback(func(): _burbuja.visible = false)


func iniciar_dialogo() -> void:
	if is_instance_valid(_burbuja):
		_burbuja.visible = false
	var ui = get_tree().get_first_node_in_group("ui_dialogo")
	if ui:
		ui.iniciar(nombre_npc, dialogos, mision_id, color)
	if mision_id != "":
		mision_iniciada.emit(mision_id)
