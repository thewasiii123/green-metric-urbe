# ============================================================
# mapa_campus.gd — URBE Rangers: Eco-Quest
# Posiciones alineadas a cuadrícula 16px.
# Pasillos horizontales: 32px entre filas (2 tiles).
# ============================================================
extends Node2D

# ── Ambiente: pájaros y shimmer del lago ─────────────────────
var _t_mapa  : float = 0.0
var _pajaros : Array = []   # [{x, y, vx, f, wing_f}]
var _destellos : Array = [] # [{x, y, fase}] reflejos en el lago

func _ready() -> void:
	for i in 6:
		_pajaros.append({
			"x": randf_range(0.0, 1408.0),
			"y": randf_range(18.0, 135.0),
			"vx": randf_range(35.0, 75.0),
			"f": randf_range(0.0, TAU),
			"wf": randf_range(5.0, 10.0),
		})
	for i in 12:
		_destellos.append({
			"x": randf_range(40.0, 1368.0),
			"y": randf_range(30.0, 140.0),
			"f": randf_range(0.0, TAU),
		})

func _process(delta: float) -> void:
	_t_mapa += delta
	for p in _pajaros:
		p["x"] = float(p["x"]) + float(p["vx"]) * delta
		if float(p["x"]) > 1430.0:
			p["x"] = -15.0
			p["y"] = randf_range(18.0, 135.0)
	queue_redraw()

var impacto : Dictionary = {
	1: 0.35,   # Entorno e Infraestructura
	2: 0.40,   # Energía
	3: 0.30,   # Residuos
	4: 0.45,   # Agua
	5: 0.22,   # Transporte
	6: 0.55,   # Educación
}

func actualizar_modulo(modulo_id: int, nuevo_progreso: float) -> void:
	impacto[modulo_id] = clampf(nuevo_progreso, 0.0, 1.0)
	queue_redraw()

func _color_edif(modulo_id: int, base: Color) -> Color:
	if not impacto.has(modulo_id):
		return base
	var pct : float = impacto[modulo_id]
	if pct < 0.40:
		return base.lerp(Color(0.72, 0.18, 0.18), 0.38)
	elif pct < 0.75:
		return base.lerp(Color(0.72, 0.58, 0.08), 0.28)
	else:
		return base.lerp(Color(0.18, 0.62, 0.18), 0.35)

func _color_indicador(modulo_id: int) -> Color:
	if not impacto.has(modulo_id):
		return Color.TRANSPARENT
	var pct : float = impacto[modulo_id]
	if pct < 0.40:   return Color(0.90, 0.18, 0.18)
	elif pct < 0.75: return Color(0.92, 0.72, 0.08)
	else:            return Color(0.18, 0.85, 0.18)


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# ── Paleta ───────────────────────────────────────────────
	var C_CESPED   := Color(0.22, 0.48, 0.22)
	var C_CESPED2  := Color(0.18, 0.42, 0.18)
	var C_LAGO     := Color(0.08, 0.42, 0.78)
	var C_ORILLA   := Color(0.55, 0.45, 0.25)
	var C_CAMINO   := Color(0.80, 0.66, 0.40)
	var C_CAMINO2  := Color(0.64, 0.50, 0.26)
	var C_PLAZA    := Color(0.28, 0.56, 0.28)
	var C_EDIF     := Color(0.52, 0.38, 0.28)
	var C_EDIF_VIP := Color(0.36, 0.22, 0.12)
	var C_TECHO    := Color(0.28, 0.14, 0.06)
	var C_ESTAC    := Color(0.32, 0.40, 0.46)
	var C_LINEA    := Color(0.52, 0.62, 0.68)
	var C_TEXTO    := Color.WHITE
	var C_AMARILLO := Color(0.97, 0.80, 0.10)
	var C_AZUL_OS  := Color(0.06, 0.16, 0.44)
	var C_CAFETIN  := Color(0.38, 0.28, 0.10)

	# ── FONDO CÉSPED ─────────────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 768), C_CESPED)
	for gy in range(0, 768, 32):
		draw_rect(Rect2(0, gy, 1408, 16), C_CESPED2)

	# ── LAGO NORTE  y=0..160 ─────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 160), C_LAGO)
	for ox in range(0, 1408, 140):
		draw_arc(Vector2(ox + 70, 110), 36, 0.0, PI, 20, Color(1,1,1,0.10), 2.5)
	draw_rect(Rect2(0, 155, 1408, 8), C_ORILLA)
	draw_circle(Vector2(250,  80), 8, Color(0.90, 0.85, 0.60))
	draw_circle(Vector2(900,  70), 8, Color(0.90, 0.85, 0.60))
	draw_circle(Vector2(1200, 90), 8, Color(0.90, 0.85, 0.60))
	_draw_str(font, "Lago URBE / Área Deportiva Norte",
			  Vector2(704, 88), Color(1,1,1,0.55), 9)

	# ── CAMINO SUPERIOR HORIZONTAL  y=176..208 (32px) ────────
	draw_rect(Rect2(0, 176, 1408, 32), C_CAMINO)
	draw_rect(Rect2(0, 176, 1408,  2), C_CAMINO2)
	draw_rect(Rect2(0, 206, 1408,  2), C_CAMINO2)

	# ── CAMINO VERTICAL IZQUIERDO  x=192..240 (48px) ─────────
	draw_rect(Rect2(192, 208, 48, 496), C_CAMINO)
	draw_rect(Rect2(192, 208,  2, 496), C_CAMINO2)
	draw_rect(Rect2(238, 208,  2, 496), C_CAMINO2)

	# ── CAMINO VERTICAL CENTRO-IZQ  x=416..464 (48px) ────────
	draw_rect(Rect2(416, 208, 48, 496), C_CAMINO)
	draw_rect(Rect2(416, 208,  2, 496), C_CAMINO2)
	draw_rect(Rect2(462, 208,  2, 496), C_CAMINO2)

	# ── CAMINO VERTICAL DERECHO  x=1104..1152 (48px) ─────────
	draw_rect(Rect2(1104, 208, 48, 496), C_CAMINO)
	draw_rect(Rect2(1104, 208,  2, 496), C_CAMINO2)
	draw_rect(Rect2(1150, 208,  2, 496), C_CAMINO2)

	# ── PASILLOS HORIZONTALES ENTRE FILAS (32px cada uno) ────
	draw_rect(Rect2(0, 368, 1152, 32), C_CAMINO)    # fila 1 → fila 2  (y=368..400)
	draw_rect(Rect2(0, 576, 1152, 32), C_CAMINO)    # fila 2 → fila 3  (y=576..608)

	# ── AVENIDA PRINCIPAL  y=704..768 ────────────────────────
	draw_rect(Rect2(0, 704, 1408, 64), C_CAMINO)
	draw_rect(Rect2(0, 704, 1408,  3), C_CAMINO2)
	draw_rect(Rect2(0, 765, 1408,  3), C_CAMINO2)
	for lx in range(0, 1408, 60):
		draw_rect(Rect2(lx, 733, 30, 4), Color(0.95, 0.88, 0.30, 0.70))

	# ── PLAZA CENTRAL (este de BloqE y BloqB) ────────────────
	draw_rect(Rect2(848, 208, 256, 496), C_PLAZA)
	for gy in range(208, 704, 28):
		draw_rect(Rect2(848, gy, 256, 14), C_CESPED2)
	draw_rect(Rect2(832, 400, 16, 176), C_CESPED)   # paso BloqA↔BloqB (actualizado a y=400)

	# Fuente central
	var FC := Vector2(976, 456)
	draw_circle(FC, 40, Color(0.06, 0.28, 0.62))
	draw_arc(FC, 40, 0.0, TAU, 32, Color(0.30, 0.70, 0.95), 3.0)
	draw_circle(FC, 24, Color(0.12, 0.45, 0.82))
	draw_arc(FC, 7, 0.0, TAU, 12, Color(0.70, 0.92, 1.0), 2.0)
	_draw_str(font, "Plaza Central", FC + Vector2(0, 54), Color(1,1,1,0.80), 8)

	for ap in [Vector2(880, 240), Vector2(880, 340), Vector2(880, 440), Vector2(880, 540),
			   Vector2(1060, 240), Vector2(1060, 340), Vector2(1060, 440), Vector2(1060, 540)]:
		draw_circle(ap, 15, Color(0.14, 0.38, 0.14))
		draw_circle(ap - Vector2(4,4), 6, Color(0.22, 0.54, 0.18))

	# ── FILA 1  y=208..368 ───────────────────────────────────

	# ESTACIONAMIENTO M5  x=0..192  y=208..368
	var c_estac := _color_edif(5, C_ESTAC)
	draw_rect(Rect2(0, 208, 192, 160), c_estac)
	for i in range(1, 5):
		draw_line(Vector2(i*48, 208), Vector2(i*48, 368), C_LINEA, 1.5)
	draw_line(Vector2(0, 288), Vector2(192, 288), C_LINEA, 1.5)
	draw_rect(Rect2(0, 208, 192, 160), C_TECHO, false, 2.0)
	_txt(font, "P",         Rect2(0,  208, 48, 160), C_AMARILLO, 28)
	_txt(font, "Estac.\nM5", Rect2(48, 208, 144, 160), C_TEXTO, 10)
	_dibujar_indicador(Vector2(182, 218), 5)

	# CAFETÍN M3  x=240..416  y=208..368
	_edif(font, Rect2(240, 208, 176, 160), "Cafetín\nM3",
		_color_edif(3, C_CAFETIN), C_TECHO, C_TEXTO, 3)
	draw_rect(Rect2(244, 210, 12, 14), Color(0.08, 0.28, 0.68))
	draw_rect(Rect2(260, 210, 12, 14), Color(0.62, 0.48, 0.05))
	draw_rect(Rect2(276, 210, 12, 14), Color(0.14, 0.50, 0.14))

	# BIBLIOTECA M4  x=464..672  y=208..368
	_edif(font, Rect2(464, 208, 208, 160), "Biblioteca\nM4",
		_color_edif(4, C_EDIF_VIP), C_TECHO, C_TEXTO, 4)

	# BLOQUE E M2  x=688..848  y=208..368
	_edif(font, Rect2(688, 208, 160, 160), "Bloque E\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# BLOQUE F M1  x=1152..1408  y=208..576
	_edif(font, Rect2(1152, 208, 256, 368), "Bloque F\nM1",
		_color_edif(1, C_EDIF_VIP), C_TECHO, C_TEXTO, 1)

	# ── FILA 2  y=400..576  (pasillo 32px arriba y abajo) ────

	# BLOQUE G M1  x=0..192  y=400..576
	_edif(font, Rect2(0, 400, 192, 176), "Bloque G\nM1",
		_color_edif(1, C_EDIF), C_TECHO, C_TEXTO, 1)

	# BLOQUE D M2  x=240..416  y=400..576
	_edif(font, Rect2(240, 400, 176, 176), "Bloque D\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# BLOQUE A M2  x=464..640  y=400..576
	_edif(font, Rect2(464, 400, 176, 176), "Bloque A\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# BLOQUE B M2  x=656..832  y=400..576
	_edif(font, Rect2(656, 400, 176, 176), "Bloque B\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# ── FILA 3  y=608..704  (pasillo 32px arriba, avda abajo) ─

	# FOTOCOPIADO M1  x=0..144  y=608..704
	_edif(font, Rect2(0, 608, 144, 96), "Fotoc.\nM1",
		_color_edif(1, C_EDIF), C_TECHO, C_TEXTO, 1)

	# BLOQUE C M2  x=240..400  y=608..704
	_edif(font, Rect2(240, 608, 160, 96), "Bloque C\nM2",
		_color_edif(2, C_EDIF), C_TECHO, C_TEXTO, 2)

	# RECTORADO M6  x=464..880  y=608..704
	_edif(font, Rect2(464, 608, 416, 96), "Rectorado / Auditorio   M6",
		_color_edif(6, C_EDIF_VIP), C_TECHO, C_TEXTO, 6)

	# ÁREA SERVICIOS M6  x=1152..1408  y=608..704
	_edif(font, Rect2(1152, 608, 256, 96), "Área Servicios\nM6",
		_color_edif(6, C_EDIF_VIP), C_TECHO, C_TEXTO, 6)

	# ── ÁRBOLES LATERALES ────────────────────────────────────
	for a in [
		Vector2(168, 296), Vector2(168, 384),   # izq fila1 / pasillo 1→2
		Vector2(168, 488), Vector2(168, 592),   # izq fila2 / pasillo 2→3
		Vector2(168, 656),                       # izq fila3
		Vector2(392, 296), Vector2(392, 384),
		Vector2(392, 488), Vector2(392, 592),
		Vector2(392, 656),
		Vector2(1080, 296), Vector2(1080, 488), Vector2(1080, 656)
	]:
		draw_circle(a, 13, Color(0.14, 0.38, 0.14))
		draw_circle(a - Vector2(3,3), 5, Color(0.22, 0.54, 0.18))

	# ── CONTENEDORES DE RECICLAJE ────────────────────────────
	_dibujar_contenedores(font)

	# ── PÁJAROS AMBIENTALES ──────────────────────────────────
	for p in _pajaros:
		var bx  : float = float(p["x"])
		var by  : float = float(p["y"]) + sin(_t_mapa * float(p["wf"]) * 0.5 + float(p["f"])) * 2.5
		var wing : float = 4.5 + sin(_t_mapa * float(p["wf"]) + float(p["f"])) * 3.0
		var bird_col := Color(0.08, 0.08, 0.10, 0.70)
		draw_line(Vector2(bx - wing, by - wing * 0.5), Vector2(bx, by), bird_col, 1.3)
		draw_line(Vector2(bx, by), Vector2(bx + wing, by - wing * 0.5), bird_col, 1.3)

	# ── REFLEJOS DEL LAGO ────────────────────────────────────
	for d in _destellos:
		var dx  : float = float(d["x"])
		var dy  : float = float(d["y"])
		var df  : float = float(d["f"])
		var a   : float = 0.08 + 0.07 * sin(_t_mapa * 1.3 + df)
		var len : float = 12.0 + 6.0 * sin(_t_mapa * 0.9 + df * 1.7)
		draw_line(Vector2(dx - len, dy), Vector2(dx + len, dy),
				  Color(0.75, 0.92, 1.0, a), 1.5)

	# ── SEÑAL DE ENTRADA ─────────────────────────────────────
	draw_rect(Rect2(580, 714, 144, 42), C_TECHO)
	draw_rect(Rect2(583, 717, 138, 36), C_AZUL_OS)
	draw_rect(Rect2(583, 717, 138, 36), C_AMARILLO, false, 2.0)
	_draw_str(font, "ENTRADA URBE", Vector2(652, 738), C_TEXTO, 9)

	draw_circle(Vector2(744, 736), 22, C_AMARILLO)
	draw_arc(Vector2(744, 736), 22, 0.0, TAU, 32, C_TECHO, 2.5)
	_draw_str(font, "URBE", Vector2(744, 740), C_AZUL_OS, 9)


# ── CONTENEDORES DE RECICLAJE ─────────────────────────────
# 5 contenedores por cluster: orgánico(café) plástico(amarillo)
# papel(azul) vidrio(verde) general(gris)
func _dibujar_contenedores(font: Font) -> void:
	var spots : Array = [
		Vector2(248, 350),   # Cafetín (pasillo fila1, frente sur)
		Vector2(696, 350),   # Bloque E (pasillo fila1, frente sur)
		Vector2(470, 350),   # Biblioteca (pasillo fila1, frente sur)
		Vector2(248, 582),   # Bloque D (pasillo fila2, frente sur)
		Vector2(470, 582),   # Bloque A (pasillo fila2, frente sur)
		Vector2(72,  582),   # Bloque G (pasillo fila2, frente sur)
		Vector2(150, 714),   # Fotocopiado (avenida norte)
		Vector2(550, 714),   # Rectorado (avenida norte)
		Vector2(940, 508),   # Plaza Central (junto a fuente)
	]
	for sp in spots:
		_cluster_contenedor(sp, font)


func _cluster_contenedor(pos: Vector2, font: Font) -> void:
	var colores : Array = [
		Color(0.40, 0.20, 0.05),   # orgánico  (café)
		Color(0.94, 0.78, 0.04),   # plástico  (amarillo)
		Color(0.08, 0.25, 0.80),   # papel     (azul)
		Color(0.10, 0.62, 0.18),   # vidrio    (verde)
		Color(0.52, 0.52, 0.52),   # general   (gris)
	]
	var W : float = 7.0
	var H : float = 11.0
	var GAP : float = 1.5
	var total_w : float = colores.size() * W + (colores.size() - 1) * GAP
	var x0 : float = pos.x - total_w * 0.5
	for i in range(colores.size()):
		var cx : float = x0 + i * (W + GAP)
		draw_rect(Rect2(cx, pos.y, W, H), colores[i])
		draw_rect(Rect2(cx, pos.y, W, H), Color(0,0,0,0.7), false, 0.8)
		# tapa
		draw_rect(Rect2(cx - 0.5, pos.y - 2.5, W + 1, 3.5), colores[i].darkened(0.25))
		draw_rect(Rect2(cx - 0.5, pos.y - 2.5, W + 1, 3.5), Color(0,0,0,0.5), false, 0.6)
	# etiqueta ♻
	_draw_str(font, "♻", pos + Vector2(0, -8), Color(1,1,1,0.65), 7)


# ── HELPERS DE DIBUJO ─────────────────────────────────────

func _dibujar_indicador(pos: Vector2, modulo_id: int) -> void:
	var col := _color_indicador(modulo_id)
	if col == Color.TRANSPARENT:
		return
	draw_circle(pos, 6, col)
	draw_arc(pos, 6, 0.0, TAU, 16, Color(0,0,0,0.5), 1.5)


func _edif(font: Font, rect: Rect2, nombre: String,
		   color: Color, techo: Color, c_txt: Color,
		   modulo_id: int = -1) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 10)), techo)
	if rect.size.x >= 80 and rect.size.y >= 50:
		var wx : float = rect.size.x / 3.0
		for wi in range(1, 3):
			draw_rect(
				Rect2(rect.position.x + wi * wx - 6, rect.position.y + 20, 12, 10),
				Color(0.60, 0.80, 1.0, 0.5)
			)
	draw_rect(rect, techo, false, 2.5)
	_txt(font, nombre, rect, c_txt, 10)
	if modulo_id != -1:
		var ind_pos := Vector2(rect.position.x + rect.size.x - 9, rect.position.y + 18)
		_dibujar_indicador(ind_pos, modulo_id)


func _txt(font: Font, texto: String, rect: Rect2, color: Color, size: int) -> void:
	var lineas := texto.split("\n")
	var bloque : float = float(lineas.size()) * float(size + 3)
	var y0 : float = rect.position.y + (rect.size.y - bloque) * 0.5 + size + 2
	for l in lineas:
		draw_string(font, Vector2(rect.position.x, y0), l,
					HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)
		y0 += size + 3


func _draw_str(font: Font, texto: String, centro: Vector2,
			   color: Color, size: int) -> void:
	draw_string(font, centro, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)
