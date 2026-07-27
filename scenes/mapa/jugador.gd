# ============================================================
# jugador.gd — URBE Rangers: Eco-Quest
# ============================================================
extends CharacterBody2D

const VELOCIDAD     : float  = 120.0
const GRUPO_JUGADOR : String = "jugador"
const TRAIL_MAX     : int    = 10
const TRAIL_DELTA   : float  = 0.055

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var _moviéndose    : bool          = false
var _dir_actual    : String        = "abajo"
var npc_cercano    : Node          = null
var _trail         : Array[Vector2] = []
var _trail_timer   : float         = 0.0

# Señal para que el mapa pueda reaccionar (zoom, efectos)
signal interaccion_iniciada()


func _ready() -> void:
	add_to_group(GRUPO_JUGADOR)
	if sprite:
		sprite.play("idle_abajo")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2(1.5, 1.5)


func _physics_process(delta: float) -> void:
	var dlg          = get_tree().get_first_node_in_group("ui_dialogo")
	var quiz         = get_tree().get_first_node_in_group("ui_quiz")
	var mision_ui    = get_tree().get_first_node_in_group("ui_mision_inicio")
	var minijuego_ui = get_tree().get_first_node_in_group("ui_minijuego")
	var tutorial_ui  = get_tree().get_first_node_in_group("ui_tutorial")
	var crisis_ui    = get_tree().get_first_node_in_group("ui_crisis")

	if (dlg and dlg.visible) or (quiz and quiz.visible) \
			or (mision_ui and mision_ui.visible) \
			or (minijuego_ui and minijuego_ui.visible) \
			or (tutorial_ui and tutorial_ui.visible) \
			or (crisis_ui and crisis_ui.visible):
		velocity = Vector2.ZERO
		_animar("idle_" + _dir_actual)
		move_and_slide()
		# Trail se disuelve al parar
		if not _trail.is_empty():
			_trail.pop_front()
			queue_redraw()
		return

	# Botón interactuar táctil
	var touch_nodo = get_tree().get_first_node_in_group("touch_controls")
	if touch_nodo and touch_nodo.visible and touch_nodo.interact_fired:
		touch_nodo.interact_fired = false
		if npc_cercano != null:
			interaccion_iniciada.emit()
			npc_cercano.iniciar_dialogo()

	var dir := _leer_input()
	if dir.length() > 0:
		dir         = dir.normalized()
		_moviéndose = true
		_dir_actual = _calcular_direccion(dir)
		velocity    = dir * VELOCIDAD
		_animar("walk_" + _dir_actual)

		# Trail de pasos
		_trail_timer += delta
		if _trail_timer >= TRAIL_DELTA:
			_trail_timer = 0.0
			_trail.append(global_position)
			if _trail.size() > TRAIL_MAX:
				_trail.pop_front()
			queue_redraw()
	else:
		_moviéndose = false
		velocity    = Vector2.ZERO
		_animar("idle_" + _dir_actual)
		# Trail se disuelve gradualmente
		if not _trail.is_empty():
			_trail.pop_front()
			queue_redraw()

	move_and_slide()


func _draw() -> void:
	# Sombra elíptica bajo el personaje
	draw_arc(Vector2(0, 10), 11.0, 0.0, PI, 14, Color(0, 0, 0, 0.22), 8.0)

	if _trail.is_empty(): return
	var n : int = _trail.size()
	for i in n:
		var local_p : Vector2 = to_local(_trail[i])
		var t       : float   = float(i + 1) / float(n)
		var alpha   : float   = t * 0.30
		var r       : float   = 2.5 + t * 2.0
		draw_circle(local_p, r, Color(0.30, 0.92, 0.42, alpha))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar"):
		return

	var mision_ui    = get_tree().get_first_node_in_group("ui_mision_inicio")
	var dlg          = get_tree().get_first_node_in_group("ui_dialogo")
	var quiz         = get_tree().get_first_node_in_group("ui_quiz")
	var minijuego_ui = get_tree().get_first_node_in_group("ui_minijuego")
	var tutorial_ui2 = get_tree().get_first_node_in_group("ui_tutorial")
	var crisis_ui2   = get_tree().get_first_node_in_group("ui_crisis")
	if (mision_ui and mision_ui.visible) or (dlg and dlg.visible) \
			or (quiz and quiz.visible) or (minijuego_ui and minijuego_ui.visible) \
			or (crisis_ui2 and crisis_ui2.visible):
		return
	# Tutorial maneja [E] internamente, no lo consumimos aquí
	if tutorial_ui2 and tutorial_ui2.visible:
		return

	if npc_cercano != null:
		interaccion_iniciada.emit()
		npc_cercano.iniciar_dialogo()


func _leer_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("mover_derecha"):   dir.x =  1.0
	if Input.is_action_pressed("mover_izquierda"): dir.x = -1.0
	if Input.is_action_pressed("mover_abajo"):     dir.y =  1.0
	if Input.is_action_pressed("mover_arriba"):    dir.y = -1.0

	# Joystick táctil (móvil): sobreescribe solo si hay input táctil
	var touch = get_tree().get_first_node_in_group("touch_controls")
	if touch and touch.visible and touch.joy_dir.length() > 0.0:
		dir = touch.joy_dir

	return dir


func _calcular_direccion(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "derecha" if dir.x > 0 else "izquierda"
	else:
		return "abajo" if dir.y > 0 else "arriba"


func _animar(nombre: String) -> void:
	if sprite and sprite.animation != nombre:
		sprite.play(nombre)
