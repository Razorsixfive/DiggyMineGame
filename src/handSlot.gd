extends PanelContainer

# ---------- Onready Nodes ----------
@onready var label = $Label
@onready var itemT = $TextureRect

# ---------- Exported Variables ----------
@export var itemId: int = 0
@export var count: int = 0:
	set(newCount):
		if newCount > 0:
			show()
			# Enable mouse tracking
			set_physics_process(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			# Show counter only if there is more than one item
			if newCount > 1:
				label.text = str(newCount)
				label.show()
			else:
				label.hide()
		else:
			hide()
			# Disable mouse tracking
			set_physics_process(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		count = newCount

# ---------- Ready Function ----------
func _ready():
	# Initializes counter to 0 so everything is in the correct state when the game starts
	count = 0

# ---------- Physics Processing ----------
# Makes the item follow the mouse. Physics processing is disabled when there is no item.
func _physics_process(delta):
	position = get_global_mouse_position() - Vector2(32, 32)

# ---------- UI Updates ----------
# Updates the values for the UI
func setHand(img: Texture2D, Id: int, antal: int):
	count = antal
	itemId = Id
	itemT.texture = img
