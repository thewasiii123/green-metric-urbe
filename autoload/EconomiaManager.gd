# ============================================================
# EconomiaManager.gd — URBE Rangers: Eco-Quest
# Autoload: EcoCredits, Energía/Vidas, Insignias, ImpactRating.
# ============================================================
extends Node

# ── Señales ──────────────────────────────────────────────────
signal ecocredits_cambiados(total: int)
signal energia_cambiada(actual: int, maximo: int)
signal insignia_obtenida(id: String, nombre: String, icono: String)
signal impacto_cambiado(modulo_id: int, valor: float)

# ── EcoCredits ────────────────────────────────────────────────
var ecocredits : int = 50

# ── Energía / Vidas ──────────────────────────────────────────
const MAX_ENERGIA   : int = 3
var energia_actual  : int = 3
var _fallos_racha   : int = 0

# ── ImpactRating por módulo (0.0–1.0) ────────────────────────
var impacto : Dictionary = {
	1: 0.35, 2: 0.40, 3: 0.30,
	4: 0.45, 5: 0.22, 6: 0.55
}

# ── Insignias ─────────────────────────────────────────────────
const INSIGNIAS : Dictionary = {
	"m1_completo":    {"nombre": "Guardián Verde",    "icono": "🌿"},
	"m2_completo":    {"nombre": "Ahorrista Solar",   "icono": "⚡"},
	"m3_completo":    {"nombre": "Eco Clasificador",  "icono": "♻"},
	"m4_completo":    {"nombre": "Gota Vital",        "icono": "💧"},
	"m5_completo":    {"nombre": "Ciclista Campus",   "icono": "🚲"},
	"m6_completo":    {"nombre": "EcoInvestigador",   "icono": "📚"},
	"quiz_perfecto":  {"nombre": "Puntaje Perfecto",  "icono": "⭐"},
	"racha_fuego":    {"nombre": "Racha Ardiente",    "icono": "🔥"},
	"crisis_resuelta":{"nombre": "Héroe de Crisis",   "icono": "🚨"},
	"ecolider":       {"nombre": "EcoLíder URBE",     "icono": "🏆"},
}
var _insignias_obtenidas : Array = []

# ── Preguntas remediales para recuperar energía ───────────────
const PREGUNTAS_REMEDIALES : Array = [
	{"q": "¿Qué evalúa principalmente UI GreenMetric?",
	 "ops": ["Deportes universitarios", "Sostenibilidad del campus", "Rendimiento académico"], "c": 1},
	{"q": "¿Qué color corresponde a contenedores de papel reciclable?",
	 "ops": ["Rojo", "Azul", "Negro"], "c": 1},
	{"q": "¿Qué significa CO₂ en el contexto ambiental?",
	 "ops": ["Dióxido de carbono — gas de efecto invernadero", "Cloruro de calcio", "Combustible fósil"], "c": 0},
	{"q": "¿Qué porcentaje mínimo de área verde promueve GreenMetric?",
	 "ops": ["5%", "15%", "25%"], "c": 2},
	{"q": "¿Qué transporte prioriza GreenMetric en campus?",
	 "ops": ["Auto privado", "Moto", "Bicicleta y transporte público"], "c": 2},
	{"q": "¿Cuál es el módulo GreenMetric que evalúa el consumo eléctrico?",
	 "ops": ["Entorno", "Energía", "Transporte"], "c": 1},
	{"q": "¿Qué acción reduce más el consumo de agua en un campus?",
	 "ops": ["Regar jardines a mediodía", "Instalar grifos temporizadores", "Usar manguera libre"], "c": 1},
]
var _remedial_idx : int = 0


func _ready() -> void:
	randomize()


# ── EcoCredits ────────────────────────────────────────────────
func ganar_creditos(cantidad: int) -> void:
	ecocredits += cantidad
	ecocredits_cambiados.emit(ecocredits)


func gastar_creditos(cantidad: int) -> bool:
	if ecocredits < cantidad: return false
	ecocredits -= cantidad
	ecocredits_cambiados.emit(ecocredits)
	return true


# ── Energía ───────────────────────────────────────────────────
func tiene_energia() -> bool:
	return energia_actual > 0


func on_fallo_quiz() -> void:
	_fallos_racha += 1
	if _fallos_racha >= 2:
		_fallos_racha = 0
		energia_actual = maxi(0, energia_actual - 1)
		energia_cambiada.emit(energia_actual, MAX_ENERGIA)


func on_acierto_quiz() -> void:
	_fallos_racha = 0


func recuperar_con_creditos() -> bool:
	if not gastar_creditos(25): return false
	energia_actual = mini(MAX_ENERGIA, energia_actual + 1)
	energia_cambiada.emit(energia_actual, MAX_ENERGIA)
	return true


func recuperar_con_remedial() -> void:
	energia_actual = mini(MAX_ENERGIA, energia_actual + 1)
	energia_cambiada.emit(energia_actual, MAX_ENERGIA)


func siguiente_pregunta_remedial() -> Dictionary:
	var p : Dictionary = PREGUNTAS_REMEDIALES[_remedial_idx % PREGUNTAS_REMEDIALES.size()]
	_remedial_idx += 1
	return p


# ── ImpactRating ──────────────────────────────────────────────
func actualizar_impacto(modulo_id: int, delta: float) -> float:
	if not impacto.has(modulo_id): return 0.0
	impacto[modulo_id] = clampf(impacto[modulo_id] + delta, 0.0, 1.0)
	impacto_cambiado.emit(modulo_id, impacto[modulo_id])
	return impacto[modulo_id]


func get_color_impacto(modulo_id: int) -> Color:
	var v : float = impacto.get(modulo_id, 0.5)
	if v < 0.40:   return Color(0.88, 0.18, 0.18)
	elif v < 0.75: return Color(0.90, 0.65, 0.08)
	else:          return Color(0.18, 0.82, 0.18)


func impacto_global() -> float:
	var s : float = 0.0
	for v in impacto.values(): s += v
	return s / float(impacto.size())


# ── Insignias ─────────────────────────────────────────────────
func otorgar_insignia(id: String) -> void:
	if id in _insignias_obtenidas or not INSIGNIAS.has(id): return
	_insignias_obtenidas.append(id)
	var ins : Dictionary = INSIGNIAS[id]
	insignia_obtenida.emit(id, ins["nombre"], ins["icono"])


func on_modulo_completado(modulo_id: int, xp_ganado: int, xp_maximo: int) -> void:
	ganar_creditos(xp_ganado / 5)
	actualizar_impacto(modulo_id, 0.15)
	otorgar_insignia("m%d_completo" % modulo_id)
	if xp_ganado >= xp_maximo:
		otorgar_insignia("quiz_perfecto")
	if _insignias_obtenidas.size() >= INSIGNIAS.size() - 1:
		otorgar_insignia("ecolider")


func insignias_lista() -> Array:
	return _insignias_obtenidas.duplicate()
