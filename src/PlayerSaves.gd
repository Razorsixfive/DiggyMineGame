class_name PlayerSaves extends Node

class PlayerSaveData:
	var name: String

	var maxHp: int
	var maxAir: int

	var item: Array


func SavePlayer(Player: PlayerSaveData):
	var file = FileAccess.open("user://save//chater.save", FileAccess.WRITE)

func  LoadPlayer() -> PlayerSaveData:
	var data: PlayerSaveData = PlayerSaveData.new()
	if FileAccess.file_exists("user://save//chater.save"):
		var file = FileAccess.open("user://save//chater.save", FileAccess.READ)
	else:
		data.name = "new player"
		data.maxHp = 20
		data.maxAir = 20

	return
