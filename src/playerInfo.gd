extends Node

# ---------- Onready Variables ----------
@onready var item_list = $itemList
@onready var invertoryUi = $CanvasLayer/invertory
@onready var shop = $CanvasLayer/shop
@onready var status_bar = $CanvasLayer/statusBar
@onready var hand_slot = $CanvasLayer/handSlot

# ---------- Exported Variables ----------
@export var invtery: Array[invertorySlot]
@export var coins: int:
	set(num):
		status_bar.setCoin(num)
		coins = num

# ---------- Variables ----------
var InvertoryState: bool = false
var hotBarTaget: int = 0:
	set(newSlot):
		if newSlot != hotBarTaget:
			invertoryUi.setSlotFucos(hotBarTaget, false)
			invertoryUi.setSlotFucos(newSlot, true)
			hotBarTaget = newSlot

var handSlot: invertorySlot = invertorySlot.new()

# ---------- Ready Function ----------
# Initialize inventory slots and connect signals
func _ready():
	for slotCount in invtery.size():
		if !invtery[slotCount]:
			invtery[slotCount] = invertorySlot.new()
	
	invertoryUi.LoadInvertory(invtery)
	invertoryUi.setSlotFucos(0, true)
	invertoryUi.leftClickSlot.connect(leftClick)
	invertoryUi.rightClickSlot.connect(rightClick)
	shop.sellItem.connect(sellHand)
	shop.buyItem.connect(buyHand)
	coins = 1000

# ---------- Inventory Management ----------
# Toggle the inventory UI state
func swapInvertoryState():
	InvertoryState = !InvertoryState
	if InvertoryState:
		invertoryUi.open()
	else:
		invertoryUi.close()

# Adds an item to the inventory
func addItem(itemId: int) -> bool:
	for slotCount in invtery.size():
		if invtery[slotCount].itemId == itemId:
			if item_list.items[itemId].stackSize > invtery[slotCount].count:
				invtery[slotCount].count += 1
				invertoryUi.setSlot(slotCount, invtery[slotCount])
				return true
	for slotCount in invtery.size():
		if invtery[slotCount].count <= 0:
			invtery[slotCount].itemId = itemId
			invtery[slotCount].count = 1
			invertoryUi.setSlot(slotCount, invtery[slotCount])
			return true
	return false

# Place an item and reduce its count in the inventory
func placeItem() -> Vector3i:
	if invtery[hotBarTaget].count > 0:
		if item_list.items[invtery[hotBarTaget].itemId].placerble:
			invtery[hotBarTaget].count -= 1
			invertoryUi.setSlot(hotBarTaget, invtery[hotBarTaget])
			return Vector3i(item_list.items[invtery[hotBarTaget].itemId].atlastPos.x, item_list.items[invtery[hotBarTaget].itemId].atlastPos.y, item_list.items[invtery[hotBarTaget].itemId].atlastId)
	return Vector3i(0, 0, -1)

# ---------- Inventory Slot Management ----------
# Handles left-click on a slot to swap the item with the hand slot
func leftClick(id: int):
	var tempItem: invertorySlot = handSlot
	handSlot = invtery[id]
	invtery[id] = tempItem
	invertoryUi.setSlot(id, invtery[id])
	hand_slot.setHand(item_list.items[handSlot.itemId].texture, handSlot.itemId, handSlot.count)

# Handles right-click on a slot to merge or split items between hand and inventory
func rightClick(id: int):
	if handSlot.count > 0:
		if invtery[id].count > 0:
			if invtery[id].itemId == handSlot.itemId:
				handSlot.count -= 1
				invtery[id].count += 1
		else:
			invtery[id].itemId = handSlot.itemId
			handSlot.count -= 1
			invtery[id].count += 1
	else:
		if invtery[id].count > 0:
			var antal = ceil(invtery[id].count / 2)
			handSlot.itemId = invtery[id].itemId
			handSlot.count = antal
			invtery[id].count -= antal
	invertoryUi.setSlot(id, invtery[id])
	hand_slot.setHand(item_list.items[handSlot.itemId].texture, handSlot.itemId, handSlot.count)

# ---------- Shop Management ----------
# Sells the item in the hand slot for coins
func sellHand(all: bool):
	if handSlot.count > 0:
		var antal: int = 0
		if all:
			antal = handSlot.count
		else:
			antal = 1
		coins += item_list.items[handSlot.itemId].sell * antal
		handSlot.count -= antal
	hand_slot.setHand(item_list.items[handSlot.itemId].texture, handSlot.itemId, handSlot.count)

# Buys an item and places it in the hand slot
func buyHand(id: int):
	if handSlot.count > 0:
		if handSlot.itemId == id:
			if buyItemToHand(id):
				handSlot.count += 1
	else:
		if buyItemToHand(id):
			handSlot.itemId = id
			handSlot.count = 1
	hand_slot.setHand(item_list.items[handSlot.itemId].texture, handSlot.itemId, handSlot.count)

# Buys an item if enough coins are available
func buyItemToHand(id: int) -> bool:
	if item_list.items[id].buy <= coins:
		if handSlot.count < item_list.items[id].stackSize:
			coins -= item_list.items[id].buy
			return true
	return false
