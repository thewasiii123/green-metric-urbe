# ============================================================
# zonas_campus.gd — URBE Rangers: Eco-Quest
# Posiciones calibradas para mapa 1408 x 768 px
# ============================================================
extends Node2D

signal zona_activada(modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()

const ZONAS : Dictionary = {
	"ZonaRectorado": {
		"modulo_id": 6,
		"nombre":    "Educación e Investigación — Rectorado",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(711,  199),
		"size":      Vector2(224,  114),
	},
	"ZonaBloqueA": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura — Bloque A",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(264,  284),
		"size":      Vector2(154,  107),
	},
	"ZonaBloqueBC": {
		"modulo_id": 2,
		"nombre":    "Energía y Cambio Climático — Bloques B y C",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(563,  326),
		"size":      Vector2(182,   92),
	},
	"ZonaBloqueDE": {
		"modulo_id": 2,
		"nombre":    "Energía y Cambio Climático — Bloques D y E",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(816,  295),
		"size":      Vector2(182,   92),
	},
	"ZonaBloqueG": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura — Bloque G",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1203, 207),
		"size":      Vector2(183,  104),
	},
	"ZonaBiblioteca": {
		"modulo_id": 4,
		"nombre":    "Agua — Biblioteca",
		"color":     Color(0.00, 0.42, 0.51),
		"pos":       Vector2(960,  368),
		"size":      Vector2(176,   77),
	},
	"ZonaAuditorio": {
		"modulo_id": 6,
		"nombre":    "Educación e Investigación — Auditorio",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(192,  426),
		"size":      Vector2(218,  100),
	},
	"ZonaEstacionamiento": {
		"modulo_id": 5,
		"nombre":    "Transporte — Estacionamiento",
		"color":     Color(0.05, 0.27, 0.63),
		"pos":       Vector2(767,  449),
		"size":      Vector2(296,  100),
	},
	"ZonaCanchas": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura — Canchas Deportivas",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1147, 464),
		"size":      Vector2(252,  138),
	},
}


func _ready() -> void:
	# Eliminar hijos Area2D viejos que puedan existir
	for hijo in get_children():
		hijo.queue_free()
	await get_tree().process_frame
	_configurar_zonas()


func _configurar_zonas() -> void:
	for nombre_zona in ZONAS.keys():
		var datos : Dictionary = ZONAS[nombre_zona]

		var zona       := Area2D.new()
		zona.name       = nombre_zona
		zona.position   = datos["pos"]
		zona.collision_layer = 0
		zona.collision_mask  = 1
		add_child(zona)

		var cs         := CollisionShape2D.new()
		var rect       := RectangleShape2D.new()
		rect.size       = datos["size"]
		cs.shape        = rect
		zona.add_child(cs)

		zona.body_entered.connect(_on_zona_entrada.bind(nombre_zona))
		zona.body_exited.connect(_on_zona_salida_body.bind(nombre_zona))

		print("✅ Zona lista: %s  pos:%s  size:%s" % [
			nombre_zona, str(datos["pos"]), str(datos["size"])
		])


func _on_zona_entrada(cuerpo: Node, nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	var d : Dictionary = ZONAS[nombre_zona]
	zona_activada.emit(d["modulo_id"], d["nombre"], d["color"])


func _on_zona_salida_body(cuerpo: Node, _nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	zona_salida.emit()
