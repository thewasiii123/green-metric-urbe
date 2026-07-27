# ============================================================
# mision_plantar.gd — NIVEL 1: Infraestructura y Entorno
# Minijuego de plantación sostenible.
# El estudiante debe elegir la planta correcta para cada
# zona del campus según criterios de sostenibilidad.
# ============================================================
extends CanvasLayer

signal mision_completada_plantar(mision_id: String, xp: int, ec: int)

# ── Datos de las 3 misiones de plantación ───────────────────
const MISIONES : Array = [
	{
		"id":       "plantar_corredores",
		"zona":     "Corredor Principal URBE",
		"icono":    "🌳",
		"contexto": "Los corredores del campus reciben el sol directo todo el día.\nLos estudiantes necesitan sombra natural y las aceras requieren raíces no invasivas.",
		"criterio": "Necesitamos un árbol nativo que dé sombra amplia sin dañar la infraestructura.",
		"correcta": "araguaney",
		"plantas":  [
			{"id": "araguaney",      "nombre": "Araguaney",          "desc": "Árbol Nacional · Sombra amplia · Raíces no invasivas"},
			{"id": "eucalipto",      "nombre": "Eucalipto",           "desc": "Especie introducida · Raíces invasivas"},
			{"id": "cactus",         "nombre": "Cactus del Desierto", "desc": "Especie desértica · Sin sombra"},
			{"id": "pino_canadiense","nombre": "Pino Canadiense",     "desc": "Especie foránea · Clima frío"},
		],
		"feedback": {
			"araguaney":       "✅ ¡Excelente! El Araguaney es el Árbol Nacional de Venezuela. Su copa amplia proporciona sombra perfecta y sus raíces no dañan las aceras. ¡Elección ideal para corredores universitarios!",
			"eucalipto":       "❌ El eucalipto es una especie invasiva. Sus raíces profundas y agresivas dañan aceras e infraestructura. Además consume grandes cantidades de agua subterránea.",
			"cactus":          "❌ El cactus del desierto no es apto para el clima tropical de Maracaibo. No proporciona sombra y no se adapta a las condiciones de humedad del campus.",
			"pino_canadiense": "❌ El pino canadiense es una especie de clima frío. No tolera las altas temperaturas de Maracaibo y no brinda la sombra adecuada para corredores universitarios.",
		},
	},
	{
		"id":       "plantar_rectorado",
		"zona":     "Jardín del Rectorado",
		"icono":    "🌺",
		"contexto": "El jardín principal del Rectorado es la carta de presentación del campus.\nNecesita plantas ornamentales con bajo consumo de agua y alto impacto visual.",
		"criterio": "Buscamos plantas decorativas adaptadas al trópico, resistentes al calor y sin pesticidas.",
		"correcta": "buganvilia",
		"plantas":  [
			{"id": "buganvilia",  "nombre": "Buganvilia (Veranera)", "desc": "Tropical · Ornamental · Resistente · Poco agua"},
			{"id": "rosa_inglesa","nombre": "Rosa Inglesa",          "desc": "Alto mantenimiento · Necesita pesticidas"},
			{"id": "bambu",       "nombre": "Bambú Gigante",         "desc": "Invasivo · Crece descontrolado"},
			{"id": "cactus",      "nombre": "Cactus",                "desc": "Sin valor ornamental para jardín formal"},
		],
		"feedback": {
			"buganvilia":   "✅ ¡Perfecto! La Buganvilia (Veranera) es ideal: resistente al calor de Maracaibo, consume poca agua, florece abundantemente todo el año y embellece el campus sin requerir pesticidas.",
			"rosa_inglesa": "❌ La rosa inglesa requiere muchos cuidados, pesticidas y condiciones de clima templado. Su mantenimiento intensivo es incompatible con los principios de sostenibilidad de GreenMetric.",
			"bambu":        "❌ El bambú gigante es una especie invasiva. Se propaga de forma descontrolada, puede dañar estructuras y no es adecuado para un jardín formal universitario.",
			"cactus":       "❌ El cactus no tiene valor ornamental para un jardín universitario formal. No produce flores vistosas ni proporciona la imagen verde que necesita el Rectorado.",
		},
	},
	{
		"id":       "plantar_patio",
		"zona":     "Patio Central Estudiantil",
		"icono":    "🌿",
		"contexto": "El patio central es el espacio de descanso de los estudiantes.\nNecesita vegetación que cree un microclima fresco sin obstruir el paso ni crear peligros.",
		"criterio": "Plantas de bajo mantenimiento que reduzcan la temperatura y sean seguras para el tránsito.",
		"correcta": "helecho_tropical",
		"plantas":  [
			{"id": "helecho_tropical","nombre": "Helecho Tropical + Pasto","desc": "Bajo mantenimiento · Fresco · Seguro"},
			{"id": "mango",           "nombre": "Árbol de Mango",          "desc": "Frutos resbalosos · Raíces invasivas"},
			{"id": "bambu",           "nombre": "Bambú",                   "desc": "Invasivo · Obstruye el paso"},
			{"id": "eucalipto",       "nombre": "Eucalipto",               "desc": "Invasivo · Tóxico para otras plantas"},
		],
		"feedback": {
			"helecho_tropical": "✅ ¡Correcto! El helecho tropical con pasto San Agustín crea un manto verde de bajo mantenimiento que reduce la temperatura del suelo, es seguro para el tránsito estudiantil y no requiere podas frecuentes.",
			"mango":            "❌ El árbol de mango presenta riesgos: sus frutos caídos son resbalosos y peligrosos, sus raíces invasivas dañan las aceras y su sombra irregular no es ideal para zonas de tránsito.",
			"bambu":            "❌ El bambú se propaga invasivamente y puede obstruir el paso en el patio. Su rápido crecimiento requiere mantenimiento constante y podría dañar la infraestructura cercana.",
			"eucalipto":        "❌ El eucalipto libera compuestos alelopáticos que inhiben el crecimiento de otras plantas. Además es invasivo y consume grandes cantidades de agua subterránea.",
		},
	},
]

# ── Constantes visuales ──────────────────────────────────────
const PANEL_W   : float = 960.0
const PANEL_H   : float = 620.0
const CARTA_W   : float = 195.0
const CARTA_H   : float = 210.0

# ── Estado ───────────────────────────────────────────────────
var _mision_idx     : int    = 0
var _mision_id      : String = ""
var _seleccion_ok   : bool   = false
var _zona_ref       : Area2D = null   # zona_tierra que disparó esta misión

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root     : Panel         = null
var _zona_lbl       : Label         = null
var _contexto_lbl   : Label         = null
var _criterio_lbl   : Label         = null
var _suelo_node     : Node2D        = null
var _cartas         : Array         = []
var _feedback_panel : Panel         = null
var _fb_icono       : Label         = null
var _fb_titulo      : Label         = null
var _fb_desc        : Label         = null
var _fb_btn         : Button        = null
var _pct_lbl        : Label         = null
var _nivel_badge    : Label         = null

# ── Inner class: ilustración de planta ───────────────────────
class PlantaVisual extends Node2D:
	var tipo : String = ""
	var _t   : float  = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match tipo:
			"araguaney":       _araguaney()
			"buganvilia":      _buganvilia()
			"cactus":          _cactus()
			"eucalipto":       _eucalipto()
			"pino_canadiense": _pino()
			"rosa_inglesa":    _rosa()
			"bambu":           _bambu()
			"helecho_tropical":_helecho()
			_:                 _generico()

	func _araguaney() -> void:
		# Tronco marrón
		draw_rect(Rect2(-5, 2, 10, 30), Color(0.42, 0.26, 0.10))
		# Raíces (no invasivas, pequeñas)
		draw_line(Vector2(-5, 28), Vector2(-14, 34), Color(0.35, 0.20, 0.08), 2.0)
		draw_line(Vector2( 5, 28), Vector2( 14, 34), Color(0.35, 0.20, 0.08), 2.0)
		# Copa amarilla (flores de araguaney)
		draw_circle(Vector2( 0, -20), 26.0, Color(0.90, 0.72, 0.05, 0.92))
		draw_circle(Vector2(-14, -10), 18.0, Color(0.92, 0.76, 0.06, 0.85))
		draw_circle(Vector2( 14, -10), 18.0, Color(0.92, 0.76, 0.06, 0.85))
		draw_circle(Vector2(  0, -34), 16.0, Color(0.95, 0.80, 0.10, 0.82))
		# Flores amarillas individuales
		for i in 10:
			var a := float(i) / 10.0 * TAU
			var r := 18.0 + sin(_t * 2.0 + a) * 2.5
			var p := Vector2(cos(a) * r, sin(a) * r * 0.7 - 18)
			draw_circle(p, 3.5, Color(1.0, 0.90, 0.15))
		# Hojas verdes visibles bajo flores
		draw_circle(Vector2(-8, -8), 9.0, Color(0.18, 0.52, 0.14, 0.60))
		draw_circle(Vector2( 8, -8), 9.0, Color(0.18, 0.52, 0.14, 0.60))

	func _buganvilia() -> void:
		# Tallo principal
		draw_line(Vector2(0, 32), Vector2(-16, -4), Color(0.28, 0.48, 0.14), 3.0)
		draw_line(Vector2(0, 32), Vector2( 16, -4), Color(0.28, 0.48, 0.14), 3.0)
		draw_line(Vector2(-16, -4), Vector2(-22, -22), Color(0.28, 0.48, 0.14), 2.5)
		draw_line(Vector2( 16, -4), Vector2( 22, -22), Color(0.28, 0.48, 0.14), 2.5)
		draw_line(Vector2(0, 10), Vector2(0, -28), Color(0.28, 0.48, 0.14), 2.5)
		# Hojas verdes
		var hojas := [Vector2(-10, 8), Vector2(10, 8), Vector2(-6, -2), Vector2(6, -2)]
		for h in hojas:
			draw_circle(h, 7.0, Color(0.22, 0.58, 0.18, 0.75))
		# Brácteas / flores (fucsia/morado)
		var flores := [Vector2(-24, -24), Vector2(24, -24), Vector2(-10, -32),
					   Vector2(10, -32), Vector2(0, -36), Vector2(-18, -16), Vector2(18, -16)]
		for f in flores:
			for j in 5:
				var a := float(j) / 5.0 * TAU + _t * 0.5
				draw_circle(f + Vector2(cos(a), sin(a)) * 6.5, 4.5,
							Color(0.88, 0.20, 0.62, 0.90))
		# Centro amarillo de las flores
		for f in flores:
			draw_circle(f, 2.5, Color(1.0, 0.88, 0.15))

	func _cactus() -> void:
		# Suelo arenoso
		draw_arc(Vector2(0, 34), 22.0, 0.0, PI, 14, Color(0.72, 0.58, 0.30, 0.6), 8.0)
		# Cuerpo principal
		var body := PackedVector2Array([
			Vector2(-10, 32), Vector2(10, 32), Vector2(11, -22), Vector2(-11, -22)
		])
		draw_colored_polygon(body, Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(0, -22), 11.0, PI, TAU, 14, Color(0.20, 0.52, 0.16), 22.0)
		# Brazos
		draw_rect(Rect2(-30, -8, 20, 10), Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(-20, -8), 10.0, PI, TAU, 10, Color(0.20, 0.52, 0.16), 20.0)
		draw_rect(Rect2(10, -2, 20, 10), Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(20, -2), 10.0, PI, TAU, 10, Color(0.20, 0.52, 0.16), 20.0)
		# Espinas
		for i in 12:
			var y_pos := -20.0 + float(i) * 4.5
			draw_line(Vector2(-11, y_pos), Vector2(-17, y_pos - 2), Color(0.85, 0.80, 0.60), 1.2)
			draw_line(Vector2( 11, y_pos), Vector2( 17, y_pos - 2), Color(0.85, 0.80, 0.60), 1.2)
		# Flor en la cima (pequeña)
		draw_circle(Vector2(0, -34), 6.0, Color(0.95, 0.30, 0.20))
		draw_circle(Vector2(0, -34), 3.0, Color(1.0, 0.85, 0.15))

	func _eucalipto() -> void:
		# Tronco delgado alto (árbol muy alto y estrecho)
		draw_rect(Rect2(-3, -32, 6, 64), Color(0.55, 0.48, 0.38))
		# Raíces invasivas (amplias y visibles)
		draw_line(Vector2(-3, 30), Vector2(-30, 36), Color(0.45, 0.35, 0.22), 3.0)
		draw_line(Vector2( 3, 30), Vector2( 30, 36), Color(0.45, 0.35, 0.22), 3.0)
		draw_line(Vector2(-3, 28), Vector2(-22, 40), Color(0.45, 0.35, 0.22), 2.0)
		draw_line(Vector2( 3, 28), Vector2( 22, 40), Color(0.45, 0.35, 0.22), 2.0)
		# Texto "INVASIVO" indicador (raíces)
		# Ramas plateadas (hojas de eucalipto son colgantes)
		for i in 8:
			var y := -28.0 + float(i) * 7.0
			var x_off := 10.0 + sin(float(i) * 0.8 + _t) * 4.0
			draw_line(Vector2(0, y), Vector2(-x_off, y + 8), Color(0.60, 0.72, 0.62), 2.0)
			draw_line(Vector2(0, y), Vector2( x_off, y + 8), Color(0.60, 0.72, 0.62), 2.0)
			# Hojas ovaladas plateadas-verdes
			draw_circle(Vector2(-x_off - 4, y + 10), 5.5, Color(0.58, 0.70, 0.60, 0.85))
			draw_circle(Vector2( x_off + 4, y + 10), 5.5, Color(0.58, 0.70, 0.60, 0.85))
		# Cruz roja de "especie invasiva"
		draw_line(Vector2(-18, -36), Vector2(18, -8), Color(0.88, 0.15, 0.15, 0.70), 3.0)
		draw_line(Vector2(-18, -8), Vector2(18, -36), Color(0.88, 0.15, 0.15, 0.70), 3.0)

	func _pino() -> void:
		# Tronco
		draw_rect(Rect2(-4, 18, 8, 18), Color(0.42, 0.28, 0.14))
		# Capas del pino (triángulos superpuestos)
		var capas := [
			{"y": 18.0, "w": 28.0}, {"y": 4.0,  "w": 22.0},
			{"y": -8.0, "w": 18.0}, {"y": -20.0,"w": 13.0},
		]
		for capa in capas:
			var pts := PackedVector2Array([
				Vector2(-(capa["w"] as float), capa["y"] as float),
				Vector2( (capa["w"] as float), capa["y"] as float),
				Vector2(0.0, (capa["y"] as float) - 18.0)
			])
			draw_colored_polygon(pts, Color(0.10, 0.30, 0.14))
			draw_line(pts[0], pts[2], Color(0.15, 0.40, 0.18), 1.5)
			draw_line(pts[1], pts[2], Color(0.15, 0.40, 0.18), 1.5)
		# Punta de la copa
		var top_pts := PackedVector2Array([
			Vector2(-9, -20), Vector2(9, -20), Vector2(0, -36)
		])
		draw_colored_polygon(top_pts, Color(0.10, 0.28, 0.12))
		# Nieve en punta (clima frío, especie foránea)
		draw_circle(Vector2(0, -34), 6.5, Color(0.92, 0.94, 0.96, 0.90))
		draw_arc(Vector2(-22, 4), 6.0, PI, TAU, 8, Color(0.90, 0.93, 0.96, 0.80), 8.0)
		draw_arc(Vector2( 22, 4), 6.0, PI, TAU, 8, Color(0.90, 0.93, 0.96, 0.80), 8.0)

	func _rosa() -> void:
		# Tallo con espinas
		draw_line(Vector2(0, 34), Vector2(0, -12), Color(0.18, 0.48, 0.14), 3.0)
		for i in 4:
			var y := 28.0 - float(i) * 10.0
			draw_line(Vector2(0, y), Vector2(6 if i%2 == 0 else -6, y - 5),
					  Color(0.18, 0.48, 0.14), 1.5)
		# Hojas
		draw_circle(Vector2(-10, 10), 8.0, Color(0.20, 0.55, 0.16))
		draw_circle(Vector2( 10, 10), 8.0, Color(0.20, 0.55, 0.16))
		# Pétalos rosa/rojo
		for i in 7:
			var a := float(i) / 7.0 * TAU
			draw_circle(Vector2(cos(a) * 10, sin(a) * 10 - 14), 9.0, Color(0.85, 0.12, 0.22, 0.90))
		# Centro de la rosa
		draw_circle(Vector2(0, -14), 7.0, Color(0.70, 0.08, 0.18))
		draw_circle(Vector2(0, -14), 3.5, Color(0.95, 0.50, 0.55))

	func _bambu() -> void:
		# 3 cañas de bambú (altas y apretadas → visualmente obstructivo)
		var canas := [Vector2(-10, 0), Vector2(0, 0), Vector2(10, 0)]
		for c in canas:
			draw_rect(Rect2((c as Vector2).x - 4, -36, 8, 70),
					  Color(0.20 + (c as Vector2).x * 0.005, 0.58, 0.18))
			# Nodos del bambú cada 12px
			for n in 5:
				var ynb := -32.0 + float(n) * 14.0
				draw_rect(Rect2((c as Vector2).x - 5, ynb, 10, 3),
						  Color(0.15, 0.45, 0.12))
		# Hojas en las cimas
		var leaf_positions := [Vector2(-20, -34), Vector2(0, -36), Vector2(20, -34),
							   Vector2(-12, -26), Vector2(12, -26)]
		for lp in leaf_positions:
			draw_circle(lp as Vector2, 7.0, Color(0.18, 0.60, 0.15, 0.85))

	func _helecho() -> void:
		# Pasto San Agustín (fondo verde bajo)
		var pts_grass := PackedVector2Array([
			Vector2(-36, 34), Vector2(36, 34), Vector2(36, 20), Vector2(-36, 20)
		])
		draw_colored_polygon(pts_grass, Color(0.22, 0.58, 0.16))
		# Briznas de pasto
		for i in 12:
			var gx := -32.0 + float(i) * 6.0
			draw_line(Vector2(gx, 20), Vector2(gx + sin(float(i)) * 4, 8),
					  Color(0.25, 0.68, 0.18), 2.0)
		# Helechos (palmas con hojas pinnadas)
		var centros := [Vector2(-14, 10), Vector2(14, 10), Vector2(0, 4)]
		for centro in centros:
			var cp := centro as Vector2
			# Pecíolo principal
			draw_line(cp, cp + Vector2(0, -18), Color(0.18, 0.52, 0.14), 2.5)
			# Pinas (hojillas) alternadas
			for n in 7:
				var y := -4.0 - float(n) * 2.5
				var xl := cp.x - 4.0 - float(n) * 0.8
				var xr := cp.x + 4.0 + float(n) * 0.8
				draw_circle(Vector2(xl, cp.y + y), 3.0, Color(0.20, 0.60, 0.18, 0.88))
				draw_circle(Vector2(xr, cp.y + y), 3.0, Color(0.20, 0.60, 0.18, 0.88))

	func _generico() -> void:
		draw_circle(Vector2(0, -10), 20.0, Color(0.20, 0.60, 0.20))
		draw_rect(Rect2(-4, 5, 8, 28), Color(0.42, 0.26, 0.10))

# ── Inner class: suelo animado ────────────────────────────────
class SueloVisual extends Node2D:
	var _t          : float  = 0.0
	var plantada    : bool   = false
	var tipo_planta : String = ""

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# Fondo de tierra
		var pts := PackedVector2Array()
		for i in 36:
			var a := float(i) / 36.0 * TAU
			pts.append(Vector2(cos(a) * 64, sin(a) * 28))
		draw_colored_polygon(pts, Color(0.35, 0.22, 0.09))
		# Textura de tierra
		draw_arc(Vector2(0, 0), 60.0, 0.0, TAU, 36, Color(0.25, 0.14, 0.05), 4.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for _i in 20:
			var px := rng.randf_range(-54.0, 54.0)
			var py := rng.randf_range(-20.0, 20.0)
			draw_circle(Vector2(px, py), rng.randf_range(2.0, 5.0),
						Color(0.25, 0.14, 0.06, 0.55))
		# Hoyo central
		if not plantada:
			var puls := 1.0 + 0.15 * sin(_t * 3.5)
			draw_circle(Vector2(0, 0), 14.0 * puls, Color(0.18, 0.10, 0.03))
			draw_arc(Vector2(0, 0), 15.0 * puls, 0.0, TAU, 20,
					 Color(0.55, 0.88, 0.25, 0.5 + 0.3 * sin(_t * 2.0)), 2.0)
			# Flechas indicadoras de "plantar aquí"
			var arrow_a := _t * 0.8
			for j in 3:
				var a := arrow_a + float(j) / 3.0 * TAU
				var p := Vector2(cos(a) * 22, sin(a) * 22)
				draw_arc(p, 5.0, a + PI * 0.5, a + PI * 1.5, 8,
						 Color(0.45, 0.88, 0.25, 0.55), 2.0)
		else:
			# Planta creciendo
			var scale_y := minf(_t * 0.8, 1.0)
			var ga := 0.12 + 0.08 * sin(_t * 2.0)
			draw_circle(Vector2(0, -20), 30.0, Color(0.20, 0.80, 0.25, ga))

# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("mision_plantar")
	_crear_ui()
	hide()


func iniciar(indice: int, zona_node: Area2D) -> void:
	_mision_idx   = clampi(indice, 0, MISIONES.size() - 1)
	_zona_ref     = zona_node
	_seleccion_ok = false
	_feedback_panel.visible = false
	for c in _cartas:
		_resetear_carta(c)
	_poblar_datos()
	show()
	# Hint contextual
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_plantar",
			"🌱 Elige la planta correcta para esta zona según los criterios de sostenibilidad.")


# ── Poblar con datos del mision_idx actual ───────────────────
func _poblar_datos() -> void:
	var m : Dictionary = MISIONES[_mision_idx]
	_mision_id = m["id"]

	_zona_lbl.text      = "%s  %s" % [m["icono"], m["zona"]]
	_contexto_lbl.text  = m["contexto"]
	_criterio_lbl.text  = "📋 " + m["criterio"]

	# Progreso nivel 1
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(1) if nm else 0.0
	_pct_lbl.text = "NIVEL 1  ·  %.0f%% completado" % (pct * 100.0)

	var plantas : Array = m["plantas"]
	for i in _cartas.size():
		var carta : Panel = _cartas[i]
		if i >= plantas.size(): continue
		var pdata : Dictionary = plantas[i]
		_configurar_carta(carta, pdata["id"], pdata["nombre"], pdata["desc"],
						  pdata["id"] == m["correcta"])


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -PANEL_W * 0.5
	_panel_root.offset_top    = -PANEL_H * 0.5
	_panel_root.offset_right  =  PANEL_W * 0.5
	_panel_root.offset_bottom =  PANEL_H * 0.5
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.06, 0.98)
	ps.border_color = Color(0.20, 0.80, 0.25)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja verde superior
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.22, 0.88, 0.30, 0.80)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(key, 22)
	_panel_root.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	mg.add_child(vbox)

	# ── Encabezado ────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var btn_salir := Button.new()
	btn_salir.text = "← Salir"
	btn_salir.custom_minimum_size = Vector2(80, 32)
	btn_salir.add_theme_font_size_override("font_size", 12)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bs.border_color = Color(0.65, 0.15, 0.15)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(8)
	btn_salir.add_theme_stylebox_override("normal", bs)
	btn_salir.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
	btn_salir.pressed.connect(_on_salir)
	header.add_child(btn_salir)

	_zona_lbl = Label.new()
	_zona_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zona_lbl.add_theme_font_size_override("font_size", 19)
	_zona_lbl.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	header.add_child(_zona_lbl)

	_nivel_badge = Label.new()
	_nivel_badge.text = "🌿 NIVEL 1"
	_nivel_badge.add_theme_font_size_override("font_size", 12)
	_nivel_badge.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	header.add_child(_nivel_badge)

	# Separador
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.35)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# ── Fila de contenido ─────────────────────────────────────
	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 18)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_row)

	# Columna izquierda: contexto + suelo
	var col_izq := VBoxContainer.new()
	col_izq.custom_minimum_size   = Vector2(230, 0)
	col_izq.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.add_theme_constant_override("separation", 10)
	content_row.add_child(col_izq)

	_contexto_lbl = Label.new()
	_contexto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_contexto_lbl.add_theme_font_size_override("font_size", 12)
	_contexto_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	col_izq.add_child(_contexto_lbl)

	_criterio_lbl = Label.new()
	_criterio_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_criterio_lbl.add_theme_font_size_override("font_size", 11)
	_criterio_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 0.60))
	col_izq.add_child(_criterio_lbl)

	# Contenedor visual del suelo
	var suelo_cont := Control.new()
	suelo_cont.custom_minimum_size   = Vector2(140, 100)
	suelo_cont.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	suelo_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.add_child(suelo_cont)

	_suelo_node = SueloVisual.new()
	_suelo_node.position = Vector2(70, 50)
	suelo_cont.add_child(_suelo_node)

	_pct_lbl = Label.new()
	_pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pct_lbl.add_theme_font_size_override("font_size", 11)
	_pct_lbl.add_theme_color_override("font_color", Color(0.40, 0.80, 0.45))
	col_izq.add_child(_pct_lbl)

	# Separador vertical
	var vsep := VSeparator.new()
	var vss := StyleBoxFlat.new()
	vss.bg_color = Color(0.22, 0.72, 0.22, 0.30)
	vss.content_margin_left = 1.0
	vsep.add_theme_stylebox_override("separator", vss)
	content_row.add_child(vsep)

	# Columna derecha: cuadrícula de plantas
	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.add_theme_constant_override("separation", 10)
	content_row.add_child(col_der)

	var instruccion := Label.new()
	instruccion.text = "🔍  Selecciona la planta más adecuada para esta zona:"
	instruccion.add_theme_font_size_override("font_size", 13)
	instruccion.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88))
	col_der.add_child(instruccion)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col_der.add_child(grid)

	_cartas = []
	for _i in 4:
		var carta := _crear_carta()
		grid.add_child(carta)
		_cartas.append(carta)

	# ── Panel de feedback (oculto) ────────────────────────────
	_crear_panel_feedback()


func _crear_carta() -> Panel:
	var carta := Panel.new()
	carta.custom_minimum_size = Vector2(CARTA_W, CARTA_H)
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.06, 0.12, 0.08, 0.95)
	cs.border_color = Color(0.20, 0.55, 0.22)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(12)
	cs.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	cs.shadow_size  = 6
	carta.add_theme_stylebox_override("panel", cs)
	carta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	carta.gui_input.connect(_on_carta_input.bind(carta))

	# Zona de ilustración de la planta
	var visual_cont := Control.new()
	visual_cont.set_anchors_preset(Control.PRESET_TOP_WIDE)
	visual_cont.custom_minimum_size = Vector2(0, 110)
	visual_cont.offset_bottom = 110.0
	visual_cont.clip_contents = true
	carta.add_child(visual_cont)

	var pv := PlantaVisual.new()
	pv.position = Vector2(CARTA_W * 0.5, 72)
	visual_cont.add_child(pv)
	carta.set_meta("planta_visual", pv)

	# Nombre de la planta
	var nombre_lbl := Label.new()
	nombre_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nombre_lbl.offset_top    = -70.0
	nombre_lbl.offset_bottom = -44.0
	nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_lbl.add_theme_font_size_override("font_size", 12)
	nombre_lbl.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	carta.add_child(nombre_lbl)
	carta.set_meta("nombre_lbl", nombre_lbl)

	# Descripción
	var desc_lbl := Label.new()
	desc_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	desc_lbl.offset_top    = -44.0
	desc_lbl.offset_bottom = -6.0
	desc_lbl.offset_left   = 6.0
	desc_lbl.offset_right  = -6.0
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.60, 0.72, 0.62))
	carta.add_child(desc_lbl)
	carta.set_meta("desc_lbl", desc_lbl)

	carta.set_meta("planta_id",  "")
	carta.set_meta("es_correcta", false)
	return carta


func _configurar_carta(carta: Panel, pid: String, nombre: String,
					   desc: String, es_correcta: bool) -> void:
	carta.set_meta("planta_id",   pid)
	carta.set_meta("es_correcta", es_correcta)
	(carta.get_meta("nombre_lbl") as Label).text = nombre
	(carta.get_meta("desc_lbl") as Label).text   = desc
	(carta.get_meta("planta_visual") as PlantaVisual).tipo = pid


func _resetear_carta(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.12, 0.08, 0.95)
	ps.border_color = Color(0.20, 0.55, 0.22)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	ps.shadow_size  = 6
	carta.add_theme_stylebox_override("panel", ps)
	carta.modulate = Color.WHITE


func _on_carta_input(event: InputEvent, carta: Panel) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
	if _seleccion_ok: return
	_procesar_seleccion(carta)


func _procesar_seleccion(carta: Panel) -> void:
	var pid        : String = carta.get_meta("planta_id")
	var es_ok      : bool   = carta.get_meta("es_correcta")
	var m          : Dictionary = MISIONES[_mision_idx]
	var feedback_txt : String = m["feedback"].get(pid, "Respuesta no reconocida.")

	if es_ok:
		_seleccion_ok = true
		_animar_carta_ok(carta)
		(_suelo_node as SueloVisual).plantada = true
		_mostrar_feedback(true, "¡Planta correcta!", feedback_txt)
		_completar_mision()
	else:
		_animar_carta_mal(carta)
		_mostrar_feedback(false, "Planta incorrecta", feedback_txt)


func _animar_carta_ok(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.28, 0.10, 0.98)
	ps.border_color = Color(0.22, 0.90, 0.28)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(12)
	carta.add_theme_stylebox_override("panel", ps)
	var tw := carta.create_tween()
	tw.tween_property(carta, "scale", Vector2(1.06, 1.06), 0.10)
	tw.tween_property(carta, "scale", Vector2(1.0,  1.0),  0.10)


func _animar_carta_mal(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.20, 0.04, 0.04, 0.98)
	ps.border_color = Color(0.88, 0.18, 0.18)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(12)
	carta.add_theme_stylebox_override("panel", ps)
	var tw := carta.create_tween()
	tw.tween_property(carta, "position:x", carta.position.x + 6, 0.06)
	tw.tween_property(carta, "position:x", carta.position.x - 6, 0.06)
	tw.tween_property(carta, "position:x", carta.position.x, 0.06)


func _crear_panel_feedback() -> void:
	_feedback_panel = Panel.new()
	_feedback_panel.set_anchors_preset(Control.PRESET_CENTER)
	_feedback_panel.custom_minimum_size = Vector2(560, 220)
	_feedback_panel.offset_left   = -280.0
	_feedback_panel.offset_top    = -110.0
	_feedback_panel.offset_right  =  280.0
	_feedback_panel.offset_bottom =  110.0
	_feedback_panel.visible       = false
	var fps := StyleBoxFlat.new()
	fps.bg_color     = Color(0.04, 0.06, 0.04, 0.98)
	fps.border_color = Color(0.22, 0.82, 0.28)
	fps.set_border_width_all(3)
	fps.set_corner_radius_all(16)
	fps.shadow_color = Color(0.10, 0.55, 0.18, 0.60)
	fps.shadow_size  = 20
	_feedback_panel.add_theme_stylebox_override("panel", fps)
	add_child(_feedback_panel)

	var fmg := MarginContainer.new()
	fmg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		fmg.add_theme_constant_override(k, 24)
	_feedback_panel.add_child(fmg)

	var fvbox := VBoxContainer.new()
	fvbox.add_theme_constant_override("separation", 12)
	fmg.add_child(fvbox)

	_fb_icono = Label.new()
	_fb_icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_icono.add_theme_font_size_override("font_size", 36)
	fvbox.add_child(_fb_icono)

	_fb_titulo = Label.new()
	_fb_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_titulo.add_theme_font_size_override("font_size", 18)
	_fb_titulo.add_theme_color_override("font_color", Color.WHITE)
	fvbox.add_child(_fb_titulo)

	_fb_desc = Label.new()
	_fb_desc.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_fb_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_desc.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	_fb_desc.add_theme_font_size_override("font_size", 13)
	_fb_desc.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82))
	fvbox.add_child(_fb_desc)

	_fb_btn = Button.new()
	_fb_btn.text = "  Continuar  ▶  "
	_fb_btn.custom_minimum_size = Vector2(200, 44)
	_fb_btn.add_theme_font_size_override("font_size", 14)
	var fbs := StyleBoxFlat.new()
	fbs.bg_color     = Color(0.06, 0.34, 0.08)
	fbs.border_color = Color(0.22, 0.84, 0.22)
	fbs.set_border_width_all(2)
	fbs.set_corner_radius_all(12)
	_fb_btn.add_theme_stylebox_override("normal", fbs)
	_fb_btn.pressed.connect(_on_feedback_continuar)
	fvbox.add_child(_fb_btn)


func _mostrar_feedback(correcto: bool, titulo: String, desc: String) -> void:
	_fb_icono.text  = "🌱" if correcto else "❌"
	_fb_titulo.text = titulo
	_fb_titulo.add_theme_color_override("font_color",
		Color(0.30, 0.95, 0.35) if correcto else Color(0.95, 0.35, 0.30))
	_fb_desc.text   = desc
	_fb_btn.text    = "  ¡Completado!  🎉  " if correcto else "  Intentar de nuevo  "

	_feedback_panel.modulate.a = 0.0
	_feedback_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_feedback_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_feedback_panel, "scale",
		Vector2(1.0, 1.0), 0.22).from(Vector2(0.85, 0.85))


func _on_feedback_continuar() -> void:
	_feedback_panel.visible = false
	if _seleccion_ok:
		_cerrar()


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(1, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completada"):
		_zona_ref._marcar_completada()
	var xp : int = int(nm.XP_POR_MISION.get(1, 40)) if nm else 40
	var ec : int = int(nm.EC_POR_MISION.get(1, 15)) if nm else 15
	mision_completada_plantar.emit(_mision_id, xp, ec)


func _on_salir() -> void:
	_cerrar()


func _cerrar() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)
