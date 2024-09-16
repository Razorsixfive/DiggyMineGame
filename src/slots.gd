extends PanelContainer

@onready var count = $count
@onready var texture_rect = $MarginContainer/TextureRect
@onready var margin_container = $MarginContainer

@export var myId: int = -1;

@export var itemId: int = 0
@export var antal: int = 0:
	set(newNumber):
		if newNumber == 1:
			count.hide()
		elif newNumber > 0:
			count.show()
			count.text = str(newNumber)
			antal = newNumber
		else:
			antal = newNumber
			texture_rect.texture = null
			count.hide()

@export var fousce: bool = false:
	set(newState):
		var margin_value: int = 4
		if newState:
			margin_value = 0
		margin_container.add_theme_constant_override("margin_top", margin_value)
		margin_container.add_theme_constant_override("margin_left", margin_value)
		margin_container.add_theme_constant_override("margin_bottom", margin_value)
		margin_container.add_theme_constant_override("margin_right", margin_value)
		fousce = newState


func setItem(imag: Texture2D, itemId: int, itemCount: int = 1):
	texture_rect.texture = imag
	antal = itemCount
func _click_this_slot(ev: InputEvent):
	if ev.is_action_pressed("click"):
		clicketLeft.emit(myId)
	if ev.is_action_pressed("rightClick"):
		clicketRight.emit(myId)

signal clicketLeft(slotId:	int)
signal clicketRight(slotId:	int)
