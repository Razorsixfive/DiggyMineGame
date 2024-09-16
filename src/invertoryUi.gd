extends PanelContainer

var slote = preload("res://item/uiInvertorySlot.tscn")

@onready var item_list = $"../../itemList"

#linker op til de 2 menus som opgøre den grafisker del af inv
@onready var cold_bar = $GridContainer/coldBar/GridContainer
@onready var hot_bar = $GridContainer/hotBar/GridContainer

#styer om inv er exter space er sylinger eller ikke
func open():
	cold_bar.show()
func close():
	cold_bar.hide()

signal leftClickSlot(id: int)
signal rightClickSlot(id: int)

#finder den andgivet slot i hotbar og angiver om det er den der skal hiligters
func setSlotFucos(slot: int,taget: bool):
	var inv = hot_bar.get_children()
	inv[slot].fousce = taget
	
#setter inhold af ui slot så den paser til inv slots for at user kan se ders inv
func setSlot(slot: int,item: invertorySlot):
	#tjeker om det er hot bar slot
	if slot <= 3:
		var inv = hot_bar.get_children()
		#tjek om item alread er loadet so vi ikke load texture vis den alrader er der
		if inv[slot].antal > 0:
			inv[slot].antal = item.count
		else:
			inv[slot].setItem(item_list.items[item.itemId].texture,item.itemId,item.count)
	#siden det ikke er på hotbar så må det være den normal inv
	else:
		var inv = cold_bar.get_children()
		slot -= 4
		#tjek om item alread er loadet so vi ikke load texture vis den alrader er der
		if inv[slot].antal > 0:
			inv[slot].antal = item.count
		else:
			inv[slot].setItem(item_list.items[item.itemId].texture,item.itemId,item.count)

#clear og rebuilder inv ui så den har same size som inv og sikker at alt er connet som det skal
func LoadInvertory(slots: Array[invertorySlot]):
	#fjener all hotbare slots
	var inv = hot_bar.get_children()
	for i in inv:
		hot_bar.remove_child(i)
	
	#byger hot bar og linker og configer den så den er klar til bruger
	for i in 4:
		var newSlot = slote.instantiate()
		newSlot.myId = i
		newSlot.clicketLeft.connect(_slotTagetLeft)
		newSlot.clicketRight.connect(_slotTagetRight)
		#vis der er noget i inv bliver inv-ui update med det ratiger info
		if slots[newSlot.myId].count > 0:
			newSlot.setItem(item_list.items[slots[newSlot.myId].itemId].texture,slots[newSlot.myId].itemId,slots[newSlot.myId].count)
		hot_bar.add_child(newSlot, true)
	
	#fjener all slots som ikke er hotbar
	inv = cold_bar.get_children()
	for i in inv:
		cold_bar.remove_child(i)
	
	for i in slots.size() - 4:
		var newSlot = slote.instantiate()
		newSlot.myId = i+4
		newSlot.clicketLeft.connect(_slotTagetLeft)
		newSlot.clicketRight.connect(_slotTagetRight)
		#vis der er noget i inv bliver inv-ui update med det ratiger info
		if slots[newSlot.myId].count > 0:
			newSlot.setItem(item_list.items[slots[newSlot.myId].itemId].texture,slots[newSlot.myId].itemId,slots[newSlot.myId].count)
		cold_bar.add_child(newSlot, true)

#send et signal til inv når der er nogler der kliger på invUI slote
func _slotTagetLeft(id: int):
	leftClickSlot.emit(id)
func _slotTagetRight(id: int):
	rightClickSlot.emit(id)
