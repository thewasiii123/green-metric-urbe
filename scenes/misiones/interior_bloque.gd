# ============================================================
# interior_bloque.gd — NIVEL 2: Energía (Misión LED)
# Interior navegable de un bloque universitario.
# El estudiante se mueve con WASD dentro del pasillo,
# llega a cada luminaria crítica y presiona E para abrirla.
# ============================================================
extends CanvasLayer

signal mision_interior_completada(mision_id: String, xp: int, ec: int)

# ── Datos de los edificios con misiones LED ──────────────────
const BLOQUES : Array = [
	{
		"id":     "led_bloque_a",
		"nombre": "Bloque A — Aulas de Clase",
		"desc":   "Reemplaza las luminarias incandescentes de 100W por tecnología LED con sensor de movimiento.",
		"spots":  [
			{"pos": Vector2(200, 130), "nombre": "Salón A-101"},
			{"pos": Vector2(500, 130), "nombre": "Salón A-102"},
			{"pos": Vector2(350, 280), "nombre": "Pasillo Principal"},
		]
	},
	{
		"id":     "led_bloque_b",
		"nombre": "Bloque B — Laboratorios",
		"desc":   "Los laboratorios de cómputo tienen luminarias de alto consumo. Instala LED inteligente.",
		"spots":  [
			{"pos": Vector2(160, 110), "nombre": "Lab. Redes"},
			{"pos": Vector2(400, 110), "nombre": "Lab. Programación"},
			{"pos": Vector2(640, 240), "nombre": "Sala de Servidores"},
		]
	},
	{
		"id":     "led_bloque_c",
		"nombre": "Bloque C — Oficinas Docentes",
		"desc":   "Las oficinas del cuerpo docente aún usan iluminación fluorescente. Migra a LED inteligente.",
		"spots":  [
			{"pos": Vector2(220, 160), "nombre": "Coord. Académica"},
			{"pos": Vector2(560, 200), "nombre": "Sala de Reuniones"},
		]
	},
]

# ── Dimensiones del mundo interior ──────────────────────────
const ROOM_W      : float = 760.0
const ROOM_H      : float = 380.0
const ROOM_X      : float = 60.0    # posición dentro del panel
const ROOM_Y      : float = 90.0
const PLAYER_R    : float = 10.0
const PLAYER_SPEED: float = 190.0
const SPOT_RADIO  : float = 24.0
const INTERACT_R  : float = 52.0

# ── Estado ───────────────────────────────────────────────────
var _bloque_idx   : int     = 0
var _mision_id    : String  = ""
var _player_pos   : Vector2 = Vector2(ROOM_W * 0.5, ROOM_H - 40)
var _spots_done   : Array   = []   # Array[bool]
var _spot_cercano : int     = -1
var _t            : float   = 0.0
var _zona_ref     : Area2D  = null
var _pasos_done   : int     = 0    # pasos completados del subdiálogo actual

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root   : Panel  = null
var _titulo_lbl   : Label  = null
var _progress_lbl : Label  = null
var _mundo_node   : Node2D = null
var _sub_panel    : Panel  = null
var _sub_paso_lbl : Label  = null
var _sub_desc_lbl : Label  = null
var _sub_visual   : Node2D = null
var _sub_btn      : Button = null
var _sub_barra    : Label  = null
var _hint_e_lbl   : Label  = null
var _btn_salir    : Button = null

# ── Subdiálogo de reemplazo ───────────────────────────────────
const PASOS_LED : Array = [
	{"titulo": "Paso 1 — Apagar el circuito",
	 "desc":   "Antes de cualquier intervención, apaga el interruptor del circuito eléctrico del área para garantizar la seguridad del proceso.",
	 "icono":  "🔌", "color": Color(0.88, 0.50, 0.10)},
	{"titulo": "Paso 2 — Retirar la luminaria antigua",
	 "desc":   "Retira el bombillo incandescente de 100W. Este tipo consume 5x más energía que un LED equivalente y genera más calor residual.",
	 "icono":  "💡", "color": Color(0.85, 0.35, 0.10)},
	{"titulo": "Paso 3 — Instalar LED con sensor",
	 "desc":   "Instala el módulo LED de 12W con sensor de movimiento integrado. Se apaga automáticamente cuando no hay personas en el área.",
	 "icono":  "⚡", "color": Color(0.95, 0.80, 0.10)},
	{"titulo": "Paso 4 — Verificar funcionamiento",
	 "desc":   "Restaura el circuito y verifica que el sensor detecte movimiento correctamente. El ahorro estimado es del 88% del consumo anterior.",
	 "icono":  "✅", "color": Color(0.22, 0.88, 0.30)},
]

var _paso_actual : int = 0


# ── Inner class: dibujo del mundo interior ───────────────────
class MundoInterior extends Node2D:
	const ROOM_W   = 760.0
	const ROOM_H   = 380.0
	const PLAYER_R = 10.0
	const SPOT_RADIO = 24.0
	var player_pos  : Vector2 = Vector2(0, 0)
	var spots       : Array   = []
	var spots_done  : Array   = []
	var spot_cerc   : int     = -1
	var tipo_bloque : int     = 0
	var _t          : float   = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		_draw_room()
		_draw_furniture()
		_draw_spots()
		_draw_player()

	func _draw_room() -> void:
		# Suelo del pasillo
		draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), Color(0.10, 0.12, 0.16))
		# Baldosas
		var tile_size := 40.0
		for xi in int(ROOM_W / tile_size):
			for yi in int(ROOM_H / tile_size):
				var rx := float(xi) * tile_size + 0.5
				var ry := float(yi) * tile_size + 0.5
				draw_rect(Rect2(rx, ry, tile_size - 1.0, tile_size - 1.0),
						  Color(0.13, 0.15, 0.20))
		# Paredes (bordes)
		draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), Color(0.22, 0.30, 0.45), false, 3.0)
		# Líneas de pared norte y sur (más oscuras)
		draw_rect(Rect2(0, 0, ROOM_W, 16), Color(0.15, 0.18, 0.28))
		draw_rect(Rect2(0, ROOM_H - 16, ROOM_W, 16), Color(0.15, 0.18, 0.28))

	func _draw_furniture() -> void:
		# Mobiliario según tipo de bloque
		match tipo_bloque:
			0:   # Aulas: filas de pupitres
				for row in 3:
					for col in 5:
						var fx := 60.0 + float(col) * 130.0
						var fy := 40.0 + float(row) * 95.0
						draw_rect(Rect2(fx, fy, 60, 35), Color(0.18, 0.22, 0.30))
						draw_rect(Rect2(fx, fy, 60, 35), Color(0.25, 0.32, 0.45), false, 1.5)
				# Pizarrón al fondo norte
				draw_rect(Rect2(100, 16, 560, 22), Color(0.08, 0.18, 0.14))
				draw_rect(Rect2(100, 16, 560, 22), Color(0.12, 0.28, 0.20), false, 1.5)
			1:   # Laboratorios: mesas con computadoras
				for row in 2:
					for col in 4:
						var fx := 80.0 + float(col) * 160.0
						var fy := 60.0 + float(row) * 150.0
						draw_rect(Rect2(fx, fy, 100, 50), Color(0.12, 0.16, 0.24))
						draw_rect(Rect2(fx, fy, 100, 50), Color(0.20, 0.28, 0.42), false, 1.5)
						# Pantalla
						draw_rect(Rect2(fx + 15, fy + 6, 60, 36),
								  Color(0.04, 0.06, 0.14))
						draw_rect(Rect2(fx + 15, fy + 6, 60, 36),
								  Color(0.10, 0.40, 0.65, 0.5), false, 1.0)
			2:   # Oficinas: escritorios individuales
				for col in 3:
					var fx := 100.0 + float(col) * 200.0
					draw_rect(Rect2(fx, 80, 120, 60), Color(0.14, 0.18, 0.26))
					draw_rect(Rect2(fx, 80, 120, 60), Color(0.22, 0.30, 0.44), false, 1.5)

	func _draw_spots() -> void:
		var spots_data : Array = spots
		var done : Array = spots_done
		for i in spots_data.size():
			var sp : Dictionary = spots_data[i]
			var sp_pos : Vector2 = sp["pos"]
			var is_done : bool   = i < done.size() and done[i]
			var is_cerc : bool   = (i == spot_cerc)

			if is_done:
				# LED instalado: punto verde con luz
				draw_circle(sp_pos, 20.0, Color(0.15, 0.80, 0.25, 0.22))
				_draw_led_installed(sp_pos)
			else:
				# Bombillo viejo: punto naranja pulsante
				var ga := 0.15 + 0.12 * sin(_t * 3.5 + float(i))
				draw_circle(sp_pos, 28.0, Color(0.90, 0.50, 0.05, ga))
				if is_cerc:
					draw_circle(sp_pos, 30.0, Color(0.95, 0.75, 0.15, ga * 1.5))
					draw_arc(sp_pos, 34.0, 0.0, TAU, 32,
							 Color(0.95, 0.80, 0.20, ga), 2.5)
				_draw_old_bulb(sp_pos)

			# Nombre del spot
			# (dibujamos como líneas de debug — label real en CanvasLayer)
			draw_arc(sp_pos, SPOT_RADIO, 0.0, TAU, 20,
					 Color(0.90, 0.55, 0.10) if not is_done else Color(0.22, 0.88, 0.30),
					 1.5)

	func _draw_old_bulb(p: Vector2) -> void:
		var pulse := 1.0 + 0.08 * sin(_t * 4.0)
		draw_circle(p, 10.0 * pulse, Color(0.85, 0.42, 0.08))
		draw_circle(p + Vector2(0, 6), Vector2(6, 4).x, Color(0.70, 0.30, 0.06))
		draw_arc(p + Vector2(-3, -12), 3.0, PI, TAU, 8,
				 Color(1.0, 0.90, 0.60, 0.55 * pulse), 1.5)
		# Rayos del bombillo
		for j in 6:
			var a := float(j) / 6.0 * TAU + _t * 0.5
			var r1 := 14.0 * pulse
			var r2 := 20.0 * pulse
			draw_line(p + Vector2(cos(a) * r1, sin(a) * r1),
					  p + Vector2(cos(a) * r2, sin(a) * r2),
					  Color(0.95, 0.75, 0.20, 0.30 * pulse), 1.5)

	func _draw_led_installed(p: Vector2) -> void:
		# LED: luz más fría y eficiente (azul-blanco)
		var ga := 0.10 + 0.05 * sin(_t * 1.8)
		draw_circle(p, 22.0, Color(0.70, 0.88, 1.0, ga))
		draw_circle(p, 10.0, Color(0.60, 0.82, 1.0))
		draw_arc(p, 10.0, 0.0, TAU, 16, Color(0.80, 0.94, 1.0), 2.0)
		draw_circle(p + Vector2(-3, -8), 3.0, Color(1.0, 1.0, 1.0, 0.70))
		# Checkmark pequeño
		draw_line(p + Vector2(-6, 2), p + Vector2(-2, 6), Color(0.22, 0.90, 0.30), 2.5)
		draw_line(p + Vector2(-2, 6), p + Vector2(8, -6), Color(0.22, 0.90, 0.30), 2.5)

	func _draw_player() -> void:
		var p := player_pos
		# Sombra
		draw_arc(p + Vector2(0, 8), PLAYER_R * 0.9, 0.0, PI, 12,
				 Color(0.0, 0.0, 0.0, 0.30), 6.0)
		# Cuerpo del jugador (mini personaje top-down)
		draw_circle(p, PLAYER_R, Color(0.25, 0.65, 0.35))
		draw_arc(p, PLAYER_R, 0.0, TAU, 20, Color(0.35, 0.85, 0.45), 2.0)
		# Cabeza (círculo más pequeño arriba)
		draw_circle(p + Vector2(0, -PLAYER_R * 0.5), PLAYER_R * 0.55, Color(0.88, 0.72, 0.55))
		# Indicador de dirección
		draw_arc(p, PLAYER_R + 4.0, -PI * 0.3, PI * 0.3, 8,
				 Color(0.45, 0.95, 0.55, 0.55), 2.0)

# ── Inner class: subpanel de reemplazo de bombillo ───────────
class BulbStepVisual extends Node2D:
	var paso : int   = 0
	var _t   : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match paso:
			0: _draw_switch()
			1: _draw_remove_bulb()
			2: _draw_install_led()
			3: _draw_verify()

	func _draw_switch() -> void:
		# Panel eléctrico con interruptor
		draw_rect(Rect2(-40, -50, 80, 70), Color(0.20, 0.22, 0.28))
		draw_rect(Rect2(-40, -50, 80, 70), Color(0.35, 0.40, 0.52), false, 2.0)
		# Interruptor (apagado)
		draw_rect(Rect2(-12, -30, 24, 28), Color(0.12, 0.14, 0.20))
		draw_rect(Rect2(-8, -5, 16, 14), Color(0.75, 0.20, 0.15))
		# Texto apagado
		draw_circle(Vector2(0, -40), 8.0, Color(0.50, 0.15, 0.12))
		draw_arc(Vector2(0, 24), 16.0, 0.0, TAU, 20, Color(0.85, 0.20, 0.18, 0.6), 2.0)
		# Rayo peligro
		draw_line(Vector2(-5, -48), Vector2(5, -38), Color(0.95, 0.80, 0.10, 0.80), 2.5)
		draw_line(Vector2(5, -38), Vector2(-3, -30), Color(0.95, 0.80, 0.10, 0.80), 2.5)

	func _draw_remove_bulb() -> void:
		# Bombillo incandescente viejo siendo removido
		var rise := minf(_t * 30.0, 20.0)
		# Casquillo en techo
		draw_rect(Rect2(-8, -55, 16, 10), Color(0.40, 0.38, 0.35))
		# Bombillo bajando/subiendo
		draw_circle(Vector2(0, -30 + rise), 20.0, Color(0.80, 0.55, 0.15))
		draw_arc(Vector2(0, -30 + rise), 20.0, 0.0, TAU, 20,
				 Color(0.95, 0.72, 0.22), 2.0)
		draw_rect(Rect2(-7, -12 + rise, 14, 16), Color(0.65, 0.60, 0.55))
		draw_rect(Rect2(-7, 2 + rise, 14, 4), Color(0.50, 0.48, 0.44))
		# Filamento dañado (rayas)
		draw_arc(Vector2(-3, -30 + rise), 4.0, PI * 0.3, PI * 2.7, 8,
				 Color(0.90, 0.70, 0.20, 0.70), 1.5)
		# Flechas de "retirar"
		var arr_a := _t * 2.0
		draw_line(Vector2(-30, -20), Vector2(-30, -10 + rise), Color(0.75, 0.75, 0.75, 0.6), 1.5)
		draw_line(Vector2(-30, -10 + rise), Vector2(-24, -16 + rise), Color(0.75, 0.75, 0.75, 0.6), 1.5)
		draw_circle(Vector2(-30, -20), 3.0, Color(0.85, 0.30, 0.25, 0.5 + 0.4 * sin(arr_a)))

	func _draw_install_led() -> void:
		# LED moderno siendo instalado
		var puls := 1.0 + 0.08 * sin(_t * 3.0)
		# Casquillo en techo
		draw_rect(Rect2(-8, -55, 16, 10), Color(0.40, 0.38, 0.35))
		# Módulo LED (más plano que el incandescente)
		draw_rect(Rect2(-16, -48, 32, 10), Color(0.25, 0.30, 0.40))
		draw_rect(Rect2(-16, -38, 32, 8), Color(0.35, 0.40, 0.52))
		draw_rect(Rect2(-16, -48, 32, 18), Color(0.40, 0.50, 0.65), false, 1.5)
		# Luz LED (azul-blanco eficiente)
		var ga := 0.18 + 0.10 * sin(_t * 2.5)
		draw_circle(Vector2(0, -20), 28.0 * puls, Color(0.60, 0.85, 1.0, ga))
		draw_circle(Vector2(0, -20), 18.0, Color(0.70, 0.88, 1.0, 0.6))
		# Sensor de movimiento (círculo pequeño en lateral)
		draw_circle(Vector2(18, -44), 5.0, Color(0.10, 0.10, 0.15))
		draw_arc(Vector2(18, -44), 5.0, 0.0, TAU, 12, Color(0.55, 0.75, 0.95), 1.5)
		# Onda del sensor
		for r in [8.0, 14.0]:
			draw_arc(Vector2(18, -44), r, -PI * 0.6, PI * 0.6, 12,
					 Color(0.55, 0.78, 0.95, 0.35 + 0.15 * sin(_t * 2.0 + r)), 1.5)
		# Ahorro indicador
		draw_line(Vector2(-34, -8), Vector2(-34, 20), Color(0.22, 0.88, 0.30, 0.70), 2.0)
		draw_line(Vector2(-28, -2), Vector2(-34, -8), Color(0.22, 0.88, 0.30, 0.70), 2.0)
		draw_line(Vector2(-40, -2), Vector2(-34, -8), Color(0.22, 0.88, 0.30, 0.70), 2.0)

	func _draw_verify() -> void:
		# Verificación: checkmark grande + luz funcionando
		var gsize := 1.0 + 0.06 * sin(_t * 2.0)
		draw_circle(Vector2(0, 0), 36.0 * gsize, Color(0.15, 0.80, 0.25, 0.18))
		draw_arc(Vector2(0, 0), 36.0 * gsize, 0.0, TAU, 32,
				 Color(0.22, 0.90, 0.30, 0.45), 3.0)
		draw_line(Vector2(-18, 4), Vector2(-6, 16), Color(0.22, 0.92, 0.30), 5.0)
		draw_line(Vector2(-6, 16), Vector2(22, -16), Color(0.22, 0.92, 0.30), 5.0)
		# Estrellas
		for i in 8:
			var a := float(i) / 8.0 * TAU + _t * 0.8
			var r := 44.0 + sin(_t * 2.0 + i * 0.8) * 4.0
			draw_circle(Vector2(cos(a) * r, sin(a) * r),
						2.5, Color(0.35, 0.95, 0.40, 0.70))
		# Texto ahorro
		draw_arc(Vector2(0, 0), 28.0, PI * 0.2, PI * 1.8, 20,
				 Color(0.22, 0.88, 0.30, 0.30), 12.0)


# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("interior_bloque")
	_crear_ui()
	hide()


func iniciar(bloque_idx: int, zona_node: Area2D) -> void:
	_bloque_idx  = clampi(bloque_idx, 0, BLOQUES.size() - 1)
	_zona_ref    = zona_node
	var b : Dictionary = BLOQUES[_bloque_idx]
	_mision_id   = b["id"]
	_player_pos  = Vector2(ROOM_W * 0.5, ROOM_H - 40)
	_spots_done  = []
	for _i in (b["spots"] as Array).size():
		_spots_done.append(false)
	_spot_cercano = -1
	_pasos_done   = 0
	_sub_panel.visible = false
	_hint_e_lbl.visible = false

	# Inicializar mundo
	(_mundo_node as MundoInterior).spots      = b["spots"]
	(_mundo_node as MundoInterior).spots_done = _spots_done
	(_mundo_node as MundoInterior).tipo_bloque = _bloque_idx

	_titulo_lbl.text = "🏛️  " + (b["nombre"] as String)
	_actualizar_progress()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("interior_led",
			"⚡ Muévete con WASD y presiona [E] al acercarte a las luminarias naranjas.")


func _actualizar_progress() -> void:
	var total := (BLOQUES[_bloque_idx]["spots"] as Array).size()
	var hecho := 0
	for d in _spots_done:
		if d: hecho += 1
	_progress_lbl.text = "Luminarias reemplazadas: %d / %d" % [hecho, total]


# ── Proceso y movimiento ──────────────────────────────────────
func _process(delta: float) -> void:
	if not visible: return
	if _sub_panel.visible: return   # sin movimiento mientras hay subdiálogo
	_t += delta
	_mover_jugador(delta)
	_verificar_spot_cercano()
	(_mundo_node as MundoInterior).player_pos  = _player_pos
	(_mundo_node as MundoInterior).spot_cerc   = _spot_cercano


func _mover_jugador(delta: float) -> void:
	var vel := Vector2.ZERO
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W): vel.y -= 1
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S): vel.y += 1
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A): vel.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): vel.x += 1
	if vel.length_squared() > 0:
		vel = vel.normalized() * PLAYER_SPEED
	_player_pos += vel * delta
	# Limitar a los bordes del cuarto
	_player_pos.x = clampf(_player_pos.x, PLAYER_R + 4, ROOM_W - PLAYER_R - 4)
	_player_pos.y = clampf(_player_pos.y, PLAYER_R + 20, ROOM_H - PLAYER_R - 4)


func _verificar_spot_cercano() -> void:
	var b : Dictionary = BLOQUES[_bloque_idx]
	var spots : Array = b["spots"]
	_spot_cercano = -1
	var min_dist  := INTERACT_R
	for i in spots.size():
		if _spots_done[i]: continue
		var sp_pos : Vector2 = (spots[i] as Dictionary)["pos"]
		var dist := _player_pos.distance_to(sp_pos)
		if dist < min_dist:
			min_dist      = dist
			_spot_cercano = i
	_hint_e_lbl.visible = (_spot_cercano >= 0)
	if _spot_cercano >= 0:
		var sp_nombre : String = (spots[_spot_cercano] as Dictionary)["nombre"]
		_hint_e_lbl.text = "⚡ [E]  Reemplazar luminaria — %s" % sp_nombre


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if _sub_panel.visible:
		if event.is_action_pressed("interactuar"):
			get_viewport().set_input_as_handled()
			_avanzar_paso()
		return
	if event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		if _spot_cercano >= 0:
			_iniciar_subpanel(_spot_cercano)
		else:
			# E sin spot → preguntar si salir
			pass
	if event is InputEventKey and (event as InputEventKey).pressed:
		var ke := event as InputEventKey
		if ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_salir()


# ── Subpanel: proceso de reemplazo ───────────────────────────
func _iniciar_subpanel(spot_idx: int) -> void:
	_pasos_done = spot_idx   # guardamos el índice del spot
	_paso_actual = 0
	_mostrar_paso()
	_sub_panel.modulate.a = 0.0
	_sub_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_sub_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_sub_panel, "scale",
		Vector2(1.0, 1.0), 0.22).from(Vector2(0.88, 0.88))


func _mostrar_paso() -> void:
	var p : Dictionary = PASOS_LED[_paso_actual]
	_sub_paso_lbl.text = "%s  %s" % [p["icono"], p["titulo"]]
	_sub_paso_lbl.add_theme_color_override("font_color", p["color"])
	_sub_desc_lbl.text = p["desc"]
	(_sub_visual as BulbStepVisual).paso = _paso_actual
	var es_ultimo := (_paso_actual == PASOS_LED.size() - 1)
	_sub_btn.text = "  ¡Listo!  ✅  " if es_ultimo else "  Continuar  ▶  "
	_sub_barra.text = "Paso %d de %d" % [_paso_actual + 1, PASOS_LED.size()]


func _avanzar_paso() -> void:
	_paso_actual += 1
	if _paso_actual >= PASOS_LED.size():
		_completar_spot(_pasos_done)
	else:
		_mostrar_paso()


func _completar_spot(spot_idx: int) -> void:
	_spots_done[spot_idx] = true
	(_mundo_node as MundoInterior).spots_done = _spots_done
	_actualizar_progress()
	_sub_panel.visible = false
	# Verificar si todos los spots están completos
	var todos_listos := true
	for d in _spots_done:
		if not d: todos_listos = false; break
	if todos_listos:
		_completar_mision()


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(2, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completado"):
		_zona_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(2, 50)) if nm else 50
	var ec : int = int(nm.EC_POR_MISION.get(2, 20)) if nm else 20
	mision_interior_completada.emit(_mision_id, xp, ec)
	# Mostrar celebración breve antes de cerrar
	var cel_panel := Panel.new()
	cel_panel.set_anchors_preset(Control.PRESET_CENTER)
	cel_panel.custom_minimum_size = Vector2(440, 180)
	cel_panel.offset_left  = -220.0; cel_panel.offset_top    = -90.0
	cel_panel.offset_right =  220.0; cel_panel.offset_bottom =  90.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.04, 0.10, 0.06, 0.98)
	cps.border_color = Color(0.22, 0.90, 0.28)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	cps.shadow_size  = 24
	cel_panel.add_theme_stylebox_override("panel", cps)
	add_child(cel_panel)
	var cel_lbl := Label.new()
	cel_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cel_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cel_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	cel_lbl.add_theme_font_size_override("font_size", 18)
	cel_lbl.add_theme_color_override("font_color", Color(0.30, 0.95, 0.35))
	cel_lbl.text = "⚡ ¡Misión completada!\n\nTodas las luminarias del %s\nfueron reemplazadas por LED inteligente.\n+%d XP  ·  +%d EcoCredits" % [
		(BLOQUES[_bloque_idx]["nombre"] as String), xp, ec
	]
	cel_panel.add_child(cel_lbl)
	cel_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cel_panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(cel_panel, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		cel_panel.queue_free()
		_on_salir())


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Panel principal
	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(900, 560)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -450.0
	_panel_root.offset_top    = -280.0
	_panel_root.offset_right  =  450.0
	_panel_root.offset_bottom =  280.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.08, 0.14, 0.98)
	ps.border_color = Color(0.95, 0.60, 0.10)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.50, 0.30, 0.05, 0.50)
	ps.shadow_size  = 24
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja naranja/energía en la parte superior
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.95, 0.58, 0.08, 0.85)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	# Botón salir
	_btn_salir = Button.new()
	_btn_salir.text = "✕ Salir"
	_btn_salir.custom_minimum_size = Vector2(80, 30)
	_btn_salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_salir.offset_left   = -92.0
	_btn_salir.offset_top    =  8.0
	_btn_salir.offset_right  = -8.0
	_btn_salir.offset_bottom =  38.0
	_btn_salir.add_theme_font_size_override("font_size", 11)
	var bss := StyleBoxFlat.new()
	bss.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bss.border_color = Color(0.65, 0.15, 0.15)
	bss.set_border_width_all(2)
	bss.set_corner_radius_all(8)
	_btn_salir.add_theme_stylebox_override("normal", bss)
	_btn_salir.add_theme_color_override("font_color", Color(0.92, 0.50, 0.50))
	_btn_salir.pressed.connect(_on_salir)
	_panel_root.add_child(_btn_salir)

	# Título
	_titulo_lbl = Label.new()
	_titulo_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_titulo_lbl.offset_left   = 14.0
	_titulo_lbl.offset_top    = 10.0
	_titulo_lbl.offset_right  = 760.0
	_titulo_lbl.offset_bottom = 42.0
	_titulo_lbl.add_theme_font_size_override("font_size", 17)
	_titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.65))
	_panel_root.add_child(_titulo_lbl)

	# Badge nivel
	var badge := Label.new()
	badge.text = "⚡ NIVEL 2"
	badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	badge.offset_left   = 14.0
	badge.offset_top    = 42.0
	badge.offset_right  = 200.0
	badge.offset_bottom = 60.0
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.95, 0.65, 0.20))
	_panel_root.add_child(badge)

	# Progreso
	_progress_lbl = Label.new()
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_progress_lbl.offset_left   = -380.0
	_progress_lbl.offset_top    = 42.0
	_progress_lbl.offset_right  = -96.0
	_progress_lbl.offset_bottom = 60.0
	_progress_lbl.add_theme_font_size_override("font_size", 11)
	_progress_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	_panel_root.add_child(_progress_lbl)

	# Zona de mundo: Control con clip
	var mundo_cont := Control.new()
	mundo_cont.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mundo_cont.offset_left   = float(ROOM_X - 2)
	mundo_cont.offset_top    = float(ROOM_Y - 2)
	mundo_cont.offset_right  = float(ROOM_X + ROOM_W + 2)
	mundo_cont.offset_bottom = float(ROOM_Y + ROOM_H + 2)
	mundo_cont.clip_contents = true
	_panel_root.add_child(mundo_cont)

	_mundo_node = MundoInterior.new()
	_mundo_node.position = Vector2(0, 0)
	mundo_cont.add_child(_mundo_node)

	# Borde del mundo
	var world_border := ColorRect.new()
	world_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_border.color        = Color(0.22, 0.40, 0.65, 0)
	world_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mundo_cont.add_child(world_border)

	# Hint de la tecla E
	_hint_e_lbl = Label.new()
	_hint_e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_e_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint_e_lbl.offset_left   =  14.0
	_hint_e_lbl.offset_top    = -52.0
	_hint_e_lbl.offset_right  = 860.0
	_hint_e_lbl.offset_bottom = -28.0
	_hint_e_lbl.visible = false
	_hint_e_lbl.add_theme_font_size_override("font_size", 14)
	_hint_e_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	_panel_root.add_child(_hint_e_lbl)

	# Instrucciones WASD
	var wasd_lbl := Label.new()
	wasd_lbl.text = "WASD — Moverse   |   [E] — Interactuar"
	wasd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wasd_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wasd_lbl.offset_left   = 14.0
	wasd_lbl.offset_top    = -24.0
	wasd_lbl.offset_right  = 860.0
	wasd_lbl.offset_bottom = -6.0
	wasd_lbl.add_theme_font_size_override("font_size", 10)
	wasd_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	_panel_root.add_child(wasd_lbl)

	# ── Subpanel de reemplazo ─────────────────────────────────
	_sub_panel = Panel.new()
	_sub_panel.set_anchors_preset(Control.PRESET_CENTER)
	_sub_panel.custom_minimum_size = Vector2(600, 340)
	_sub_panel.offset_left   = -300.0
	_sub_panel.offset_top    = -170.0
	_sub_panel.offset_right  =  300.0
	_sub_panel.offset_bottom =  170.0
	_sub_panel.visible = false
	var sps := StyleBoxFlat.new()
	sps.bg_color     = Color(0.04, 0.06, 0.12, 0.99)
	sps.border_color = Color(0.95, 0.62, 0.10)
	sps.set_border_width_all(3)
	sps.set_corner_radius_all(16)
	sps.shadow_color = Color(0.50, 0.30, 0.05, 0.60)
	sps.shadow_size  = 24
	_sub_panel.add_theme_stylebox_override("panel", sps)
	add_child(_sub_panel)

	var smg := MarginContainer.new()
	smg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		smg.add_theme_constant_override(k, 22)
	_sub_panel.add_child(smg)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 12)
	smg.add_child(svbox)

	# Barra de pasos
	_sub_barra = Label.new()
	_sub_barra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_barra.add_theme_font_size_override("font_size", 11)
	_sub_barra.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	svbox.add_child(_sub_barra)

	# Título del paso
	_sub_paso_lbl = Label.new()
	_sub_paso_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_paso_lbl.add_theme_font_size_override("font_size", 17)
	svbox.add_child(_sub_paso_lbl)

	# Visual del paso
	var vis_cont := Control.new()
	vis_cont.custom_minimum_size   = Vector2(0, 120)
	vis_cont.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vis_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svbox.add_child(vis_cont)

	_sub_visual = BulbStepVisual.new()
	_sub_visual.position = Vector2(300, 60)
	vis_cont.add_child(_sub_visual)

	# Descripción del paso
	_sub_desc_lbl = Label.new()
	_sub_desc_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_sub_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_desc_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	_sub_desc_lbl.add_theme_font_size_override("font_size", 13)
	_sub_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.82))
	svbox.add_child(_sub_desc_lbl)

	# Botón continuar
	_sub_btn = Button.new()
	_sub_btn.custom_minimum_size = Vector2(200, 44)
	_sub_btn.add_theme_font_size_override("font_size", 14)
	var sbns := StyleBoxFlat.new()
	sbns.bg_color     = Color(0.08, 0.28, 0.10)
	sbns.border_color = Color(0.22, 0.85, 0.28)
	sbns.set_border_width_all(2)
	sbns.set_corner_radius_all(12)
	_sub_btn.add_theme_stylebox_override("normal", sbns)
	_sub_btn.pressed.connect(_avanzar_paso)
	svbox.add_child(_sub_btn)
