extends PanelContainer

# ---------- Preloaded Resources ----------
var slote = preload("res://item/uiInvertorySlot.tscn")

# ---------- Onready Nodes ----------
@onready var item_list = $"../../itemList"
@onready var cold_bar = $GridContainer/coldBar/GridContainer
@onready var hot_bar = $GridContainer/hotBar/GridContainer

# ---------- Signals ----------
signal leftClickSlot(id: int)
signal rightClickSlot(id: int)

# ---------- Inventory Management ----------
# Opens the cold bar inventory UI.
func open():
	cold_bar.show()

# Closes the cold bar inventory UI.
func close():
	cold_bar.hide()

# Sets focus on the specified slot in the hot bar.
func setSlotFucos(slot: int, taget: bool):
	var inv = hot_bar.get_children()
	inv[slot].fousce = taget

# Sets the content of a UI slot to match the inventory slot.
func setSlot(slot: int, item: invertorySlot):
	# Checks if the slot is in the hot bar
	if slot <= 3:
		var inv = hot_bar.get_children()
		# Checks if the item is already loaded to avoid reloading texture
		if inv[slot].antal > 0:
			inv[slot].antal = item.count
		else:
			inv[slot].setItem(item_list.items[item.itemId].texture, item.itemId, item.count)
	# Otherwise, it is a normal inventory slot
	else:
		var inv = cold_bar.get_children()
		slot -= 4
		# Checks if the item is already loaded to avoid reloading texture
		if inv[slot].antal > 0:
			inv[slot].antal = item.count
		else:
			inv[slot].setItem(item_list.items[item.itemId].texture, item.itemId, item.count)

# Loads the inventory UI and adjusts it to the inventory size.
func LoadInvertory(slots: Array[invertorySlot]):
	# Removes all hot bar slots
	var inv = hot_bar.get_children()
	for i in inv:
		hot_bar.remove_child(i)
	
	# Builds and configures the hot bar
	for i in 4:
		var newSlot = slote.instantiate()
		newSlot.myId = i
		newSlot.clicketLeft.connect(_slotTagetLeft)
		newSlot.clicketRight.connect(_slotTagetRight)
		# Updates the UI with existing inventory info if available
		if slots[newSlot.myId].count > 0:
			newSlot.setItem(item_list.items[slots[newSlot.myId].itemId].texture, slots[newSlot.myId].itemId, slots[newSlot.myId].count)
		hot_bar.add_child(newSlot, true)
	
	# Removes all non-hot bar slots
	inv = cold_bar.get_children()
	for i in inv:
		cold_bar.remove_child(i)
	
	for i in slots.size() - 4:
		var newSlot = slote.instantiate()
		newSlot.myId = i + 4
		newSlot.clicketLeft.connect(_slotTagetLeft)
		newSlot.clicketRight.connect(_slotTagetRight)
		# Updates the UI with existing inventory info if available
		if slots[newSlot.myId].count > 0:
			newSlot.setItem(item_list.items[slots[newSlot.myId].itemId].texture, slots[newSlot.myId].itemId, slots[newSlot.myId].count)
		cold_bar.add_child(newSlot, true)

# ---------- Slot Click Handlers ----------
# Emits a signal when a slot is clicked with the left mouse button.
func _slotTagetLeft(id: int):
	leftClickSlot.emit(id)

# Emits a signal when a slot is clicked with the right mouse button.
func _slotTagetRight(id: int):
	rightClickSlot.emit(id)

