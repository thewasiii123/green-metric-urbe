# ============================================================
# SupabaseManager.gd — Singleton Global
# Maneja TODAS las peticiones HTTP hacia Supabase.
# Se registra como AutoLoad para estar disponible en
# cualquier escena sin necesidad de importarlo.
# ============================================================
extends Node

# --- TUS CREDENCIALES DE SUPABASE (Settings → API) ---
const SUPABASE_URL     : String = "https://ikohikbpvtbvsgyumvbr.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_I7BlsHi98fLy-Yuq8NTtFQ_8tw6r44k"

# --- SEÑALES: otros nodos escuchan estas para recibir respuestas ---
signal login_exitoso(datos: Dictionary)
signal login_fallido(error: String)
signal registro_exitoso(datos: Dictionary)
signal modulos_cargados(lista: Array)
signal progreso_cargado(lista: Array)
signal progreso_guardado()
signal error_red(mensaje: String)

# --- ESTADO INTERNO ---
var jwt_token     : String = ""  # Token JWT del estudiante autenticado
var user_id       : String = ""  # UID del estudiante (= auth.uid() en Supabase)
var _http         : HTTPRequest  # Nodo reutilizable para peticiones HTTP
var _accion_actual: String = ""  # Identifica qué petición está en vuelo


func _ready() -> void:
	# Crear el HTTPRequest como hijo de este nodo.
	# En HTML5 solo funciona UNA petición a la vez, por eso usamos un solo nodo.
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_respuesta_http)


# ============================================================
# LOGIN: Autenticar estudiante con email y contraseña
# ============================================================
func login(email: String, contrasena: String) -> void:
	_accion_actual = "login"
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	])
	var cuerpo = JSON.stringify({"email": email, "password": contrasena})
	_http.request(url, headers, HTTPClient.METHOD_POST, cuerpo)


# ============================================================
# REGISTRO: Crear cuenta nueva de estudiante
# ============================================================
func registrar(email: String, contrasena: String, nombre: String) -> void:
	_accion_actual = "registro"
	var url = SUPABASE_URL + "/auth/v1/signup"
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	])
	var cuerpo = JSON.stringify({
		"email"   : email,
		"password": contrasena,
		"data"    : {"nombre": nombre}
	})
	_http.request(url, headers, HTTPClient.METHOD_POST, cuerpo)


# ============================================================
# CARGAR MÓDULOS: Obtiene los 6 módulos GreenMetric
# No requiere JWT (política RLS: lectura pública)
# ============================================================
func cargar_modulos() -> void:
	_accion_actual = "cargar_modulos"
	var url = SUPABASE_URL + "/rest/v1/modulos_greenmetric?order=orden_desbloqueo.asc&activo=eq.true"
	var headers = PackedStringArray([
		"apikey: "         + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + SUPABASE_ANON_KEY
	])
	_http.request(url, headers, HTTPClient.METHOD_GET)


# ============================================================
# CARGAR PROGRESO: Obtiene el avance del estudiante autenticado
# RLS filtra automáticamente por auth.uid() usando el JWT
# ============================================================
func cargar_progreso() -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	_accion_actual = "cargar_progreso"
	var url = SUPABASE_URL + "/rest/v1/progreso_estudiante?select=*"
	_http.request(url, _headers_auth(), HTTPClient.METHOD_GET)


# ============================================================
# GUARDAR PROGRESO: Inserta o actualiza el avance en un módulo
# Usa UPSERT para no duplicar (UNIQUE user_id + modulo_id)
# ============================================================
func guardar_progreso(modulo_id: int, puntaje: int, xp: int, completado: bool) -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	_accion_actual = "guardar_progreso"
	var url = SUPABASE_URL + "/rest/v1/progreso_estudiante"
	var cuerpo = JSON.stringify({
		"user_id"         : user_id,   # coincide con columna user_id en la tabla
		"modulo_id"       : modulo_id, # coincide con columna modulo_id
		"puntaje_obtenido": puntaje,   # coincide con columna puntaje_obtenido
		"xp_ganada"       : xp,        # coincide con columna xp_ganada
		"completado"      : completado  # coincide con columna completado
	})
	var headers = _headers_auth()
	headers.append("Prefer: resolution=merge-duplicates")
	_http.request(url, headers, HTTPClient.METHOD_POST, cuerpo)


# ============================================================
# MANEJADOR CENTRAL: Todas las respuestas HTTP llegan aquí
# ============================================================
func _on_respuesta_http(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("error_red", "Sin conexión. Código: " + str(result))
		return

	var texto  = body.get_string_from_utf8()
	var datos  = JSON.parse_string(texto)

	match _accion_actual:
		"login"          : _procesar_login(code, datos)
		"registro"       : _procesar_registro(code, datos)
		"cargar_modulos" : _procesar_modulos(code, datos)
		"cargar_progreso": _procesar_progreso(code, datos)
		"guardar_progreso": _procesar_guardar(code)

	_accion_actual = ""


func _procesar_login(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary:
		jwt_token = datos.get("access_token", "")
		user_id   = datos.get("user", {}).get("id", "")
		emit_signal("login_exitoso", datos.get("user", {}))
	else:
		var msg = datos.get("error_description", "Credenciales incorrectas.") if datos is Dictionary else "Error desconocido."
		emit_signal("login_fallido", msg)


func _procesar_registro(code: int, datos: Variant) -> void:
	if code in [200, 201] and datos is Dictionary:
		jwt_token = datos.get("access_token", "")
		user_id   = datos.get("user", {}).get("id", "")
		emit_signal("registro_exitoso", datos.get("user", {}))
	else:
		emit_signal("login_fallido", "Error al registrarse.")


func _procesar_modulos(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("modulos_cargados", datos)
	else:
		emit_signal("error_red", "No se pudieron cargar los módulos.")


func _procesar_progreso(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		emit_signal("progreso_cargado", datos)
	else:
		emit_signal("error_red", "No se pudo cargar el progreso.")


func _procesar_guardar(code: int) -> void:
	if code in [200, 201]:
		emit_signal("progreso_guardado")
	else:
		emit_signal("error_red", "No se pudo guardar el progreso.")


# Genera los headers con el JWT del estudiante autenticado
func _headers_auth() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: "         + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + jwt_token,
		"Prefer: return=representation"
	])
