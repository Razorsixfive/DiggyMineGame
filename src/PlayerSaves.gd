extends Node

class_name PlayerSaves

# ---------- Player Save Data Class ----------
class PlayerSaveData:
	var name: String

	var maxHp: int
	var maxAir: int

	var item: Array

# ---------- Save and Load Functions ----------
# Saves player data to a file.
func SavePlayer(Player: PlayerSaveData):
	var file = FileAccess.open("user://save//chater.save", FileAccess.WRITE)
	# Write player data to file here

# Loads player data from a file and returns a PlayerSaveData instance.
func LoadPlayer() -> PlayerSaveData:
	var data: PlayerSaveData = PlayerSaveData.new()
	
	if FileAccess.file_exists("user://save//chater.save"):
		var file = FileAccess.open("user://save//chater.save", FileAccess.READ)
		# Read player data from file here
	else:
		data.name = "new player"
		data.maxHp = 20
		data.maxAir = 20

	return data

