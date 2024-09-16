extends Node

# ---------- Constants ----------
# Default game server port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10567
# The maximum number of players.
const MAX_PEERS = 15
# Debug mode toggle
const DEBUG_MODE = false

# ---------- Exported Variables ----------
@export var required_password: String = ""
@export var world_name: String = "Default World Name"

# ---------- Onready  ----------
@onready var chat_box = "$playerInfo/CanvasLayer/chatBox"

# ---------- Signals ----------
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what: int)
signal message_received(message: String)

# ---------- Variables ----------
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var player_name := "The Digger"
var players := {}
var players_ready: Array[int] = []
var banned_players := []

# ---------- Ready Function ----------
func _ready() -> void:
	if multiplayer:
		if multiplayer.is_server():
			_setup_multiplayer_signals()
			_initialize_server()
		else:
			debug_print("Node is not the server; skipping signal setup.")
	else:
		debug_print("Multiplayer object is not initialized properly.")

# Sets up the signals related to multiplayer
func _setup_multiplayer_signals() -> void:
	debug_print("Node is ready, setting up multiplayer signals")
	
	# Connect signals if not already connected
	if not multiplayer.peer_connected.is_connected(_player_connected):
		multiplayer.peer_connected.connect(_player_connected)
	
	if not multiplayer.peer_disconnected.is_connected(_player_disconnected):
		multiplayer.peer_disconnected.connect(_player_disconnected)
	
	if not multiplayer.connected_to_server.is_connected(_connected_ok):
		multiplayer.connected_to_server.connect(_connected_ok)
	
	if not multiplayer.connection_failed.is_connected(_connected_fail):
		multiplayer.connection_failed.connect(_connected_fail)
	
	if not multiplayer.server_disconnected.is_connected(_server_disconnected):
		multiplayer.server_disconnected.connect(_server_disconnected)
	
	debug_print("Multiplayer signals have been set up.")

# Initializes the server setup
func _initialize_server() -> void:
	debug_print("Setting multiplayer authority.")
	set_multiplayer_authority(multiplayer.get_unique_id())
	debug_print("Server initialized with authority.")

# ---------- Network Management ----------
# Hosts a game and sets up the server.
func host_game(new_player_name: String, password: String, new_world_name: String) -> void:
	debug_print("Hosting game as (PlayerName) with password: ", [new_player_name, password])
	player_name = new_player_name
	world_name = new_world_name
	required_password = password
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)
	set_multiplayer_authority(multiplayer.get_unique_id())
	rpc("set_world_name", world_name)

# Joins a game by connecting to a server.
func join_game(ip: String, new_player_name: String, password: String) -> void:
	debug_print("Joining game at IP: ", ip)
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	required_password = password
	
	# Disconnect before connecting the signal to avoid duplication
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
		
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_connected_to_server() -> void:
	debug_print("Connected to server, sending password.")
	send_password(required_password)

# ---------- Network Signal Callbacks ----------
# Called when a player connects to the server.
func _player_connected(id: int) -> void:
	if id in banned_players:
		debug_print("Rejected connection from banned player: %d" % id)
		multiplayer.disconnect_peer(id)
		return
	
	if id in players:
		debug_print("Player with ID: %d is already registered." % id)
		return
	
	# Handle new player registration
	rpc_id(id, "set_world_name", world_name)  # Send world name to the connected client
	register_player.rpc_id(id, player_name)
	debug_print("Player connected with ID: %d" % id)


# Called when a player disconnects from the server.
func _player_disconnected(id: int) -> void:
	if id in players:
		debug_print("Player disconnected with ID: ", id)
		broadcast_message("Player %s (ID: %d) disconnected." % [players[id], id])
		multiplayer.disconnect_peer(id)
		remove_player_node(id)
		unregister_player(id)
		player_list_changed.emit()
	else:
		debug_print("Unknown player ID disconnected: ", id)
		
	# Check if it's the host that disconnected
	if multiplayer.is_server() and id == multiplayer.get_unique_id():
		debug_print("Host disconnected, ending the game for all players.")
		broadcast_message("Host has disconnected. The game will now end.")
		end_game()

		
# Called when the client successfully connects to the server.
func _connected_ok() -> void:
	debug_print("Successfully connected to the server")
	connection_succeeded.emit()

# Called when the server disconnects.
@rpc("call_local")
func _server_disconnected() -> void:
	if multiplayer.is_server():
		debug_print("Server (host) disconnected")
		game_error.emit("Server disconnected")
		end_game()  # Server should already end the game for all clients
	else:
		debug_print("Disconnected from the server, exiting the game.")
		broadcast_message("Disconnected from the server. The game will end.")
		end_game()  # Clients should also end the game when server disconnects

# Called when the client fails to connect to the server.
func _connected_fail() -> void:
	debug_print("Failed to connect to the server")
	multiplayer.set_network_peer(null)
	connection_failed.emit()

# ---------- Player Management ----------
# Registers a new player by adding them to the players dictionary.
@rpc("any_peer")
func register_player(new_player_name: String) -> void:
	var id := multiplayer.get_remote_sender_id()

	# Check if the player being registered is the host
	if id == multiplayer.get_unique_id():
		debug_print("Host (ID: %d) is registering. Cannot be unregistered later." % id)
	else:
		debug_print("Registering player with ID: %d" % id)

	# Add the player to the players dictionary
	players[id] = new_player_name

	# Emit the player list changed signal
	player_list_changed.emit()

func unregister_player(id: int) -> void:
	# Prevent unregistering the host
	if id == multiplayer.get_unique_id():
		debug_print("Cannot unregister the host (ID: %d)." % id)
		return

	debug_print("Attempting to unregister player with ID: ", id)
	if id in players:
		players.erase(id)
		debug_print("Successfully unregistered player with ID: ", id)
		player_list_changed.emit()
	else:
		debug_print("Player ID %d does not exist in the players list." % id)
		
func get_player_name(id: int) -> String:
	if players.has(id):
		return players[id]
	else:
		return player_name
	
@rpc("authority")
func kick_and_ban_player(id: int) -> void:
	if id in banned_players:
		Console.print("Player", id, "is already banned.")
		return
	# Add to banned players list
	banned_players.append(id)
	Console.print("Player", id, "has been kicked and banned.")
	
# Function to ban a player by their ID.
@rpc("authority")	
func ban_player(player_id: int) -> void:
	if player_id not in banned_players:
		banned_players.append(player_id)
		kick_player(player_id)
		print("Player %d has been banned." % player_id)
		broadcast_message("Player %d has been banned by the host." % player_id)
	else:
		print("Player %d is already banned." % player_id)

# Function to unban a player by their ID.
@rpc("authority")
func unban_player(player_id: int) -> void:
	if player_id in banned_players:
		banned_players.erase(player_id)
		print("Player %d has been unbanned." % player_id)
	else:
		print("Player %d is not banned." % player_id)
		
# Kicks the player by disconnecting them.
@rpc("authority")
func kick_player(player_id: int) -> void:
	if player_id in players:
		_player_disconnected(player_id)
		print("Player %d has been kicked" % player_id)

func is_player_banned(player_id: int) -> bool:
	return player_id in banned_players

func get_banned_players() -> Array:
	return banned_players
	
func handle_missing_player(player_id: int) -> void:
	if multiplayer.is_server():
		# Check if player node exists
		if !get_tree().get_root().get_node("worldNode/Players").has_node(str(player_id)):
			debug_print("Player node missing for ID: ", player_id)
			# Remove player from the network and clean up
			if !multiplayer.has_peer(player_id):
				end_game()
			else:
				multiplayer.disconnect_peer(player_id)
				unregister_player(player_id)  # Clean up from internal list

# ---------- World and Gameplay Management ----------
# Set world name on clients
@rpc("authority", "call_local")
func set_world_name(new_world_name: String) -> void:
	world_name = new_world_name
	debug_print("World name set to: ", [world_name])
	
# Loads the game world scene.
@rpc("call_local")
func load_world() -> void:
	debug_print("Loading world scene") 
	var world: Node2D = load("res://src/scenes/world.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()
	get_tree().paused = false

# Begins the game, spawning player instances.
func begin_game() -> void:
	assert(multiplayer.is_server())
	debug_print("Beginning the game")
	load_world.rpc()
	var world: Node2D = get_tree().get_root().get_node("worldNode")
	var player_scene: PackedScene = preload("res://src/scenes/multiplayer_Player.tscn")
	var spawn_points := {}
	spawn_points[1] = 0
	var spawn_point_idx := 1
	if world == null:
		debug_print("World node not found.")
		return

	if player_scene == null:
		debug_print("Player scene could not be loaded.")
		return	

	# Assign spawn points to players
	for p: int in players:
		spawn_points[p] = spawn_point_idx
		print("print p", p)
		spawn_point_idx += 1

	# Spawn player instances and set their names
	for p_id: int in spawn_points:
		var spawn_point_node = world.get_node("SpawnPoints/" + str(spawn_points[p_id]))
		if spawn_point_node:
			var spawn_pos: Vector2 = spawn_point_node.position
			var player = player_scene.instantiate()
			if player:
				player.position = spawn_pos
				player.name = str(p_id)
				# Add the player node to the world
				var players_node = world.get_node("Players")
				if players_node:
					players_node.add_child(player)
				# Set the player name using the set_player_name RPC
				player.set_player_name.rpc(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
				player.set_player_name(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
				player.playerId = p_id
			else:
				debug_print("Failed to instantiate player for ID: ", p_id)
		else:
			debug_print("Spawn point node not found for ID: ", p_id)

# Ends the game, clearing all player data and world nodes.
@rpc("call_local")
func end_game() -> void:
	debug_print("Ending the game")
	if has_node("/root/worldNode"):
		get_node("/root/worldNode").queue_free()

	game_ended.emit()
	
	# Clear all player data
	players.clear()
	players_ready.clear()
	
	# Reset multiplayer peer to stop networking
	multiplayer.set_multiplayer_peer(null)
	
# ---------- Utility Functions ----------
# Sends the password to the server for verification.
@rpc("call_local")
func send_password(password: String) -> void:
	var server_id = 1	
	rpc_id(server_id, "verify_password", password, multiplayer.get_unique_id())

# Verifies the password on the server.
@rpc("any_peer")
func verify_password(password: String, id: int) -> void:
	if password == required_password:
		if multiplayer.is_server():
			register_player(player_name)  # Register the player on the server
			debug_print("Player ID %d registered with correct password." % id)
		else:
			rpc_id(1, "register_player", player_name)  # Notify the server to register the player
	else:
		debug_print("Password verification failed for player ID: %d" % id)
		if multiplayer.is_server():
			_player_disconnected(id)
		else:
			rpc_id(1, "kick_player", id)  # Notify the server to kick the player if incorrect
			end_game()  # End game for the client
		multiplayer.disconnect_peer(id)  # Disconnect the player


# Utility function to remove a player node.
@rpc("authority", "call_local")
func remove_player_node(player_id: int) -> void:
	var world = get_tree().get_root().get_node("worldNode")
	
	if world and world.has_node("Players"):
		var players_node = world.get_node("Players")
		
		if players_node.has_node(str(player_id)):
			players_node.get_node(str(player_id)).queue_free()
			debug_print("Removed player node for ID: ", player_id)
		else:
			debug_print("Player node for ID does not exist: ", player_id)
	else:
		debug_print("Players node or world node does not exist.")

# Utility function to broadcast a message to all peers.
@rpc("any_peer")
func broadcast_message(message: String):
	emit_signal("message_received", message)

# Retrieves the current player list.
func get_player_list() -> Array:
	debug_print("Current player list: ", players.values())
	return players.values()

# Generates a color for a player based on their name.
func get_player_color(p_name: String) -> Color:
	debug_print("Generating color for player name: ", p_name)
	return Color.from_hsv(wrapf(p_name.hash() * 0.001, 0.0, 1.0), 0.6, 1.0)

# Debug print function to conditionally output messages.
func debug_print(message: String, optional_value: Variant = null) -> void:
	if DEBUG_MODE:
		if optional_value:
			print(message, optional_value)
		else:
			print(message)

#func generate_random_name() -> String:
	#var adjective: Array = [
		#"awesome",
		#"handsome",
		#"busy",
		#"pensive",
		#"smart",
		#"tricky",
		#"mr",
		#"feisty",
	#]
	#var noun: Array = [
		#"lemur",
		#"alien",
		#"hamster",
		#"robot",
		#"vic",
		#"drake",
		#"sheep",
		#"mouse"
	#]
	#return "%s_%s" % [adjective.pick_random(), noun.pick_random()]
