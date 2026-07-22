# ============================================================
# colision_tilemap.gd - URBE Rangers: Eco-Quest
# Colisiones alineadas al layout de cuadrícula de mapa_campus.gd
# Tile 16x16 px. Formato: [cx, cy, ancho, alto] en píxeles.
# ============================================================
extends TileMapLayer

const TS : int = 16

# Posiciones exactas extraídas de los Rect2 en mapa_campus.gd
# [cx, cy, w, h]  (centro = pos + size/2)
const EDIFICIOS : Array = [
	# Lago norte  y=0..163
	[704,   80,  1408,  163],

	# Fila 1  y=208..368  (BloqueE desplazado 16px → pasillo 32px con Biblioteca)
	[ 96,  288,   192,  160],   # Estacionamiento M5
	[328,  288,   176,  160],   # Cafetín
	[568,  288,   208,  160],   # Biblioteca
	[776,  288,   144,  160],   # Bloque E  (x=704..848)
	[1280, 392,   256,  368],   # Bloque F  (filas 1 y 2)

	# Fila 2  y=400..576  (BloqueB desplazado 16px → pasillo 32px con BloqueA)
	[ 96,  488,   192,  176],   # Bloque G
	[328,  488,   176,  176],   # Bloque D
	[552,  488,   176,  176],   # Bloque A
	[752,  488,   160,  176],   # Bloque B  (x=672..832)

	# Fila 3  y=608..704
	[ 72,  656,   144,   96],   # Fotocopiado
	[320,  656,   160,   96],   # Bloque C
	[672,  656,   416,   96],   # Rectorado / Auditorio
	[1280, 656,   256,   96],   # Área de Servicios
]

var _source_id : int = 0


func _ready() -> void:
	_crear_tileset()
	_pintar_edificios()
	visible = false
	print("OK ColisionTileMap: %d edificios" % EDIFICIOS.size())


func _crear_tileset() -> void:
	var img := Image.create(TS, TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.2, 0.2, 0.7))
	var tex := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TS, TS)
	source.create_tile(Vector2i(0, 0))

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)
	_source_id = ts.add_source(source)

	var h  : float    = TS * 0.5
	var td : TileData = source.get_tile_data(Vector2i(0, 0), 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h),
		Vector2(h,  h),  Vector2(-h, h)
	]))

	tile_set = ts


func _pintar_edificios() -> void:
	for e in EDIFICIOS:
		var cx  : float = float(e[0])
		var cy  : float = float(e[1])
		var aw  : float = float(e[2])
		var ah  : float = float(e[3])
		var tx0 : int   = int(floor((cx - aw * 0.5) / TS))
		var ty0 : int   = int(floor((cy - ah * 0.5) / TS))
		var tx1 : int   = int(ceil( (cx + aw * 0.5) / TS))
		var ty1 : int   = int(ceil( (cy + ah * 0.5) / TS))
		for gx in range(tx0, tx1):
			for gy in range(ty0, ty1):
				set_cell(Vector2i(gx, gy), _source_id, Vector2i(0, 0))
