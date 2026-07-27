# ============================================================
# npc.gd — URBE Rangers: Eco-Quest
# NPC con visual procedural moderno, burbuja animada,
# glow pulsante cuando el jugador se acerca.
# ============================================================
extends Area2D

@export var nombre_npc : String            = "NPC"
@export var mision_id  : String            = ""
@export var dialogos   : PackedStringArray = PackedStringArray(["Hola."])
@export var color      : Color             = Color(0.5, 0.5, 0.5)

signal mision_iniciada(id: String)

var _burbuja      : Control  = null
var _jugador_cerca: bool     = false
var _tween_bounce : Tween    = null
var _char_visual  : NpcChar  = null


# ════════════════════════════════════════════════════════════
# INNER CLASS — personaje dibujado proceduralmente
# Cada NPC tiene un color único → silueta única.
# ════════════════════════════════════════════════════════════
class NpcChar extends Node2D:
	var col     : Color = Color(0.5, 0.5, 0.5)
	var glow_on : bool  = false
	var _t      : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var puls := 1.0 + 0.03 * sin(_t * 2.2)
		var bob  := sin(_t * 1.8) * 1.2        # respiración suave

		# ── Halo (activo solo al acercarse el jugador) ────────
		if glow_on:
			var ga := 0.13 + 0.09 * sin(_t * 3.0)
			draw_circle(Vector2(0, -12), 21.0, Color(col.r, col.g, col.b, ga))
			draw_arc(Vector2(0, -12), 24.0, 0.0, TAU, 32,
					 Color(col.r, col.g, col.b, ga * 0.5), 1.5)

		# ── Sombra en el suelo ────────────────────────────────
		draw_arc(Vector2(0, 1), 9.0, 0.0, PI, 12, Color(0.0, 0.0, 0.0, 0.22), 7.0)

		# ── Cuerpo (trapecio redondeado) ──────────────────────
		var bc := col.darkened(0.28)
		var body := PackedVector2Array([
			Vector2(-7, bob - 15), Vector2( 7, bob - 15),
			Vector2( 8, bob -  1), Vector2(-8, bob -  1)
		])
		draw_colored_polygon(body, bc)
		for i in body.size():
			draw_line(body[i], body[(i + 1) % body.size()],
					  col.lightened(0.22), 1.2)

		# Brillo en hombro izquierdo
		draw_arc(Vector2(-7, bob - 13), 3.2, PI, PI * 1.65, 8,
				 col.lightened(0.55), 1.6)

		# ── Cuello ────────────────────────────────────────────
		draw_rect(Rect2(-2.2, bob - 19.5, 4.4, 5.5), col.darkened(0.12))

		# ── Cabeza ────────────────────────────────────────────
		var hp := Vector2(0, bob - 27.5)
		var hr := 10.2 * puls
		draw_circle(hp, hr, col.lightened(0.08))
		draw_arc(hp, hr, 0.0, TAU, 28, col.lightened(0.38), 1.8)

		# ── Ojos ──────────────────────────────────────────────
		var el := hp + Vector2(-3.5, -1.2)
		var er := hp + Vector2( 3.5, -1.2)
		draw_circle(el, 1.95, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(er, 1.95, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(el + Vector2(0.2,  0.3), 1.1, Color(0.08, 0.04, 0.18))
		draw_circle(er + Vector2(0.2,  0.3), 1.1, Color(0.08, 0.04, 0.18))
		draw_circle(el + Vector2(0.8, -0.6), 0.45, Color(1.0, 1.0, 1.0, 0.88))
		draw_circle(er + Vector2(0.8, -0.6), 0.45, Color(1.0, 1.0, 1.0, 0.88))

		# ── Boca (sonrisa) ────────────────────────────────────
		draw_arc(hp + Vector2(0, 4.5), 4.0, 0.28, PI - 0.28, 10,
				 col.lightened(0.55), 1.7)

		# ── Collar ────────────────────────────────────────────
		draw_arc(hp + Vector2(0, 7.8), 3.9, 0.4, PI - 0.4, 10,
				 col.lightened(0.48), 1.5)


# ════════════════════════════════════════════════════════════
# READY
# ════════════════════════════════════════════════════════════
func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	_ocultar_sprite_placeholder()
	_crear_char_visual()
	_crear_burbuja()


func _ocultar_sprite_placeholder() -> void:
	var vis : Node = get_node_or_null("Visual")
	if vis:
		vis.visible = false


func _crear_char_visual() -> void:
	_char_visual       = NpcChar.new()
	_char_visual.col   = color
	_char_visual.scale = Vector2(1.55, 1.55)
	add_child(_char_visual)


# ════════════════════════════════════════════════════════════
# BURBUJA DE NOMBRE
# ════════════════════════════════════════════════════════════
func _crear_burbuja() -> void:
	_burbuja = Control.new()
	_burbuja.custom_minimum_size = Vector2(0, 40)
	_burbuja.visible = false
	add_child(_burbuja)

	# Panel de la burbuja
	var fondo := Panel.new()
	fondo.name = "Fondo"
	var sb := StyleBoxFlat.new()
	sb.bg_color     = color.darkened(0.35)
	sb.bg_color.a   = 0.92
	sb.border_color = color.lightened(0.20)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color  = Color(0, 0, 0, 0.45)
	sb.shadow_size   = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left   = 8
	sb.content_margin_right  = 8
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	fondo.add_theme_stylebox_override("panel", sb)
	_burbuja.add_child(fondo)

	# Etiqueta del nombre
	var nombre_lbl := Label.new()
	nombre_lbl.name = "Nombre"
	nombre_lbl.text = nombre_npc
	nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_lbl.add_theme_font_size_override("font_size", 11)
	nombre_lbl.add_theme_color_override("font_color", Color.WHITE)
	fondo.add_child(nombre_lbl)

	await get_tree().process_frame
	if not is_instance_valid(nombre_lbl): return

	var ancho : float = max(nombre_lbl.size.x + 18.0, 60.0)
	var alto  : float = 26.0

	# NpcChar a escala 1.55: cabeza aprox en y=-27.5*1.55=-42.6, radio=10.2*1.55=15.8
	# Tope de la cabeza en espacio padre: -42.6 - 15.8 = -58.4
	# Colocamos el borde inferior de fondo a -64 para dejar 6px de margen
	fondo.position = Vector2(-ancho * 0.5, -alto - 64.0)
	fondo.size     = Vector2(ancho, alto)

	# Punto indicador pulsante bajo la burbuja
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.position            = Vector2(ancho * 0.5 - 4.0, alto - 1.0)
	var ds := StyleBoxFlat.new()
	ds.bg_color = color.lightened(0.28)
	ds.set_corner_radius_all(4)
	dot.add_theme_stylebox_override("panel", ds)
	fondo.add_child(dot)
	var tw_dot := dot.create_tween().set_loops()
	tw_dot.tween_property(dot, "modulate:a", 0.22, 0.55)
	tw_dot.tween_property(dot, "modulate:a", 1.0,  0.55)

	_iniciar_bounce()


func _iniciar_bounce() -> void:
	if not is_instance_valid(_burbuja): return
	if _tween_bounce: _tween_bounce.kill()
	_tween_bounce = create_tween().set_loops()
	_tween_bounce.tween_property(_burbuja, "position:y", -6.0, 0.42).set_ease(Tween.EASE_IN_OUT)
	_tween_bounce.tween_property(_burbuja, "position:y", -2.0, 0.42).set_ease(Tween.EASE_IN_OUT)


# ════════════════════════════════════════════════════════════
# EVENTOS DE COLISIÓN
# ════════════════════════════════════════════════════════════
func _al_entrar(body: Node) -> void:
	if body.is_in_group("jugador"):
		body.npc_cercano = self
		_jugador_cerca   = true

		if is_instance_valid(_char_visual):
			_char_visual.glow_on = true

		# Pista contextual: primera vez que el jugador se acerca a un NPC
		var hb = get_tree().get_first_node_in_group("hint_bubble")
		if hb:
			hb.push("primer_npc", "💬 ¡Presiona [E] para hablar con el NPC!")

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

		if is_instance_valid(_char_visual):
			_char_visual.glow_on = false

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
