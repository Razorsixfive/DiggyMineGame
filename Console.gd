extends CanvasLayer

class_name Console

# ---------- Exported Variables ----------
@export var is_console_visible: bool = false

# ---------- Static Variables ----------
static var consoleRt: RichTextLabel = null
static var _commands: Dictionary = {}

# ---------- Variables ----------
var cmd_input: LineEdit = null
var _command_history: Array[String] = []
var _command_from_history_index: int = -1

# ---------- Ready Function ----------
func _ready() -> void:
	consoleRt = get_node('Container/VBoxContainer/ConsoleRt') as RichTextLabel
	cmd_input = get_node('Container/VBoxContainer/Cmd') as LineEdit

	if is_console_visible:
		show()
	else:
		hide()

	_create_toggle_key()
	_initialize_commands()

# ---------- Toggle Console Visibility ----------
func _create_toggle_key() -> void:
	var input_event = InputEventKey.new()
	input_event.set_keycode(KEY_F3)
	InputMap.add_action('toggle_console')
	InputMap.action_add_event('toggle_console', input_event)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed('toggle_console'):
		if visible:
			hide()
		else:
			show()
			cmd_input.set_text('')
			cmd_input.grab_focus.call_deferred()

	if cmd_input.has_focus():
		if Input.is_action_just_pressed('ui_text_completion_accept'):
			_exec()
		elif Input.is_action_just_pressed('ui_up'):
			_get_command_from_history(1)
		elif Input.is_action_just_pressed('ui_down'):
			_get_command_from_history(-1)

# ---------- Command Management ----------
static func add_command(_name: String, exec: Callable, param_types: Array[String] = [], description: String = '') -> void:
	_commands[_name] = {
		'description': description,
		'exec': exec,
		'param_types': param_types
	}

static func remove_command(_name: String) -> void:
	_commands.erase(_name)

# ---------- Console Output ----------
static func print(
	arg0: Variant = null, arg1: Variant = null, arg2: Variant = null, arg3: Variant = null,
	arg4: Variant = null, arg5: Variant = null, arg6: Variant = null, arg7: Variant = null,
	arg8: Variant = null, arg9: Variant = null, arg10: Variant = null, arg11: Variant = null
) -> void:
	var args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11]
	var _text: String = '\n'
	for arg in args:
		if arg == null:
			break
		_text += str(arg) + ' '

	if consoleRt and consoleRt is RichTextLabel:
		consoleRt.append_text(_text)
	else:
		print("Warning: consoleRt not initialized!")

# ---------- Command Execution ----------
func _exec() -> void:
	var command: String = cmd_input.get_text()
	cmd_input.set_text('')
	_command_from_history_index = -1

	Console.print('Debug: Executing Command -', command)

	var cmdArr: PackedStringArray = command.split(' ')
	Console.print('Debug: Command Array -', cmdArr)

	if cmdArr.size() > 0 and _commands.has(cmdArr[0]):
		var cmdParams: Array = []
		for param_i in range(1, cmdArr.size()):
			var param = cmdArr[param_i]
			if param_i - 1 < _commands[cmdArr[0]].param_types.size():
				match _commands[cmdArr[0]].param_types[param_i - 1]:
					'int':
						param = int(cmdArr[param_i])
					'float':
						param = float(cmdArr[param_i])
					'bool':
						param = ['1', 'true', 'TRUE', 'True'].has(cmdArr[param_i])
					'String':
						param = cmdArr[param_i]
			cmdParams.append(param)

		Console.print('>', command)
		Console.print('Debug: Params -', cmdParams)

		if _commands[cmdArr[0]].exec is Callable:
			_commands[cmdArr[0]].exec.callv(cmdParams)
		else:
			Console.print('Error: Command exec is not callable')
	else:
		Console.print('>', command, '[color=#d15d5d]', 'command not found.', '[/color]')

	if command != '' and (_command_history.size() == 0 or command != _command_history[0]):
		_command_history.push_front(command)

func _get_command_from_history(direction: int) -> void:
	var history_size: int = _command_history.size()
	if _command_from_history_index >= -1 and _command_from_history_index < history_size:
		_command_from_history_index = clampi(_command_from_history_index + direction, -1, history_size - 1)
		if _command_from_history_index == -1:
			cmd_input.set_text('')
		else:
			cmd_input.set_text(_command_history[_command_from_history_index])

# ---------- Built-in Commands ----------
func _initialize_commands() -> void:
	_commands = {
		'help': {
			'description': 'Show all the commands',
			'exec': _help,
			'param_types': []
		},
		'clear': {
			'description': 'Clear the console',
			'exec': _clear,
			'param_types': []
		},
		'is_host': {
			'description': 'Check if this console is on the hosting server',
			'exec': _is_host,
			'param_types': []
		},
		'players': {
			'description': 'List all connected players',
			'exec': _list_players,
			'param_types': []
		},
		'world_name': {
			'description': 'Show the current world name',
			'exec': _get_world_name,
			'param_types': []
		},
		'ban_player': {
			'description': 'Ban a player by their unique ID',
			'exec': _ban_player,
			'param_types': ['int']
		},
		'unban_player': {
			'description': 'Unban a player by their unique ID',
			'exec': _unban_player,
			'param_types': ['int']
		},
		'list_banned': {
			'description': 'List all banned players',
			'exec': _list_banned_players,
			'param_types': []
		},
		'get_network_info': {
			'description': 'Display current network info',
			'exec': _get_network_info,
			'param_types': []
		},
		'reset': {
			'description': 'Reset the game state',
			'exec': _reset,
			'param_types': []
		}
	}

func _help() -> void:
	Console.print('---------------------')
	for command in _commands.keys():
		var params = ''
		for param: String in _commands[command].param_types:
			params += '[' + param + '] '
		Console.print('[color=#62b769]', command, params, '[/color]', '-', _commands[command].description)
	Console.print('---------------------')

func _clear() -> void:
	if consoleRt and consoleRt is RichTextLabel:
		consoleRt.clear()
	else:
		print("Warning: consoleRt not initialized!")

func _is_host() -> void:
	if multiplayer.is_server():
		Console.print("This console is on the hosting server.")
	else:
		Console.print("This console is NOT on the hosting server.")

func _list_players() -> void:
	if has_node("/root/gamestate"):
		var gamestate = get_node("/root/gamestate")
		var players_dict = gamestate.players
		
		# Get the local player's ID (assuming there's a way to get it)
		var local_player_id = multiplayer.get_unique_id()

		# Print local player's info first
		Console.print("Your Player Info: ID:", local_player_id)

		# Print all connected players
		Console.print('Connected players:')
		for player_id in players_dict.keys():
			var player_name = players_dict[player_id]
			if player_id == local_player_id:
				continue  # Skip the local player, since we've already printed their info
			Console.print(' - ID:', player_id, ', Name:', player_name)
	else:
		Console.print('Error: Gamestate node not found.')


func _get_world_name() -> void:
	if has_node("/root/gamestate"):
		var world_name = get_node("/root/gamestate").world_name
		Console.print('Current World Name:', world_name)
	else:
		Console.print('Error: Gamestate node not found.')

func _ban_player(player_id: int) -> void:
	if has_node("/root/gamestate"):
		var gamestate = get_node("/root/gamestate")
		gamestate.ban_player(player_id)
		Console.print("Player", player_id, "has been banned.")
	else:
		Console.print("Error: Gamestate node not found.")

func _unban_player(player_id: int) -> void:
	if has_node("/root/gamestate"):
		var gamestate = get_node("/root/gamestate")
		gamestate.unban_player(player_id)
		Console.print("Player", player_id, "has been unbanned.")
	else:
		Console.print("Error: Gamestate node not found.")

func _list_banned_players() -> void:
	if has_node("/root/gamestate"):
		var gamestate = get_node("/root/gamestate")
		var banned_players = gamestate.get_banned_players()
		if banned_players.size() > 0:
			Console.print('Banned Players:')
			for player_id in banned_players:
				Console.print(' - ', player_id)
		else:
			Console.print('No players are currently banned.')
	else:
		Console.print('Error: Gamestate node not found.')

func _get_network_info() -> void:
	# Print general network info
	Console.print('Network Info:')
	Console.print(' - Server:', multiplayer.is_server())
	Console.print(' - Client:', multiplayer.is_client())
	
	# Get and print network peers
	var peers = multiplayer.get_connected_peers()
	Console.print(' - Network peers:', peers)

func _reset():
	if has_node("/root/gamestate"):
		get_node("/root/gamestate").end_game()
		Console.print('Game state reset.')
		_list_banned_players()
	else:
		Console.print('Error: Gamestate node not found.')
