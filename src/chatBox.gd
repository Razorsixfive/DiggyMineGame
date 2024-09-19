extends PanelContainer

# ---------- Onready Nodes ----------
@onready var rich_text_label = $GridContainer/RichTextLabel
@onready var line_edit = $GridContainer/LineEdit

# ---------- Exported Variables ----------
@export var userName: String = "new"  # Default name, should be set when the game starts

# ---------- Functions ----------
# Adds a new message to the chat.
@rpc("any_peer", "reliable")
func addToText(text: String, id: int):
	var user_name = gamestate.get_player_name(id)
	text = "\n" + user_name + ": " + text
	rich_text_label.text += text

# Called when the chat input receives an "enter" key press.
func _on_line_edit_text_submitted(new_text):
	var text = line_edit.text
	# Clears text to prepare for the next input
	line_edit.clear()
	# Hides and shows the line edit to remove focus without transferring it to another element
	line_edit.hide()
	line_edit.show()
	# Sends message to all peers on the server and then to self to keep it in sync
	var id = multiplayer.get_unique_id()  # Get the player's unique ID
	addToText.rpc(text, id)
	addToText(text, id)


