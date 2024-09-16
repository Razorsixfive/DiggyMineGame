extends PanelContainer
@onready var shopMenu = $GridContainer/MarginContainer
@onready var shopPopper = $GridContainer/Button

@onready var shop_list = $"../../shopList"
@onready var item_list = $"../../itemList"

@export var shopIcon: Texture2D

signal buyItem(id: int)
signal sellItem(all: bool)

var shopPopOut: bool:
	set(open):
		if open:
			shopMenu.show()
			shopPopper.text = "close shop"
		else:
			shopMenu.hide()
			shopPopper.text = "open shop"
		shopPopOut = open

func _ready():
	shopPopOut = false
	var shopSlot = $GridContainer/MarginContainer/GridContainer.get_children()
	for i in shopSlot:
		if i.myId >= 0:
			if shop_list.items.size() > i.myId:
				i.clicketLeft.connect(_slotTagetLeft)
				i.clicketRight.connect(_slotTagetRight)
				i.setItem(item_list.items[shop_list.items[i.myId]].texture,1)
		else:
			i.clicketLeft.connect(_slotTagetLeft)
			i.clicketRight.connect(_slotTagetRight)
			i.setItem(shopIcon,1)



func _slotTagetLeft(id: int):
	if id >= 0:
		if shop_list.items.size() > id:
			buyItem.emit(shop_list.items[id])
	else:
		sellItem.emit(true)
func _slotTagetRight(id: int):
	if id >= 0:
		if shop_list.items.size() > id:
			buyItem.emit(shop_list.items[id])
	else:
		sellItem.emit(false)
func _shopButon():
	shopPopOut = !shopPopOut
	shopPopper.hide()
	shopPopper.show()
