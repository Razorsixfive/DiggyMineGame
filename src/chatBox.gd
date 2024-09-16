extends PanelContainer

@onready var rich_text_label = $GridContainer/RichTextLabel
@onready var line_edit = $GridContainer/LineEdit

@export var userName: String = "new"  # Default name, should be set when the game starts

#tilføjer den nyer mgs til chat
@rpc("any_peer", "reliable")
func addToText(text: String, id: int):
	var user_name = gamestate.get_player_name(id)
	text = "\n" + user_name + ": " + text
	rich_text_label.text += text

#køre når chat input få "enter" tryket
func _on_line_edit_text_submitted(new_text):
	var text = line_edit.text
	#fjener text så den er klar til næster gang
	line_edit.clear()
	#gemmer og gør input syliger igen får at tivger fuckus væk uden at giver den til et andet element
	line_edit.hide()
	line_edit.show()
  #send beskder til all på server og der efter til siger self for at holder det i sync
	var id = multiplayer.get_unique_id()  # Get the player's unique ID
	addToText.rpc(text, id)
	addToText(text,id)

