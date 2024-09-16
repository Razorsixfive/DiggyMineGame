extends Node2D

@onready var tile_map = $TileMap
@onready var water_manger = $waterManger

@export var xSize: int
@export var ySize: int

@export var groundHight: int = 7

@export var oreDestie: float
@export var ground: Array[tileHight]
@export var ore: Array[tileHight]

# Called when the node enters the scene tree for the first time.
func _ready():
	worldSpawn(Vector2i(xSize,ySize), groundHight)


@rpc("authority", "reliable")
func worldSpawn(mapSize: Vector2i,flowerHight: int):
	if multiplayer.is_server():
		worldSpawn.rpc(mapSize,flowerHight)
	xSize = mapSize.x
	ySize = mapSize.y
	groundHight = flowerHight
	water_manger.setupMap(xSize,ySize)
	#placing ground
	var arayPoint: int = 0
	for y in ySize:
		if ground.size() > arayPoint+1:
			if ground[arayPoint+1].hight <= y:
				arayPoint += 1
		for x in xSize:
			if y > groundHight:
				tile_map.set_cell(1,Vector2i(x,y),ground[arayPoint].atlastId,ground[arayPoint].atlastPos)
			elif y == groundHight:
				tile_map.set_cell(1,Vector2i(x,y),5,Vector2i(0,0))
	if multiplayer.is_server():
		for y in ySize:
			for x in xSize:
				if y > groundHight +1:
					if randf() <= oreDestie:
						placeOre(Vector2i(x,y),0,Vector2i(0,0))
						placeOre.rpc(Vector2i(x,y),0,Vector2i(0,0))
		makeSea(Vector2i(2,groundHight),Vector2i(8,groundHight+4))
				
@rpc("authority","reliable")
func placeOre(pos: Vector2i, atlasId: int, atlasPos: Vector2i):
	tile_map.set_cell(2,pos,atlasId,atlasPos)
@rpc("any_peer", "reliable")
func placeTile(pos: Vector2i,atlasId:int,atlasPos: Vector2i):
	tile_map.set_cell(1,pos,atlasId,atlasPos)
@rpc("any_peer", "reliable")
func breackTile(pos: Vector2i) -> int:
	var dropId: int
	var tileData: TileData
	tileData = tile_map.get_cell_tile_data(2,pos)
	if tileData:
		dropId = tileData.get_custom_data("drop")
	else:
		tileData = tile_map.get_cell_tile_data(1,pos)
		if tileData:
			dropId = tileData.get_custom_data("drop")
	tile_map.set_cell(1,pos,-1)
	tile_map.set_cell(2,pos,-1)
	water_manger.waterNeedUpdate(pos+ Vector2i.UP)
	water_manger.waterNeedUpdate(pos+ Vector2i.DOWN)
	water_manger.waterNeedUpdate(pos+ Vector2i.LEFT)
	water_manger.waterNeedUpdate(pos+ Vector2i.RIGHT)
	return dropId
	
func addWater(pos: Vector2i,amount: int):
	if !multiplayer.is_server():
		water_manger.waterMove.rpc_id(1,pos,amount)
	else:
		water_manger.waterMove(pos,amount)

func posToGridPos(pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(pos / tile_map.scale.x)

func digLevel(pos: Vector2i, procent: float):
	if procent == -1:
		setDigLevel(pos,-1,true)
	elif 0.6 <= procent:
		setDigLevel(pos,2,true)
	elif 0.3 <= procent:
		setDigLevel(pos,1,true)
	elif 0.1 <= procent:
		setDigLevel(pos,0,true)
		
@rpc("any_peer","reliable")
func setDigLevel(pos: Vector2i,level: int, isLocal: bool):
	var tileOld: Vector2i = tile_map.get_cell_atlas_coords(3,pos)
	if tileOld.x != level:
		if level == -1:
			tile_map.set_cell(3,pos,-1)
		else :
			tile_map.set_cell(3,pos,4,Vector2i(level,0))
		if isLocal:
			setDigLevel.rpc(pos,level,false)

func getTraineModifyer(pos: Vector2i) -> Array:
	var dataHolder: Array[bool] = [false,false]
		#geting specal tages from tile the player is in
	var tileDataFront: TileData = tile_map.get_cell_tile_data(1,pos)
	var tileDataBack = tile_map.get_cell_tile_data(0,pos)

	#tjekker om spiler er på staires eller i vand
	if tileDataFront:
		dataHolder[0] = tileDataFront.get_custom_data("clime")
	elif tileDataBack:
		dataHolder[0] = tileDataBack.get_custom_data("clime")
	else:
		dataHolder[0] = false

	#tjeker om spiller er under vand
	if tileDataBack:
		dataHolder[1] = tileDataBack.get_custom_data("blockAir")
	else:
		dataHolder[1] = false
	return dataHolder

func getBlockHp(pos: Vector2i) -> float:
	var tileData: TileData = tile_map.get_cell_tile_data(1,pos)
	if tileData:
		var exterHp: int
		var baseHp = tileData.get_custom_data("hp")
		var oreTile: TileData = tile_map.get_cell_tile_data(2,pos)
		if oreTile:
			exterHp = oreTile.get_custom_data("hp")
		else:
			exterHp = 0
		return (baseHp + exterHp)*0.25
	return -1
func isTileFree(pos: Vector2i) -> bool:
	var tileData: TileData = tile_map.get_cell_tile_data(1,pos)
	if tileData:
		return false
	return true
	
func makeSea(startPos: Vector2i, endPos: Vector2i):
	var workSpace: Vector2i = Vector2i(endPos.x - startPos.x,endPos.y - startPos.y)
	for y in workSpace.y:
		for x in workSpace.x:
			breackTile(Vector2i(startPos.x+x,startPos.y+y))
			addWater(Vector2i(startPos.x+x,startPos.y+y),100)
