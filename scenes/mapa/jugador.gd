# ============================================================
# jugador.gd - URBE Rangers: Eco-Quest
# Controla el Eco-Ranger con movimiento WASD en 4 direcciones
# y animaciones por direccion usando AnimatedSprite2D.
# Spritesheet: 96x192 px | Frame: 32x48 px | 3 cols x 4 filas
# ============================================================
extends CharacterBody2D

const VELOCIDAD     : float  = 120.0
const GRUPO_JUGADOR : String = "jugador"

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var _moviendose  : bool   = false
var _dir_actual  : String = "abajo"
var npc_cercano           = null


func _ready() -> void:
	add_to_group(GRUPO_JUGADOR)
	if sprite:
		sprite.play("idle_abajo")


func _physics_process(_delta: float) -> void:
	var dir := _leer_input()

	if dir.length() > 0:
		dir           = dir.normalized()
		_moviendose   = true
		_dir_actual   = _calcular_direccion(dir)
		velocity      = dir * VELOCIDAD
		_animar("walk_" + _dir_actual)
	else:
		_moviendose = false
		velocity    = Vector2.ZERO
		_animar("idle_" + _dir_actual)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar"):
		return
	if npc_cercano == null:
		return
	# Si el dialogo ya esta abierto, la UI maneja el E para avanzar/cerrar
	var ui = get_tree().get_first_node_in_group("ui_dialogo")
	if ui and ui.visible:
		return
	npc_cercano.iniciar_dialogo()


func _leer_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("mover_derecha"):   dir.x =  1.0
	if Input.is_action_pressed("mover_izquierda"): dir.x = -1.0
	if Input.is_action_pressed("mover_abajo"):     dir.y =  1.0
	if Input.is_action_pressed("mover_arriba"):    dir.y = -1.0
	return dir


func _calcular_direccion(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "derecha" if dir.x > 0 else "izquierda"
	else:
		return "abajo"   if dir.y > 0 else "arriba"


func _animar(nombre: String) -> void:
	if sprite and sprite.animation != nombre:
		sprite.play(nombre)