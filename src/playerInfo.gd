extends Node

@onready var item_list = $itemList
@onready var invertoryUi = $CanvasLayer/invertory
@onready var shop = $CanvasLayer/shop
@onready var status_bar = $CanvasLayer/statusBar
@onready var hand_slot = $CanvasLayer/handSlot


@export var invtery: Array[invertorySlot]
@export var coins: int:
	set(num):
		status_bar.setCoin(num)
		coins = num

var InvertoryState: bool = false
var hotBarTaget: int = 0:
	set(newSlot):
		if newSlot != hotBarTaget:
			invertoryUi.setSlotFucos(hotBarTaget, false)
			invertoryUi.setSlotFucos(newSlot,true)
			hotBarTaget = newSlot

var handSlot: invertorySlot = invertorySlot.new()

func  _ready():
	for slotCount in invtery.size():
		if !invtery[slotCount]:
			invtery[slotCount] = invertorySlot.new()
			
	invertoryUi.LoadInvertory(invtery)
	invertoryUi.setSlotFucos(0,true)
	invertoryUi.leftClickSlot.connect(leftClick)
	invertoryUi.rightClickSlot.connect(rightClick)
	shop.sellItem.connect(sellHand)
	shop.buyItem.connect(buyHand)
	coins = 1000

func swapInvertoryState():
	InvertoryState = !InvertoryState
	if InvertoryState:
		invertoryUi.open()
	else:
		invertoryUi.close()
		

func addItem(itemId: int) -> bool:
	for slotCount in invtery.size():
		if invtery[slotCount].itemId == itemId:
			if item_list.items[itemId].stackSize > invtery[slotCount].count:
				invtery[slotCount].count += 1
				invertoryUi.setSlot(slotCount,invtery[slotCount])
				return true
	for slotCount in invtery.size():
		if invtery[slotCount].count <= 0:
			invtery[slotCount].itemId = itemId
			invtery[slotCount].count = 1
			invertoryUi.setSlot(slotCount,invtery[slotCount])
			return true
	return false

func placeItem() -> Vector3i:
	if invtery[hotBarTaget].count > 0:
		if item_list.items[invtery[hotBarTaget].itemId].placerble:
			invtery[hotBarTaget].count -= 1
			invertoryUi.setSlot(hotBarTaget,invtery[hotBarTaget])
			return Vector3i(item_list.items[invtery[hotBarTaget].itemId].atlastPos.x,item_list.items[invtery[hotBarTaget].itemId].atlastPos.y,item_list.items[invtery[hotBarTaget].itemId].atlastId)
	return Vector3i(0,0,-1)

func leftClick(id: int):
	var tempItem: invertorySlot = handSlot
	handSlot = invtery[id]
	invtery[id] = tempItem
	
	invertoryUi.setSlot(id,invtery[id])
	hand_slot.setHand(item_list.items[handSlot.itemId].texture,handSlot.itemId,handSlot.count)
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
			var antal = ceil(invtery[id].count/2)
			handSlot.itemId = invtery[id].itemId
			handSlot.count = antal
			invtery[id].count -= antal
	invertoryUi.setSlot(id,invtery[id])
	hand_slot.setHand(item_list.items[handSlot.itemId].texture,handSlot.itemId,handSlot.count)

func sellHand(all: bool):
	if handSlot.count > 0:
		var antal: int = 0
		if all:
			antal = handSlot.count
		else:
			antal = 1
		coins += item_list.items[handSlot.itemId].sell * antal
		handSlot.count -= antal
	hand_slot.setHand(item_list.items[handSlot.itemId].texture,handSlot.itemId,handSlot.count)
func buyHand(id: int):
	if handSlot.count > 0:
		if handSlot.itemId == id:
			if buyItemToHand(id):
				handSlot.count += 1
	else:
		if buyItemToHand(id):
			handSlot.itemId = id
			handSlot.count = 1
	hand_slot.setHand(item_list.items[handSlot.itemId].texture,handSlot.itemId,handSlot.count)

func buyItemToHand(id: int) -> bool:
	if item_list.items[id].buy <= coins:
		if handSlot.count < item_list.items[id].stackSize:
			coins -= item_list.items[id].buy
			return true
	return false
