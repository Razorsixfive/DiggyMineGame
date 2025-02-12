extends PanelContainer

# ---------- Onready Nodes ----------
@onready var shopMenu = $GridContainer/MarginContainer
@onready var shopPopper = $GridContainer/Button
@onready var shop_list = $"../../shopList"
@onready var item_list = $"../../itemList"

# ---------- Exported Variables ----------
@export var shopIcon: Texture2D

# ---------- Signals ----------
signal buyItem(id: int)
signal sellItem(all: bool)

# ---------- Shop Pop-Out State ----------
var shopPopOut: bool:
	set(open):
		if open:
			shopMenu.show()
			shopPopper.text = "close shop"
		else:
			shopMenu.hide()
			shopPopper.text = "open shop"
		shopPopOut = open

# ---------- Ready Function ----------
func _ready():
	shopPopOut = false
	var shopSlot = $GridContainer/MarginContainer/GridContainer.get_children()
	for i in shopSlot:
		if i.myId >= 0:
			if shop_list.items.size() > i.myId:
				i.clicketLeft.connect(_slotTagetLeft)
				i.clicketRight.connect(_slotTagetRight)
				i.setItem(item_list.items[shop_list.items[i.myId]].texture, 1)
		else:
			i.clicketLeft.connect(_slotTagetLeft)
			i.clicketRight.connect(_slotTagetRight)
			i.setItem(shopIcon, 1)

# ---------- Slot Click Handlers ----------
# Handles left click on a slot, emitting a signal to buy the item or sell all items if the ID is negative.
func _slotTagetLeft(id: int):
	if id >= 0:
		if shop_list.items.size() > id:
			buyItem.emit(shop_list.items[id])
	else:
		sellItem.emit(true)

# Handles right click on a slot, emitting a signal to buy the item or sell individual item if the ID is negative.
func _slotTagetRight(id: int):
	if id >= 0:
		if shop_list.items.size() > id:
			buyItem.emit(shop_list.items[id])
	else:
		sellItem.emit(false)

# Toggles the shop pop-out state and updates the button text accordingly.
func _shopButon():
	shopPopOut = !shopPopOut
	shopPopper.hide()
	shopPopper.show()

