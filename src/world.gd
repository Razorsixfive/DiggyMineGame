extends Node2D

# ---------- Onready Variables ----------
@onready var tile_map = $TileMap
@onready var water_manger = $waterManger

# ---------- Exported Variables ----------
@export var xSize: int
@export var ySize: int
@export var groundHight: int = 7
@export var oreDestie: float
@export var ground: Array[tileHight]
@export var ore: Array[tileHight]

# ---------- Ready Function ----------
# Called when the node enters the scene tree for the first time.
func _ready():
	worldSpawn(Vector2i(xSize, ySize), groundHight)

# ---------- World Generation ----------
@rpc("authority", "reliable")
# Spawns the world based on the map size and flower height
func worldSpawn(mapSize: Vector2i, flowerHight: int):
	if multiplayer.is_server():
		worldSpawn.rpc(mapSize, flowerHight)
	xSize = mapSize.x
	ySize = mapSize.y
	groundHight = flowerHight
	water_manger.setupMap(xSize, ySize)

	# Placing ground tiles
	var arayPoint: int = 0
	for y in ySize:
		if ground.size() > arayPoint + 1:
			if ground[arayPoint + 1].hight <= y:
				arayPoint += 1
		for x in xSize:
			if y > groundHight:
				tile_map.set_cell(1, Vector2i(x, y), ground[arayPoint].atlastId, ground[arayPoint].atlastPos)
			elif y == groundHight:
				tile_map.set_cell(1, Vector2i(x, y), 5, Vector2i(0, 0))

	if multiplayer.is_server():
		for y in ySize:
			for x in xSize:
				if y > groundHight + 1:
					if randf() <= oreDestie:
						placeOre(Vector2i(x, y), 0, Vector2i(0, 0))
						placeOre.rpc(Vector2i(x, y), 0, Vector2i(0, 0))
		makeSea(Vector2i(2, groundHight), Vector2i(8, groundHight + 4))

# ---------- Tile Management ----------
@rpc("authority", "reliable")
# Places ore on the map
func placeOre(pos: Vector2i, atlasId: int, atlasPos: Vector2i):
	tile_map.set_cell(2, pos, atlasId, atlasPos)

@rpc("any_peer", "reliable")
# Places a tile on the map
func placeTile(pos: Vector2i, atlasId: int, atlasPos: Vector2i):
	tile_map.set_cell(1, pos, atlasId, atlasPos)

@rpc("any_peer", "reliable")
# Breaks a tile and returns the drop ID
func breackTile(pos: Vector2i) -> int:
	var dropId: int
	var tileData: TileData
	tileData = tile_map.get_cell_tile_data(2, pos)
	if tileData:
		dropId = tileData.get_custom_data("drop")
	else:
		tileData = tile_map.get_cell_tile_data(1, pos)
		if tileData:
			dropId = tileData.get_custom_data("drop")
	tile_map.set_cell(1, pos, -1)
	tile_map.set_cell(2, pos, -1)
	water_manger.waterNeedUpdate(pos + Vector2i.UP)
	water_manger.waterNeedUpdate(pos + Vector2i.DOWN)
	water_manger.waterNeedUpdate(pos + Vector2i.LEFT)
	water_manger.waterNeedUpdate(pos + Vector2i.RIGHT)
	return dropId

# ---------- Water Management ----------
# Adds water to the map
func addWater(pos: Vector2i, amount: int):
	if !multiplayer.is_server():
		water_manger.waterMove.rpc_id(1, pos, amount)
	else:
		water_manger.waterMove(pos, amount)

# ---------- Utility Functions ----------
# Converts position to grid position
func posToGridPos(pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(pos / tile_map.scale.x)

# Adjusts the digging level of a tile
func digLevel(pos: Vector2i, procent: float):
	if procent == -1:
		setDigLevel(pos, -1, true)
	elif 0.6 <= procent:
		setDigLevel(pos, 2, true)
	elif 0.3 <= procent:
		setDigLevel(pos, 1, true)
	elif 0.1 <= procent:
		setDigLevel(pos, 0, true)

@rpc("any_peer", "reliable")
# Sets the digging level of a tile
func setDigLevel(pos: Vector2i, level: int, isLocal: bool):
	var tileOld: Vector2i = tile_map.get_cell_atlas_coords(3, pos)
	if tileOld.x != level:
		if level == -1:
			tile_map.set_cell(3, pos, -1)
		else:
			tile_map.set_cell(3, pos, 4, Vector2i(level, 0))
		if isLocal:
			setDigLevel.rpc(pos, level, false)

# Retrieves modifiers for terrain at the given position
func getTraineModifyer(pos: Vector2i) -> Array:
	var dataHolder: Array[bool] = [false, false]
	var tileDataFront: TileData = tile_map.get_cell_tile_data(1, pos)
	var tileDataBack = tile_map.get_cell_tile_data(0, pos)

	if tileDataFront:
		dataHolder[0] = tileDataFront.get_custom_data("clime")
	elif tileDataBack:
		dataHolder[0] = tileDataBack.get_custom_data("clime")
	else:
		dataHolder[0] = false

	if tileDataBack:
		dataHolder[1] = tileDataBack.get_custom_data("blockAir")
	else:
		dataHolder[1] = false
	return dataHolder

# Retrieves the health points of a block
func getBlockHp(pos: Vector2i) -> float:
	var tileData: TileData = tile_map.get_cell_tile_data(1, pos)
	if tileData:
		var exterHp: int
		var baseHp = tileData.get_custom_data("hp")
		var oreTile: TileData = tile_map.get_cell_tile_data(2, pos)
		if oreTile:
			exterHp = oreTile.get_custom_data("hp")
		else:
			exterHp = 0
		return (baseHp + exterHp) * 0.25
	return -1

# Checks if a tile is free
func isTileFree(pos: Vector2i) -> bool:
	var tileData: TileData = tile_map.get_cell_tile_data(1, pos)
	if tileData:
		return false
	return true

# ---------- Sea and Water Creation ----------
# Creates a sea in the defined area
func makeSea(startPos: Vector2i, endPos: Vector2i):
	var workSpace: Vector2i = Vector2i(endPos.x - startPos.x, endPos.y - startPos.y)
	for y in workSpace.y:
		for x in workSpace.x:
			breackTile(Vector2i(startPos.x + x, startPos.y + y))
			addWater(Vector2i(startPos.x + x, startPos.y + y), 100)

