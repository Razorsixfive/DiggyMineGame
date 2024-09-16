extends PanelContainer

@onready var label = $Label
@onready var itemT = $TextureRect

@export var itemId: int = 0
#sikker at alt køre som det skal når der er items i musen så som at gemmer musen og så vider
@export var count: int = 0:
	set(newCount):
		if newCount > 0:
			show()
			#tænder for mouse treking
			set_physics_process(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			#gør counter kun sylinger når der er mere end en af noget
			if newCount > 1:
				label.text = str(newCount)
				label.show()
			else:
				label.hide()
		else:
			hide()
			#sluker for mouse treking
			set_physics_process(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		count = newCount

func _ready():
	#seter counter til 0 så alting er i den ratiger state når spilet starter
	count = 0

#får item til at følger musen _physics_process bliver sluket når der ikke er noget i musen
func _physics_process(delta):
	position = get_global_mouse_position() - Vector2(32,32)
	
#updater valus for ui
func setHand(img: Texture2D,Id: int,antal: int):
	count = antal
	itemId = Id
	itemT.texture = img
