extends Control

@onready var email_input   : LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var boton_login   : Button   = %BotonLogin
@onready var boton_registro: Button   = %BotonRegistro
@onready var mensaje_label : Label    = %MensajeLabel


func _ready() -> void:
	print("✅ SceneLogin lista")
	
	# Conectar señales de Supabase
	SupabaseManager.login_exitoso.connect(_en_login_exitoso)
	SupabaseManager.login_fallido.connect(_en_login_fallido)
	SupabaseManager.error_red.connect(_en_error_red)
	
	# Limpiar mensaje inicial
	mensaje_label.text = ""
	
	# Conectar botones
	boton_login.pressed.connect(_on_boton_login_pressed)
	boton_registro.pressed.connect(_on_boton_registro_pressed)


func _on_boton_login_pressed() -> void:
	print("🔘 Botón login presionado")
	
	var email    : String = email_input.text.strip_edges()
	var password : String = password_input.text
	
	if email.is_empty() or password.is_empty():
		_mostrar_mensaje("⚠ Completa todos los campos.", Color.YELLOW)
		return
	
	if not email.contains("@"):
		_mostrar_mensaje("⚠ El correo no es válido.", Color.YELLOW)
		return
	
	_set_cargando(true)
	_mostrar_mensaje("Conectando...", Color.WHITE)
	print("📡 Enviando login: " + email)
	
	SupabaseManager.login(email, password)


func _on_boton_registro_pressed() -> void:
	_mostrar_mensaje("Registro próximamente.", Color.CYAN)


func _en_login_exitoso(_datos: Dictionary) -> void:
	print("✅ Login exitoso - UID: " + SupabaseManager.user_id)
	_set_cargando(false)
	_mostrar_mensaje("✓ Bienvenido al campus.", Color.GREEN)
	await get_tree().create_timer(1.0).timeout
	# Siguiente escena — la activamos cuando tengamos el mapa listo
	get_tree().change_scene_to_file("res://scenes/mapa/scene_mapa_mundo.tscn")


func _en_login_fallido(error: String) -> void:
	print("❌ Login fallido: " + error)
	_set_cargando(false)
	_mostrar_mensaje("✗ " + error, Color.RED)


func _en_error_red(mensaje: String) -> void:
	print("🌐 Error de red: " + mensaje)
	_set_cargando(false)
	_mostrar_mensaje("✗ Sin conexión.", Color.RED)


func _mostrar_mensaje(texto: String, color: Color) -> void:
	mensaje_label.text     = texto
	mensaje_label.modulate = color


func _set_cargando(estado: bool) -> void:
	boton_login.disabled    = estado
	boton_registro.disabled = estado
