# ============================================================
# colisiones_edificios.gd - URBE Rangers: Eco-Quest
# Colisiones calibradas sobre la imagen real del campus URBE.
# Mapa: 1408 x 768 px
# Formato: [nombre, centro_x, centro_y, ancho, alto]
# ============================================================
extends Node2D

const EDIFICIOS : Array = [
	# Zona superior: lago y puente (no transitable)
	["LimiteLago",       704,   85,  1408,  170],
	["LagoBordeIzq",      75,  200,   150,  200],

	# Edificios principales (calibrados sobre imagen real)
	["ColBiblioteca",    680,  245,   220,  140],
	["ColBloqueE",       937,  222,   145,  135],
	["ColBloqueF",      1227,  420,   215,  240],
	["ColEstacion",      231,  377,   246,  155],
	["ColFotocopiado",   189,  465,   102,   90],
	["ColBloqueB",       570,  400,   129,   90],
	["ColBloqueD",       834,  391,   122,   92],
	["ColBloqueA",       444,  492,   121,   85],
	["ColBloqueC",       834,  486,   122,   82],
	["ColBloqueG",       575,  654,   142,   92],
	["ColRectorado",     889,  640,   232,  156],
	["ColAreaServicios", 1258,  640,   257,  160],

	# Bordes del mundo
	["BordeSuperior",    704,    5,  1408,   10],
	["BordeInferior",    704,  763,  1408,   10],
	["BordeIzquierdo",     5,  384,    10,  768],
	["BordeDerecho",    1403,  384,    10,  768],
]


func _ready() -> void:
	for datos in EDIFICIOS:
		_crear_colision(datos[0], datos[1], datos[2], datos[3], datos[4])
	print("OK %d colisiones creadas" % EDIFICIOS.size())


func _crear_colision(nombre: String, cx: float, cy: float, ancho: float, alto: float) -> void:
	var body      := StaticBody2D.new()
	body.name      = nombre
	var cs        := CollisionShape2D.new()
	var rect      := RectangleShape2D.new()
	rect.size      = Vector2(ancho, alto)
	cs.position    = Vector2(cx, cy)
	cs.shape       = rect
	body.add_child(cs)
	add_child(body)
