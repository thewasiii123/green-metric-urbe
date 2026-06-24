# ============================================================
# jugador.gd — URBE Rangers: Eco-Quest
# Controla el Eco-Ranger con movimiento en 4 direcciones
# y animaciones por dirección usando AnimatedSprite2D.
# Spritesheet: 96x192 px | Frame: 32x48 px | 3 cols x 4 filas
# ============================================================
extends CharacterBody2D

# ── Constantes ───────────────────────────────────────────────
const VELOCIDAD     : float  = 120.0
const GRUPO_JUGADOR : String = "jugador"

# ── Nodos ────────────────────────────────────────────────────
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

# ── Estado ───────────────────────────────────────────────────
var _moviéndose    : bool   = false
var _dir_actual    : String = "abajo"


func _ready() -> void:
	add_to_group(GRUPO_JUGADOR)
	print("✅ Eco-Ranger listo en: " + str(global_position))

	# Si el sprite ya fue configurado en el editor, reproducir idle
	if sprite:
		sprite.play("idle_abajo")


func _physics_process(_delta: float) -> void:
	var dir := _leer_input()

	if dir.length() > 0:
		dir            = dir.normalized()
		_moviéndose    = true
		_dir_actual    = _calcular_direccion(dir)
		velocity       = dir * VELOCIDAD
		_animar("walk_" + _dir_actual)
	else:
		_moviéndose = false
		velocity    = Vector2.ZERO
		_animar("idle_" + _dir_actual)

	move_and_slide()


func _leer_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x =  1.0
	if Input.is_action_pressed("ui_left"):  dir.x = -1.0
	if Input.is_action_pressed("ui_down"):  dir.y =  1.0
	if Input.is_action_pressed("ui_up"):    dir.y = -1.0
	return dir


func _calcular_direccion(dir: Vector2) -> String:
	# Prioriza el eje con mayor magnitud
	if abs(dir.x) >= abs(dir.y):
		return "derecha" if dir.x > 0 else "izquierda"
	else:
		return "abajo"   if dir.y > 0 else "arriba"


func _animar(nombre: String) -> void:
	if sprite and sprite.animation != nombre:
		sprite.play(nombre)
