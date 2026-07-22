# ============================================================
# zonas_campus.gd - URBE Rangers: Eco-Quest
# Zonas calibradas sobre imagen real del campus URBE 1408x768.
# pos = CENTRO del area de zona (igual que el Area2D).
# La señal emite zona_key para lookup directo en SceneMapaMundo.
# ============================================================
extends Node2D

signal zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()

const ZONAS : Dictionary = {
	# ── Módulo 5 — Transporte ─────────────────────────────────
	"ZonaEstacionamiento": {
		"modulo_id": 5,
		"nombre":    "Transporte - Estacionamiento",
		"color":     Color(0.05, 0.27, 0.63),
		"pos":       Vector2(96, 288),
		"size":      Vector2(200, 168),
	},
	# ── Módulo 3 — Residuos ───────────────────────────────────
	"ZonaCafetin": {
		"modulo_id": 3,
		"nombre":    "Residuos - Cafetín Campus",
		"color":     Color(0.80, 0.65, 0.00),
		"pos":       Vector2(328, 288),
		"size":      Vector2(184, 168),
	},
	# ── Módulo 4 — Agua ──────────────────────────────────────
	"ZonaBiblioteca": {
		"modulo_id": 4,
		"nombre":    "Agua - Biblioteca",
		"color":     Color(0.00, 0.42, 0.51),
		"pos":       Vector2(568, 288),
		"size":      Vector2(216, 168),
	},
	# ── Módulo 2 — Energía y Cambio Climático ────────────────
	"ZonaBloqueE": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque E",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(776, 288),
		"size":      Vector2(152, 168),
	},
	# ── Módulo 1 — Entorno e Infraestructura ─────────────────
	"ZonaBloqueF": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura - Bloque F",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1280, 392),
		"size":      Vector2(264, 376),
	},
	"ZonaBloqueG": {
		"modulo_id": 1,
		"nombre":    "Entorno e Infraestructura - Bloque G",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(96, 488),
		"size":      Vector2(200, 184),
	},
	"ZonaBloqueD": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque D",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(328, 488),
		"size":      Vector2(184, 184),
	},
	"ZonaBloqueA": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque A",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(552, 488),
		"size":      Vector2(184, 184),
	},
	"ZonaBloqueB": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque B",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(752, 488),
		"size":      Vector2(168, 184),
	},
	"ZonaFotocopiado": {
		"modulo_id": 1,
		"nombre":    "Entorno - Centro de Fotocopiado",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(72, 656),
		"size":      Vector2(152, 104),
	},
	"ZonaBloqueC": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque C",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(320, 656),
		"size":      Vector2(168, 104),
	},
	# ── Módulo 6 — Educación e Investigación ─────────────────
	"ZonaRectorado": {
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Rectorado",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(672, 656),
		"size":      Vector2(424, 104),
	},
	"ZonaAreaServicios": {
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Area de Servicios",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(1280, 656),
		"size":      Vector2(264, 104),
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
	zona_activada.emit(nombre_zona, d["modulo_id"], d["nombre"], d["color"])


func _on_zona_salida_body(cuerpo: Node, _nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	zona_salida.emit()
