extends Resource
class_name ItemData

# ---------- Exported Variables ----------
@export var name: String = ""
@export_multiline var description: String = ""
@export var stackSize: int = 32
@export var texture: Texture2D

@export var sell: int = -1
@export var buy: int = 0

@export var placerble: bool = false
@export var atlastId: int
@export var atlastPos: Vector2i

