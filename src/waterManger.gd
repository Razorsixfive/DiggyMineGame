extends Node

@onready var tile_map = $"../TileMap"

@export var waterSleepSec: float = 1.5
@export var flowMin: int = 1
var size: Vector2i
var tikeCount: float = 0

var waterGrid: Array

func setupMap(xSize:int, ySize:int):
	waterGrid.clear()
	size.x = xSize
	size.y = ySize
	for x in xSize:
		waterGrid.append([])
		for y in ySize:
			waterGrid[x].append(waterTile.new())
	if multiplayer.is_server():
		set_process(true)
	else:
		set_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if tikeCount >= waterSleepSec:
		updateWater()
		tikeCount = 0
		for x in size.x:
			for y in size.y:
				if waterGrid[x][y].updateNext:
					waterGrid[x][y].update = true
					waterGrid[x][y].updateNext = false

	else:
		tikeCount += delta

func updateWater():
	for x in size.x:
		for y in size.y:
			if waterGrid[x][y].update:
				waterGrid[x][y].update = false
				if waterGrid[x][y].water > 0:
					waterNeedUpdate(Vector2i(x,y+1))
					waterFlow(Vector2i(x,y),Vector2i.DOWN)
					if waterGrid[x][y].water > 0:
						waterFlow(Vector2i(x,y),Vector2i.LEFT)
						waterFlow(Vector2i(x,y),Vector2i.RIGHT)
						waterFlow(Vector2i(x,y),Vector2i.UP)

@rpc("reliable","any_peer")
func waterMove(pos: Vector2i, amount:int):
	if multiplayer.is_server():
		waterMove.rpc(pos,amount)
	waterGrid[pos.x][pos.y].water += amount
	if waterGrid[pos.x][pos.y].water < 0:
		waterGrid[pos.x][pos.y].water = 0
	if waterGrid[pos.x][pos.y].water <= 0:
		tile_map.set_cell(0,pos,-1)
	elif waterGrid[pos.x][pos.y].water <= 16:
		tile_map.set_cell(0,pos,1,Vector2i(5,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)
	elif waterGrid[pos.x][pos.y].water <= 32:
		tile_map.set_cell(0,pos,1,Vector2i(4,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)
	elif waterGrid[pos.x][pos.y].water <= 48:
		tile_map.set_cell(0,pos,1,Vector2i(3,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)
	elif waterGrid[pos.x][pos.y].water <= 64:
		tile_map.set_cell(0,pos,1,Vector2i(2,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)
	elif waterGrid[pos.x][pos.y].water <= 80:
		tile_map.set_cell(0,pos,1,Vector2i(1,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)
	else:
		tile_map.set_cell(0,pos,1,Vector2i(0,0))
		if multiplayer.is_server():
			if abs(amount) >= flowMin:
				waterNeedUpdate(pos)

func waterFlow(source: Vector2i, tagetOfeset: Vector2i):
	var waterLevel: int = waterScan(source +tagetOfeset)
	if waterLevel >= 0:
		if tagetOfeset == Vector2i.DOWN:
			if waterLevel < 100:
				var amount: int = clamp(100 - waterLevel,0,waterGrid[source.x][source.y].water)
				waterMove(source, amount * -1)
				waterMove(source + tagetOfeset,amount)
				waterGrid[source.x][source.y-1].updateNext = true
		elif tagetOfeset == Vector2i.UP:
			if waterGrid[source.x][source.y].water > 99:
				waterGrid[source.x][source.y-1].updateNext = true
				if waterLevel > 99:
					var amount = abs(waterLevel-floor((waterLevel + waterGrid[source.x][source.y].water)/2))
					waterMove(source, amount * -1)
					waterMove(source + tagetOfeset,amount)
				else:
					var amount: int = clamp(100 - waterLevel,0,waterGrid[source.x][source.y].water-100)
					waterMove(source, amount * -1)
					waterMove(source + tagetOfeset,amount)
		else:
			var amount = abs(waterLevel-floor((waterLevel + waterGrid[source.x][source.y].water)/2))
			waterMove(source, amount * -1)
			waterMove(source + tagetOfeset,amount)



func waterNeedUpdate(pos:Vector2i):
	if multiplayer.is_server():
		if pos.x >= 0:
			if pos.x < size.x:
				if pos.y >= 0:
					if pos.y < size.y:
						waterGrid[pos.x][pos.y].updateNext = true

func waterScan(pos:Vector2i) -> int:
	if pos.x < 0:
		return -1
	if pos.x > size.x-1:
		return -1
	if pos.y < 0:
		return -1
	if pos.y > size.y-1:
		return -1
	var groundTileData = tile_map.get_cell_tile_data(1,pos)
	if groundTileData:
		if groundTileData.get_custom_data("porous"):
			return waterGrid[pos.x][pos.y].water
		else:
			return -1
	else:
		return waterGrid[pos.x][pos.y].water
