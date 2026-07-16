# ============================================================
# colision_tilemap.gd - URBE Rangers: Eco-Quest
# Colisiones de edificios via TileMapLayer con física integrada.
# Tile 16x16 px → mapa 1408×768 = 88×48 celdas.
# ============================================================
extends TileMapLayer

const TS : int = 16  # tamaño de tile en píxeles

# [centro_x, centro_y, ancho, alto] en píxeles
# Valores alineados a cuadrícula 16px.
# Caminos: izq x=192-240, centro x=416-464, der x=1104-1152, top y=176-208, avda y=704-768
# Pasillo fila 1→2: y=368-400 (32px)   Pasillo fila 2→3: y=576-608 (32px)
const EDIFICIOS : Array = [
	# Lago y orilla  y=0..160
	[704,  80, 1408, 160],
	# Fila 1  y=208..368
	[96,  288,  192, 160],   # Estacionamiento M5  x=0..192
	[328, 288,  176, 160],   # Cafetín M3          x=240..416
	[568, 288,  208, 160],   # Biblioteca M4       x=464..672
	[768, 288,  160, 160],   # Bloque E M2         x=688..848
	# Bloque F  y=208..576 (ocupa fila 1 y 2 en el lado derecho)
	[1280, 392, 256, 368],   # Bloque F M1         x=1152..1408
	# Fila 2  y=400..576  (pasillo 32px arriba y abajo)
	[96,  488,  192, 176],   # Bloque G M1         x=0..192
	[328, 488,  176, 176],   # Bloque D M2         x=240..416
	[552, 488,  176, 176],   # Bloque A M2         x=464..640
	[744, 488,  176, 176],   # Bloque B M2         x=656..832
	# Fila 3  y=608..704  (pasillo 32px arriba, avenida abajo)
	[72,  656,  144,  96],   # Fotocopiado M1      x=0..144
	[320, 656,  160,  96],   # Bloque C M2         x=240..400
	[672, 656,  416,  96],   # Rectorado M6        x=464..880
	[1280, 656, 256,  96],   # Área Servicios M6   x=1152..1408
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
