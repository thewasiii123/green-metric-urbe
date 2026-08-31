# ============================================================
# NivelManager.gd — URBE Rangers: Eco-Quest
# Autoload global que gestiona el sistema de niveles basado
# en los 6 módulos de UI GreenMetric.
# Nivel 1 = Infraestructura y Entorno
# Nivel 2 = Energía y Cambio Climático
# ============================================================
extends Node

signal nivel_completado(nivel: int)
signal mision_nivel_completada(nivel: int, mision_id: String)

# ── Configuración por nivel ──────────────────────────────────
const NOMBRES_NIVEL : Array[String] = [
	"",
	"Infraestructura y Entorno",
	"Energía y Cambio Climático",
	"Manejo de Residuos",
	"Uso del Agua",
	"Transporte Sostenible",
	"Educación e Investigación",
]

const ICONOS_NIVEL : Array[String] = [
	"", "🌿", "⚡", "♻", "💧", "🚲", "📚"
]

# Cuántas misiones de campo tiene cada nivel
const TOTAL_MISIONES : Dictionary = {
	1: 6,   # 3 zonas click (plaza) + 3 zonas drag (áreas verdes)
	2: 8,   # 6 LED + 2 paneles solares
	3: 6,   # 6 puntos de donación y reciclaje
	4: 8,   # 6 llaves abiertas + 2 captación de agua de lluvia
	5: 8,   # 6 decisiones de movilidad + 2 bicicleteros
	6: 4,   # malla_verde + comite_ambiental + semana_verde + informe_final
}

const XP_POR_MISION : Dictionary  = {1: 40, 2: 50, 3: 35, 4: 35, 5: 35, 6: 70}
const EC_POR_MISION : Dictionary  = {1: 15, 2: 20, 3: 12, 4: 12, 5: 12, 6: 20}
const XP_NIVEL_BONUS : Dictionary = {1: 150, 2: 250, 3: 180, 4: 180, 5: 180, 6: 200}

const SAVE_PATH : String = "user://nivel_progreso.json"

# ── Estado ───────────────────────────────────────────────────
var nivel_actual : int = 1
# {nivel_str: {mision_id: bool}}
var _misiones : Dictionary = {}
# {mision_id: Dictionary} — qué eligió el jugador en misiones con decisiones
# propias (Nivel 6: Malla Verde, Comité, Semana Verde), para citarlas
# textualmente en el informe final. No confundir con _misiones (solo bool).
var _detalles : Dictionary = {}


func _ready() -> void:
	add_to_group("nivel_manager")
	_cargar()


# ── API pública ───────────────────────────────────────────────

func nivel_desbloqueado(n: int) -> bool:
	if n == 1: return true
	return nivel_completo(n - 1)

func nivel_completo(n: int) -> bool:
	var s := str(n)
	var total : int = TOTAL_MISIONES.get(n, 0)
	if total == 0: return false
	if not _misiones.has(s): return false
	var completadas := 0
	for v in (_misiones[s] as Dictionary).values():
		if v: completadas += 1
	return completadas >= total

func pct_nivel(n: int) -> float:
	var s := str(n)
	var total : int = TOTAL_MISIONES.get(n, 0)
	if total == 0: return 0.0
	if not _misiones.has(s): return 0.0
	var completadas := 0
	for v in (_misiones[s] as Dictionary).values():
		if v: completadas += 1
	return float(completadas) / float(total)

func mision_completada_q(nivel: int, mision_id: String) -> bool:
	var s := str(nivel)
	if not _misiones.has(s): return false
	return (_misiones[s] as Dictionary).get(mision_id, false)

func guardar_detalle(mision_id: String, detalle: Dictionary) -> void:
	_detalles[mision_id] = detalle
	_guardar()

func obtener_detalle(mision_id: String) -> Dictionary:
	return _detalles.get(mision_id, {})

func completar_mision(nivel: int, mision_id: String) -> void:
	if mision_completada_q(nivel, mision_id): return
	var s := str(nivel)
	if not _misiones.has(s):
		_misiones[s] = {}
	(_misiones[s] as Dictionary)[mision_id] = true
	_guardar()
	mision_nivel_completada.emit(nivel, mision_id)
	if nivel_completo(nivel):
		nivel_completado.emit(nivel)
		if nivel == nivel_actual and nivel < 6:
			nivel_actual = nivel + 1
			_guardar()

# ── Persistencia ─────────────────────────────────────────────

func _cargar() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK: return
	var data = json.get_data()
	if not (data is Dictionary): return
	nivel_actual = int(data.get("nivel_actual", 1))
	var mis = data.get("misiones", {})
	if mis is Dictionary:
		_misiones = mis
	var det = data.get("detalles", {})
	if det is Dictionary:
		_detalles = det

func _guardar() -> void:
	var data := {"nivel_actual": nivel_actual, "misiones": _misiones, "detalles": _detalles}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f: return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ── Debug ─────────────────────────────────────────────────────
func reset_progreso() -> void:
	nivel_actual = 1
	_misiones = {}
	_detalles = {}
	_guardar()
