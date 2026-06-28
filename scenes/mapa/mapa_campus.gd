# ============================================================
# mapa_campus.gd  -  URBE Rangers: Eco-Quest
# Mapa del campus URBE dibujado proceduralmente en Godot.
# ============================================================
extends Node2D


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# ── Paleta de colores ────────────────────────────────────
	var C_CESPED   := Color(0.25, 0.52, 0.25)
	var C_CESPED2  := Color(0.20, 0.45, 0.20)  # variacion oscura
	var C_LAGO     := Color(0.09, 0.44, 0.80)
	var C_ORILLA   := Color(0.06, 0.31, 0.58)
	var C_CAMINO   := Color(0.78, 0.63, 0.36)
	var C_CAMINO2  := Color(0.68, 0.54, 0.28)  # borde camino
	var C_EDIF     := Color(0.50, 0.37, 0.29)
	var C_EDIF_VIP := Color(0.38, 0.24, 0.14)  # Rectorado, Bloque F
	var C_TECHO    := Color(0.29, 0.16, 0.08)
	var C_ESTAC    := Color(0.31, 0.40, 0.45)
	var C_LINEA    := Color(0.52, 0.62, 0.68)
	var C_TEXTO    := Color.WHITE
	var C_AMARILLO := Color(0.97, 0.79, 0.09)
	var C_AZUL_OS  := Color(0.08, 0.18, 0.46)

	# ── FONDO CÉSPED ────────────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 768), C_CESPED)

	# Textura de césped: rayas sutiles cada 32 px
	for gy in range(0, 768, 32):
		draw_rect(Rect2(0, gy, 1408, 16), C_CESPED2)

	# ── LAGO SUPERIOR ───────────────────────────────────────
	draw_rect(Rect2(0, 0, 1408, 170), C_LAGO)
	# Ondas del lago
	for ox in range(0, 1408, 120):
		draw_arc(Vector2(ox + 60, 120), 40, 0.0, PI, 20, Color(1, 1, 1, 0.10), 2.5)
	# Orilla
	draw_rect(Rect2(0, 145, 1408, 28), C_ORILLA)

	# Puente (referencia visual al puente Maracaibo)
	draw_rect(Rect2(320, 0, 20, 170), C_CAMINO)
	draw_rect(Rect2(420, 0, 20, 170), C_CAMINO)
	draw_rect(Rect2(310, 80, 140, 10), Color(0.55, 0.55, 0.55))
	draw_line(Vector2(330, 0),   Vector2(370, 80),  Color(0.60, 0.60, 0.60), 2.0)
	draw_line(Vector2(430, 0),   Vector2(390, 80),  Color(0.60, 0.60, 0.60), 2.0)
	draw_line(Vector2(330, 170), Vector2(370, 80),  Color(0.60, 0.60, 0.60), 2.0)
	draw_line(Vector2(430, 170), Vector2(390, 80),  Color(0.60, 0.60, 0.60), 2.0)

	# ── CAMINOS PRINCIPALES ──────────────────────────────────
	# Horizontal inferior (avenida principal)
	draw_rect(Rect2(0, 520, 1408, 60), C_CAMINO)
	draw_rect(Rect2(0, 520, 1408, 2),  C_CAMINO2)
	draw_rect(Rect2(0, 578, 1408, 2),  C_CAMINO2)

	# Horizontal medio (biblioteca – bloque D)
	draw_rect(Rect2(344, 306, 558, 44), C_CAMINO)
	draw_rect(Rect2(344, 306, 558, 2),  C_CAMINO2)

	# Vertical central (eje principal N-S)
	draw_rect(Rect2(485, 168, 60, 444), C_CAMINO)
	draw_rect(Rect2(485, 168, 2,  444), C_CAMINO2)
	draw_rect(Rect2(543, 168, 2,  444), C_CAMINO2)

	# Vertical derecho (bloque E – servicios)
	draw_rect(Rect2(1093, 168, 60, 398), C_CAMINO)

	# Conexión bloque D → vertical derecho
	draw_rect(Rect2(893, 424, 205, 102), C_CAMINO)

	# Zona de entrada (esquina inferior-izquierda)
	draw_rect(Rect2(0, 520, 365, 248), C_CAMINO)
	draw_rect(Rect2(343, 348, 147, 178), C_CAMINO)

	# ── ESTACIONAMIENTO M5 ──────────────────────────────────
	draw_rect(Rect2(108, 299, 246, 155), C_ESTAC)
	# Líneas de plazas
	for i in range(1, 5):
		draw_line(Vector2(108 + i * 49, 299), Vector2(108 + i * 49, 454), C_LINEA, 1.5)
	draw_line(Vector2(108, 376), Vector2(354, 376), C_LINEA, 1.5)
	# Símbolo P
	draw_rect(Rect2(108, 299, 246, 155), C_TECHO, false, 2.0)
	_txt(font, "P", Rect2(108, 299, 50, 155), C_AMARILLO, 28)
	_txt(font, "Estac. M5", Rect2(155, 299, 200, 155), C_TEXTO, 10)

	# ── EDIFICIOS ────────────────────────────────────────────
	_edif(font, Rect2(570, 175, 220, 140), "Biblioteca",      C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(864, 155, 145, 135), "Bloque E",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(1119, 300, 215, 240), "Bloque F",       C_EDIF_VIP, C_TECHO, C_TEXTO)
	_edif(font, Rect2(383, 449, 121, 85),  "Bloque A",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(505, 355, 129, 90),  "Bloque B",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(773, 345, 122, 92),  "Bloque D",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(773, 445, 122, 82),  "Bloque C",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(504, 608, 142, 92),  "Bloque G",        C_EDIF,     C_TECHO, C_TEXTO)
	_edif(font, Rect2(773, 562, 232, 156), "Rectorado",       C_EDIF_VIP, C_TECHO, C_TEXTO)
	_edif(font, Rect2(1129, 560, 257, 160), "Área\nServicios",C_EDIF_VIP, C_TECHO, C_TEXTO)
	_edif(font, Rect2(138, 420, 102, 90),  "Fotoc.",          C_EDIF,     C_TECHO, C_TEXTO)

	# ── ÁRBOLES decorativos (círculos verdes) ────────────────
	var arboles := [
		Vector2(460, 200), Vector2(510, 195), Vector2(710, 185),
		Vector2(760, 190), Vector2(810, 185), Vector2(730, 460),
		Vector2(700, 500), Vector2(650, 470), Vector2(460, 465),
		Vector2(440, 430), Vector2(680, 600), Vector2(660, 640),
		Vector2(960, 490), Vector2(1000, 500), Vector2(1050, 475),
		Vector2(270, 475), Vector2(290, 510), Vector2(250, 510),
	]
	for a in arboles:
		draw_circle(a, 14, Color(0.15, 0.40, 0.15))
		draw_circle(a - Vector2(4, 4), 6, Color(0.25, 0.55, 0.20))

	# ── SEÑAL DE ENTRADA ────────────────────────────────────
	draw_rect(Rect2(148, 530, 108, 54), C_TECHO)
	draw_rect(Rect2(151, 533, 102, 48), C_AZUL_OS)
	draw_rect(Rect2(151, 533, 102, 48), C_AMARILLO, false, 2.0)
	_draw_str(font, "ENTRADA", Vector2(202, 550), C_TEXTO,    9)
	_draw_str(font, "URBE",    Vector2(202, 564), C_AMARILLO, 10)

	# Logo URBE circular
	draw_circle(Vector2(310, 590), 26, C_AMARILLO)
	draw_arc(Vector2(310, 590), 26, 0.0, TAU, 36, C_TECHO, 2.5)
	_draw_str(font, "URBE", Vector2(310, 594), C_AZUL_OS, 10)

	# ── ETIQUETAS DE MÓDULO (pequeñas, en los caminos) ───────
	_draw_str(font, "M5 Transporte",  Vector2(231, 516), C_TECHO, 8)
	_draw_str(font, "M4 Agua",        Vector2(680, 323), C_TECHO, 8)
	_draw_str(font, "M2 Energía",     Vector2(545, 500), C_TECHO, 8)
	_draw_str(font, "M6 Educación",   Vector2(900, 516), C_TECHO, 8)


func _edif(font: Font, rect: Rect2, nombre: String,
		   color: Color, techo: Color, c_txt: Color) -> void:
	draw_rect(rect, color)
	# Franja de techo
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 10)), techo)
	# Ventanas decorativas (líneas)
	if rect.size.x >= 80 and rect.size.y >= 50:
		var wx : float = rect.size.x / 3.0
		for wi in range(1, 3):
			draw_rect(Rect2(rect.position.x + wi * wx - 6, rect.position.y + 20, 12, 10),
					  Color(0.60, 0.80, 1.0, 0.5))
	# Borde
	draw_rect(rect, techo, false, 2.5)
	_txt(font, nombre, rect, c_txt, 10)


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
