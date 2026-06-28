# ============================================================
# zonas_campus.gd - URBE Rangers: Eco-Quest
# Zonas calibradas sobre imagen real del campus URBE 1408x768.
# pos = CENTRO del area de zona (igual que el Area2D).
# ============================================================
extends Node2D

signal zona_activada(modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()

const ZONAS : Dictionary = {
	"ZonaRectorado": {
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Rectorado",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(889, 640),
		"size":      Vector2(232, 156),
	},
	"ZonaBloqueA": {
		"modulo_id": 2,
		"nombre":    "Energia y Cambio Climatico - Bloque A",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(444, 492),
		"size":      Vector2(121,  85),
	},
	"ZonaBloqueB": {
		"modulo_id": 2,
		"nombre":    "Energia y Cambio Climatico - Bloque B",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(570, 400),
		"size":      Vector2(129,  90),
	},
	"ZonaBloqueC": {
		"modulo_id": 2,
		"nombre":    "Energia y Cambio Climatico - Bloque C",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(834, 486),
		"size":      Vector2(122,  82),
	},
	"ZonaBloqueD": {
		"modulo_id": 2,
		"nombre":    "Energia y Cambio Climatico - Bloque D",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(834, 391),
		"size":      Vector2(122,  92),
	},
	"ZonaBloqueE": {
		"modulo_id": 2,
		"nombre":    "Energia y Cambio Climatico - Bloque E",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(937, 222),
		"size":      Vector2(145, 135),
	},
	"ZonaBloqueF": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura - Bloque F",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1227, 420),
		"size":      Vector2(215, 240),
	},
	"ZonaBloqueG": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura - Bloque G",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(575, 654),
		"size":      Vector2(142,  92),
	},
	"ZonaBiblioteca": {
		"modulo_id": 4,
		"nombre":    "Agua - Biblioteca",
		"color":     Color(0.00, 0.42, 0.51),
		"pos":       Vector2(680, 245),
		"size":      Vector2(220, 140),
	},
	"ZonaEstacionamiento": {
		"modulo_id": 5,
		"nombre":    "Transporte - Estacionamiento",
		"color":     Color(0.05, 0.27, 0.63),
		"pos":       Vector2(231, 377),
		"size":      Vector2(246, 155),
	},
	"ZonaAreaServicios": {
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Area de Servicios",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(1258, 640),
		"size":      Vector2(257, 160),
	},
}


func _ready() -> void:
	for hijo in get_children():
		hijo.queue_free()
	await get_tree().process_frame
	_configurar_zonas()


func _configurar_zonas() -> void:
	for nombre_zona in ZONAS.keys():
		var datos : Dictionary = ZONAS[nombre_zona]
		var zona              := Area2D.new()
		zona.name              = nombre_zona
		zona.position          = datos["pos"]
		zona.collision_layer   = 0
		zona.collision_mask    = 1
		add_child(zona)
		var cs   := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = datos["size"]
		cs.shape  = rect
		zona.add_child(cs)
		zona.body_entered.connect(_on_zona_entrada.bind(nombre_zona))
		zona.body_exited.connect(_on_zona_salida_body.bind(nombre_zona))


func _on_zona_entrada(cuerpo: Node, nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	var d : Dictionary = ZONAS[nombre_zona]
	zona_activada.emit(d["modulo_id"], d["nombre"], d["color"])


func _on_zona_salida_body(cuerpo: Node, _nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	zona_salida.emit()
