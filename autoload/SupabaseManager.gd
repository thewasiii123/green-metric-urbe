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
var _cola          : Array  = []   # Array[Dictionary] peticiones en espera
var _ocupado       : bool   = false


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_respuesta_http)


func _encolar(accion: String, url: String, metodo: int,
			  hdrs: PackedStringArray, body: String = "") -> void:
	_cola.append({"accion": accion, "url": url, "metodo": metodo,
				  "hdrs": hdrs, "body": body})
	_despachar()


func _despachar() -> void:
	if _ocupado or _cola.is_empty():
		return
	_ocupado = true
	var p : Dictionary = _cola.pop_front()
	_accion_actual = p["accion"]
	_http.request(p["url"], p["hdrs"], p["metodo"], p["body"])


# ── LOGIN ─────────────────────────────────────────────────────
func login(email: String, contrasena: String) -> void:
	var url  := SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body := JSON.stringify({"email": email, "password": contrasena})
	_encolar("login", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# ── REGISTRO ─────────────────────────────────────────────────
func registrar(email: String, contrasena: String, meta: Dictionary) -> void:
	var url  := SUPABASE_URL + "/auth/v1/signup"
	var body := JSON.stringify({
		"email"   : email,
		"password": contrasena,
		"data"    : meta
	})
	_encolar("registro", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# ── RECUPERAR CONTRASEÑA ──────────────────────────────────────
func recuperar_contrasena(email: String) -> void:
	var url  := SUPABASE_URL + "/auth/v1/recover"
	var body := JSON.stringify({"email": email})
	_encolar("recuperar", url, HTTPClient.METHOD_POST, _headers_anon(), body)


# ── MÓDULOS ───────────────────────────────────────────────────
func cargar_modulos() -> void:
	var url := SUPABASE_URL + "/rest/v1/modulos_greenmetric?order=orden_desbloqueo.asc&activo=eq.true"
	_encolar("cargar_modulos", url, HTTPClient.METHOD_GET, _headers_anon())


# ── PROGRESO ─────────────────────────────────────────────────
func cargar_progreso() -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	var url := SUPABASE_URL + "/rest/v1/progreso_estudiante?select=*"
	_encolar("cargar_progreso", url, HTTPClient.METHOD_GET, _headers_auth())


func cargar_ranking() -> void:
	var url := SUPABASE_URL + "/rest/v1/progreso_estudiante?select=user_id,xp_ganada,completado&order=xp_ganada.desc"
	_encolar("cargar_ranking", url, HTTPClient.METHOD_GET, _headers_anon())


func guardar_progreso(modulo_id: int, puntaje: int, xp: int, completado: bool) -> void:
	if jwt_token.is_empty():
		push_error("SupabaseManager: Debes hacer login primero.")
		return
	var url  := SUPABASE_URL + "/rest/v1/progreso_estudiante"
	var body := JSON.stringify({
		"user_id"          : user_id,
		"modulo_id"        : modulo_id,
		"puntaje_obtenido" : puntaje,
		"xp_ganada"        : xp,
		"completado"       : completado
	})
	var hdrs := _headers_auth()
	hdrs.append("Prefer: resolution=merge-duplicates")
	_encolar("guardar_progreso", url, HTTPClient.METHOD_POST, hdrs, body)


# ── MANEJADOR CENTRAL ─────────────────────────────────────────
func _on_respuesta_http(result: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	var accion := _accion_actual
	_accion_actual = ""
	_ocupado       = false

	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("error_red", "Sin conexión. Código: " + str(result))
		_despachar()
		return

	var texto := body.get_string_from_utf8()
	var datos  = JSON.parse_string(texto)

	match accion:
		"login"           : _procesar_login(code, datos)
		"registro"        : _procesar_registro(code, datos)
		"recuperar"       : _procesar_recuperar(code, datos)
		"cargar_modulos"  : _procesar_modulos(code, datos)
		"cargar_progreso" : _procesar_progreso(code, datos)
		"guardar_progreso": _procesar_guardar(code)
		"cargar_ranking"  : _procesar_ranking(code, datos)

	_despachar()   # lanza la siguiente petición en cola si la hay


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
