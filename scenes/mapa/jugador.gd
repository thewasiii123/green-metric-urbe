extends CharacterBody2D

const VELOCIDAD : float = 150.0

func _ready() -> void:
	print("✅ Jugador listo")

func _physics_process(_delta: float) -> void:
	var direccion : Vector2 = Vector2.ZERO
	
	# Corregido: sin inversión
	if Input.is_action_pressed("ui_right"):
		direccion.x = 1
	if Input.is_action_pressed("ui_left"):
		direccion.x = -1
	if Input.is_action_pressed("ui_down"):
		direccion.y = 1
	if Input.is_action_pressed("ui_up"):
		direccion.y = -1
	
	if direccion.length() > 0:
		direccion = direccion.normalized()
	
	velocity = direccion * VELOCIDAD
	move_and_slide()
