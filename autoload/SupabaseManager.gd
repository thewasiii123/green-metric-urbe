# ============================================================
# SupabaseManager.gd — Singleton Global
# Maneja TODAS las peticiones HTTP hacia Supabase.
# ============================================================
extends Node

const SUPABASE_URL     : String = "https://ikohikbpvtbvsgyumvbr.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_I7BlsHi98fLy-Yuq8NTtFQ_8tw6r44k"

# ── Señales ──────────────────────────────────────────────────
signal login_exitoso(datos: Dictionary)
signal login_fallido(error: String)
signal registro_exitoso(datos: Dictionary)
signal registro_fallido(error: String)
signal recuperacion_enviada()
signal recuperacion_fallida(error: String)
signal modulos_cargados(lista: Array)
signal progreso_cargado(lista: Array)
signal progreso_guardado()
signal ranking_cargado(lista: Array)
signal error_red(mensaje: String)

# ── Estado interno ───────────────────────────────────────────
var jwt_token      : String = ""
var user_id        : String = ""
var nombre_usuario : String = ""
var _http          : HTTPRequest
var _accion_actual : String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_respuesta_http)


# ── LOGIN ─────────────────────────────────────────────────────
func login(email: String, contrasena: String) -> void:
	_accion_actual = "login"
	var url  = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({"email": email, "password": contrasena})
	_http.request(url, _headers_anon(), HTTPClient.METHOD_POST, body)


# ── REGISTRO ─────────────────────────────────────────────────
func registrar(email: String, contrasena: String, meta: Dictionary) -> void:
	_accion_actual = "registro"
	var url  = SUPABASE_URL + "/auth/v1/signup"
	var body = JSON.stringify({
		"email"   : email,
		"password": contrasena,
		"data"    : meta          # nombre, cedula, carrera, semestre
	})
	_http.request(url, _headers_anon(), HTTPClient.METHOD_POST, body)


# ── RECUPERAR CONTRASEÑA (envía email de reset) ───────────────
func recuperar_contrasena(email: String) -> void:
	_accion_actual = "recuperar"
	var url  = SUPABASE_URL + "/auth/v1/recover"
	var body = JSON.stringify({"email": email})
	_http.request(url, _headers_anon(), HTTPClient.METHOD_POST, body)


# ── MÓDULOS ───────────────────────────────────────────────────
func cargar_modulos() -> void:
	_accion_actual = "cargar_modulos"
	var url = SUPABASE_URL + "/rest/v1/modulos_greenmetric?order=orden_desbloqueo.asc&activo=eq.true"
	_http.request(url, _headers_anon(), HTTPClient.METHOD_GET)


# ── PROGRESO ─────────────────────────────────────────────────
func cargar_progreso() -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	_accion_actual = "cargar_progreso"
	var url = SUPABASE_URL + "/rest/v1/progreso_estudiante?select=*"
	_http.request(url, _headers_auth(), HTTPClient.METHOD_GET)


func cargar_ranking() -> void:
	_accion_actual = "cargar_ranking"
	var url : String = SUPABASE_URL + "/rest/v1/progreso_estudiante?select=user_id,xp_ganada,completado&order=xp_ganada.desc"
	_http.request(url, _headers_anon(), HTTPClient.METHOD_GET)


func guardar_progreso(modulo_id: int, puntaje: int, xp: int, completado: bool) -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	_accion_actual = "guardar_progreso"
	var url  = SUPABASE_URL + "/rest/v1/progreso_estudiante"
	var body = JSON.stringify({
		"user_id"          : user_id,
		"modulo_id"        : modulo_id,
		"puntaje_obtenido" : puntaje,
		"xp_ganada"        : xp,
		"completado"       : completado
	})
	var hdrs := _headers_auth()
	hdrs.append("Prefer: resolution=merge-duplicates")
	_http.request(url, hdrs, HTTPClient.METHOD_POST, body)


# ── MANEJADOR CENTRAL ─────────────────────────────────────────
func _on_respuesta_http(result: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("error_red", "Sin conexión. Código: " + str(result))
		_accion_actual = ""
		return

	var texto := body.get_string_from_utf8()
	var datos  = JSON.parse_string(texto)

	match _accion_actual:
		"login"          : _procesar_login(code, datos)
		"registro"       : _procesar_registro(code, datos)
		"recuperar"      : _procesar_recuperar(code, datos)
		"cargar_modulos"  : _procesar_modulos(code, datos)
		"cargar_progreso" : _procesar_progreso(code, datos)
		"guardar_progreso": _procesar_guardar(code)
		"cargar_ranking"  : _procesar_ranking(code, datos)

	_accion_actual = ""


func _procesar_login(code: int, datos: Variant) -> void:
	if code == 200 and datos is Dictionary and datos.has("access_token"):
		jwt_token = datos.get("access_token", "")
		var user : Dictionary = datos.get("user", {})
		user_id        = user.get("id", "")
		var meta : Dictionary = user.get("user_metadata", {})
		nombre_usuario = str(meta.get("nombre", meta.get("name", user.get("email", "Eco-Ranger"))))
		emit_signal("login_exitoso", user)
	else:
		var msg : String = "Credenciales incorrectas."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", msg))
		emit_signal("login_fallido", msg)


func _procesar_registro(code: int, datos: Variant) -> void:
	if code in [200, 201] and datos is Dictionary and datos.has("user"):
		var usuario = datos.get("user", {})
		user_id   = usuario.get("id", "")
		jwt_token = datos.get("access_token", "")   # vacío si requiere confirmar email
		emit_signal("registro_exitoso", usuario)
	else:
		var msg : String = "No se pudo crear la cuenta."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", datos.get("message", msg)))
		emit_signal("registro_fallido", msg)


func _procesar_recuperar(code: int, datos: Variant) -> void:
	# Supabase devuelve 200 con body vacío {} al enviar el correo correctamente
	if code == 200:
		emit_signal("recuperacion_enviada")
	else:
		var msg : String = "No se pudo enviar el correo."
		if datos is Dictionary:
			msg = datos.get("error_description", datos.get("msg", msg))
		emit_signal("recuperacion_fallida", msg)


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


func _procesar_ranking(code: int, datos: Variant) -> void:
	if code == 200 and datos is Array:
		# Agrupa xp por user_id del lado del cliente
		var totales : Dictionary = {}
		for fila in datos:
			if fila is not Dictionary: continue
			var uid : String = str(fila.get("user_id", ""))
			var xp  : int    = int(fila.get("xp_ganada", 0))
			totales[uid] = int(totales.get(uid, 0)) + xp
		# Convierte a array ordenado
		var lista : Array = []
		for uid in totales.keys():
			lista.append({"user_id": uid, "xp_total": totales[uid],
						  "nombre": uid.left(8) + "…"})
		lista.sort_custom(func(a, b): return int(a["xp_total"]) > int(b["xp_total"]))
		emit_signal("ranking_cargado", lista)
	else:
		emit_signal("error_red", "No se pudo cargar el ranking.")


# ── Headers ───────────────────────────────────────────────────
func _headers_anon() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	])

func _headers_auth() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json",
		"apikey: "               + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + jwt_token,
		"Prefer: return=representation"
	])
