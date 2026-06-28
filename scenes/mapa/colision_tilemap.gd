# ============================================================
# colision_tilemap.gd - URBE Rangers: Eco-Quest
# Colisiones de edificios via TileMapLayer con física integrada.
# Tile 16x16 px → mapa 1408×768 = 88×48 celdas.
# ============================================================
extends TileMapLayer

const TS : int = 16  # tamaño de tile en píxeles

# [centro_x, centro_y, ancho, alto] en píxeles
const EDIFICIOS : Array = [
	# Zona lago superior (completamente bloqueada)
	[704,    85,  1408,  170],
	[ 75,   200,   150,  200],
	# Edificios del campus
	[680,   245,   220,  140],   # Biblioteca
	[937,   222,   145,  135],   # Bloque E
	[1227,  420,   215,  240],   # Bloque F
	[231,   377,   246,  155],   # Estacionamiento M5
	[189,   465,   102,   90],   # Centro Fotocopiado
	[570,   400,   129,   90],   # Bloque B
	[834,   391,   122,   92],   # Bloque D
	[444,   492,   121,   85],   # Bloque A
	[834,   486,   122,   82],   # Bloque C
	[575,   654,   142,   92],   # Bloque G
	[889,   640,   232,  156],   # Rectorado
	[1258,  640,   257,  160],   # Área de Servicios
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

	var h   : float    = TS * 0.5
	var td  : TileData = source.get_tile_data(Vector2i(0, 0), 0)
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
