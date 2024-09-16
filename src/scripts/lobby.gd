extends Control

# ---------- Constants ----------
const DEBUG_MODE = false

# ---------- Variables ----------
@onready var password := %_password
@onready var world_name_input := %_WorldName

# ---------- Ready ----------
# Called when the node is added to the scene.
func _ready() -> void:
	debug_print("Ready: Setting up signal connections")
	# Connect signals from the gamestate to corresponding functions.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)
	gamestate.player_list_changed.connect(refresh_lobby)
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	# Set the player name according to the system username. Fallback to the path.
	_set_player_name()

# ---------- Player Name Setup ----------
func _set_player_name() -> void:
	if OS.has_environment("USERNAME"):
		debug_print("Found USERNAME environment variable.")
		%Name.text = OS.get_environment("USERNAME")
	else:
		debug_print("USERNAME not found, using desktop path as fallback.")
		var desktop_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/").split("/")
		%Name.text = desktop_path[desktop_path.size() - 2]

# ---------- Button Signals ----------
func _on_host_pressed() -> void:
	debug_print("Host button pressed")
	# Validate player name
	if %Name.text == "":
		debug_print("Error: Player name is invalid")
		$Connect/ErrorLabel.text = "Invalid name!"
		return
		
	# Get inputs and validate
	var password = password.text
	var world_name = world_name_input.text
	if world_name == "":
		world_name = "Best world"

	# Hide connect UI, show player UI, and reset error label.
	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	# Host game with the provided player name.
	var player_name: String = %Name.text
	debug_print("Hosting game with player name:", player_name)
	debug_print("Hosting game with world name:", world_name)
	gamestate.host_game(player_name, password, world_name)

	# Update window title to reflect hosting status.
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Server (%s)" % player_name
	refresh_lobby()

func _on_join_pressed() -> void:
	debug_print("Join button pressed")
	# Validate player name
	if %Name.text == "":
		debug_print("Error: Player name is invalid")
		$Connect/ErrorLabel.text = "Invalid name!"
		return
		
	# Validate IP address
	if not $Connect/IPAddress.text.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	var ip: String = $Connect/IPAddress.text
	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true 

	# Join game with the provided IP and player name.
	var player_name: String = %Name.text 
	debug_print("Joining game at IP:", ip)
	debug_print("+ with player name:", player_name)
	gamestate.join_game(ip, player_name, password.text)

	# Update window title to reflect joining status.
	get_window().title = ProjectSettings.get_setting("application/config/name") + ": Client (%s)" % player_name


func _on_start_pressed() -> void:
	debug_print("Start button pressed")
	gamestate.begin_game()

func _on_find_public_ip_pressed() -> void:
	debug_print("Finding public IP")
	OS.shell_open("https://icanhazip.com/")

# ---------- Network Signal Callbacks ----------
func _on_connection_success() -> void:
	debug_print("Connection succeeded")
	$Connect.hide()
	$Players.show()

func _on_connection_failed() -> void:
	debug_print("Connection failed")
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")

func _on_game_ended() -> void:
	debug_print("Game ended")
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_game_error(errtxt: String) -> void:
	debug_print("Game error occurred:", errtxt)
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

# ---------- Utils ----------
func refresh_lobby() -> void:
	debug_print("Refreshing lobby")
	var players := gamestate.get_player_list()
	players.sort()
	
	# Clear and update player list
	$Players/List.clear()
	$Players/List.add_item(gamestate.player_name + " (you)")
	for p: String in players:
		$Players/List.add_item(p)

	# Enable/disable start button based on server status.
	$Players/Start.disabled = not multiplayer.is_server()

# Helper function for debug prints
func debug_print(message: String, optional_value: Variant = null) -> void:
	if DEBUG_MODE:
		if optional_value:
			print(message, optional_value)
		else:
			print(message)

