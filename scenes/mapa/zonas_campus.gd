# ============================================================
# zonas_campus.gd - URBE Rangers: Eco-Quest
# Zonas calibradas sobre imagen real del campus URBE 1408x768.
# pos = CENTRO del area de zona (igual que el Area2D).
# La señal emite zona_key para lookup directo en SceneMapaMundo.
# ============================================================
extends Node2D

signal zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()

# ─────────────────────────────────────────────────────────────
# Tamaños calculados para que las zonas se extiendan ~30px
# DENTRO del pasillo accesible, compensando el redondeo de tiles
# (tx0/ty0 = floor → colisión empieza hasta 15px antes del edif.)
# más el radio del jugador (~7px). Esto garantiza que body_entered
# dispare cuando el jugador toca la pared del edificio.
# ─────────────────────────────────────────────────────────────
const ZONAS : Dictionary = {
	# ── Módulo 5 — Transporte ─────────────────────────────────
	# Corredor oeste x=220..280; colisión EstacionamientoEste en x≈224
	# Jugador toca pared → centro en x≈231; zona debe llegar a x≥231
	"ZonaEstacionamiento": {
		"modulo_id": 5,
		"nombre":    "Transporte - Estacionamiento M5",
		"color":     Color(0.05, 0.27, 0.63),
		"pos":       Vector2(110, 330),
		"size":      Vector2(260, 428),   # right=240 (alcanza corredor oeste)
	},
	# ── Módulo 3 — Residuos ───────────────────────────────────
	# Camino norte y=82..120; colisión Cafetín-Norte en y≈112
	# Jugador toca pared → centro y≈105; zona_top debe ser ≤98
	# Corredor sur Cafetín↔D y=280..320; zona_bottom ≤ 290
	"ZonaCafetin": {
		"modulo_id": 3,
		"nombre":    "Residuos - Cafetín Campus",
		"color":     Color(0.80, 0.65, 0.00),
		"pos":       Vector2(380, 190),
		"size":      Vector2(208, 200),   # top=90, bottom=290
	},
	# ── Módulo 4 — Agua — Patio Central (espacio abierto) ────
	"ZonaPatio": {
		"modulo_id": 4,
		"nombre":    "Agua - Patio Central",
		"color":     Color(0.00, 0.42, 0.51),
		"pos":       Vector2(590, 300),
		"size":      Vector2(220, 220),
	},
	# ── Módulo 2 — Energía ────────────────────────────────────
	# Camino norte y=82..120; colisión BloqueE-Norte en y≈112
	"ZonaBloqueE": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque E",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(890, 265),
		"size":      Vector2(388, 350),   # top=90 (alcanza camino norte)
	},
	# ── Módulo 1 — Entorno ────────────────────────────────────
	# Corredor este x=1080..1120; colisión EstDistancia-Oeste en x≈1120
	# Jugador toca → centro x≈1113; zona_left debe ser ≤1106
	"ZonaBloqueF": {
		"modulo_id": 1,
		"nombre":    "Entorno - Estudios a Distancia",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(1264, 390),
		"size":      Vector2(316, 548),   # left=1106 (alcanza corredor este)
	},
	# Corredor Cafetín↔D y=280..320 (norte) y D↔C y=480..520 (sur)
	"ZonaBloqueD": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque D",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(380, 400),
		"size":      Vector2(208, 180),   # top=310 (pasillo norte), bottom=490 (pasillo sur)
	},
	# Pasillo BloqueC/B↔A y=640..680; colisión BloqueA-Norte en y≈672
	# Jugador toca → centro y≈665; zona_top debe ser ≤658
	"ZonaBloqueA": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque A",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(490, 695),
		"size":      Vector2(428,  90),   # top=650 (bien dentro del pasillo)
	},
	# Corredor C↔B x=460..520; colisión BloqueB-Oeste en x≈512
	# Jugador toca → centro x≈505; zona_left debe ser ≤498
	"ZonaBloqueB": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque B",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(610, 580),
		"size":      Vector2(224, 128),   # left=498 (alcanza corredor C↔B)
	},
	# Corredor Fotoc↔BloqueC x=180..280; colisión Fotoc-Este en x≈192
	# Jugador toca → centro x≈199; zona_right debe ser ≥206
	"ZonaFotocopiado": {
		"modulo_id": 1,
		"nombre":    "Entorno - Centro de Fotocopiado",
		"color":     Color(0.18, 0.49, 0.20),
		"pos":       Vector2(105, 640),
		"size":      Vector2(210, 128),   # right=210 (alcanza corredor)
	},
	# Pasillo BloqueD↔BloqueC y=480..520; colisión BloqueC-Norte en y≈512
	# Jugador toca → centro y≈505; zona_top debe ser ≤498
	"ZonaBloqueC": {
		"modulo_id": 2,
		"nombre":    "Energia - Bloque C",
		"color":     Color(0.90, 0.45, 0.00),
		"pos":       Vector2(370, 565),
		"size":      Vector2(188, 150),   # top=490 (alcanza pasillo D↔C)
	},
	# ── Módulo 6 — Educación ─────────────────────────────────
	# Pasillo BloqueE↔Rectorado y=420..480; colisión Rectorado-Norte en y≈480
	"ZonaRectorado": {
		"modulo_id": 6,
		"nombre":    "Educacion e Investigacion - Rectorado",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(900, 572),
		"size":      Vector2(328, 200),   # top=472 (alcanza pasillo)
	},
	"ZonaAreaServicios": {
		"modulo_id": 6,
		"nombre":    "Educacion - SERVIEDUCA",
		"color":     Color(0.27, 0.00, 0.56),
		"pos":       Vector2(1264, 650),
		"size":      Vector2(296,  80),
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
