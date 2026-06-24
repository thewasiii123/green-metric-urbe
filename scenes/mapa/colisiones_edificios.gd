# ============================================================
# ColisionesEdificios.gd
# Crea StaticBody2D invisibles sobre cada edificio del mapa.
# El jugador choca con ellos pero no los atraviesa.
# Adjunta este script al nodo "ColisionesEdificios" (Node2D).
# ============================================================
extends Node2D

# ── Datos de colisión por edificio ───────────────────────────
# Formato: [nombre, centro_x, centro_y, ancho, alto]
# Estas son las bases/pies de los edificios (zona caminable bloqueada)
# La colisión cubre solo la BASE del edificio, no el techo visual

const EDIFICIOS : Array = [
	# Edificios superiores (zona decorativa del lago — bloqueada completa)
	["LimiteLago",       450,   80,  1050,  160],   # toda la franja del lago

	# Edificios principales
	["ColRectorado",     711,  230,   190,   60],
	["ColBloqueA",       263,  330,   140,   60],
	["ColBloqueC",       471,  240,   110,   55],
	["ColBloqueB",       566,  370,   145,   55],
	["ColBloqueD",       820,  355,   145,   55],
	["ColBloqueE",       942,  245,   165,   55],
	["ColBloqueF",       612,  415,   122,   50],
	["ColBloqueG",      1203,  248,   178,   55],
	["ColBiblioteca",    960,  395,   172,   50],
	["ColAuditorio",     193,  465,   210,   60],

	# Bordes exteriores de tierra / acantilado (impiden salirse)
	["BordeSuperior",    704,   10,  1408,   20],
	["BordeInferior",    704,  760,  1408,   20],
	["BordeIzquierdo",    10,  384,    20,  768],
	["BordeDerecho",    1398,  384,    20,  768],

	# Zona del lago izquierda (barco decorativo — no transitable)
	["ColLagoIzq",       120,  160,   240,  200],
]


func _ready() -> void:
	for datos in EDIFICIOS:
		_crear_colision(datos[0], datos[1], datos[2], datos[3], datos[4])
	print("✅ %d colisiones de edificios creadas" % EDIFICIOS.size())


func _crear_colision(nombre: String, cx: float, cy: float, w: float, h: float) -> void:
	var body      := StaticBody2D.new()
	body.name      = nombre
	var cs        := CollisionShape2D.new()
	var rect      := RectangleShape2D.new()
	rect.size      = Vector2(w, h)
	cs.position    = Vector2(cx, cy)
	cs.shape       = rect
	body.add_child(cs)
	add_child(body)
