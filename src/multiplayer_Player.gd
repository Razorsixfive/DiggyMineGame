extends CharacterBody2D

# ---------- Constants ----------
# Movement speed of the player
const SPEED = 300.0
# Jump velocity of the player
const JUMP_VELOCITY = -400.0

# ---------- Exported Variables ----------
@export var current_anim: String = "standing":
	set(newAnim):
		current_anim = newAnim
		$anim.play(newAnim)

@export var digSpeed: float = 1
@export var digRang: int = 3
@export var baseAir: int = 30
@export var baseHp: int = 30
@export var playerId: int = 1:
	set(id):
		playerId = id
		set_multiplayer_authority(playerId)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# ---------- Onready  ----------
@onready var worldNode = $"/root/worldNode"
@onready var status_bar = $"/root/worldNode/playerInfo/CanvasLayer/statusBar"
@onready var chat_box = $"/root/worldNode/playerInfo/CanvasLayer/chatBox/GridContainer/LineEdit"
@onready var item_list = $"/root/worldNode/playerInfo/itemList"
@onready var playerInfo = $"/root/worldNode/playerInfo"

# ---------- Variables ----------
var readInputes: bool = true  # Locks inputs when chat is open
var localPlayer: bool = false
var tryDigging: bool = false
var digging: bool = false
var digPoint: float
var digHp: float
var digTaget: Vector2i
var climing: bool = false
var blockAir: bool = false
var playerGridPos: Vector2i
var maxAir: int = baseAir
var remaingAir: float = baseAir:
	set(newAirLevel):
		status_bar.setAir(newAirLevel)
		remaingAir = newAirLevel
var maxHp: int = baseHp
var remaingHp: float = baseHp:
	set(newHpLevel):
		status_bar.setHp(newHpLevel)
		remaingHp = newHpLevel

# ---------- Ready Function ----------
func _ready():
	if !multiplayer.is_server():
		playerId = name.to_int()
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
		$Camera2D.enabled = false
		localPlayer = false
	else:
		set_process(true)
		set_physics_process(true)
		$Camera2D.enabled = true
		localPlayer = true
		status_bar.setMaxAir(maxAir)
		status_bar.setAir(remaingAir)
		status_bar.setMaxHp(maxHp)
		status_bar.setHp(remaingHp)
		chat_box.focus_entered.connect(blockInput)
		chat_box.focus_exited.connect(openInput)

# ---------- Input Handling ----------
func _input(event):
	if localPlayer:
		if Input.is_action_just_pressed("click"):
			tryDigging = true
			statDiging()
		elif Input.is_action_just_released("click"):
			tryDigging = false
			stopDiging()
		if Input.is_action_just_pressed("rightClick"):
			placeBlock(worldNode.posToGridPos(get_global_mouse_position()))
		if readInputes:
			if Input.is_action_just_pressed("invertory"):
				playerInfo.swapInvertoryState()
			if Input.is_action_just_pressed("hotBarSlot0"):
				playerInfo.hotBarTaget = 0
			if Input.is_action_just_pressed("hotBarSlot1"):
				playerInfo.hotBarTaget = 1
			if Input.is_action_just_pressed("hotBarSlot2"):
				playerInfo.hotBarTaget = 2
			if Input.is_action_just_pressed("hotBarSlot3"):
				playerInfo.hotBarTaget = 3

# Locks input when chat is open
func blockInput():
	readInputes = false

# Opens input when chat is closed
func openInput():
	readInputes = true

# ---------- Physics Processing ----------
func _physics_process(delta):
	var gridPos = worldNode.posToGridPos(position)
	var direction: float = 0
	var new_anim := "standing"

	if climing:
		if readInputes:
			direction = Input.get_axis("moveUp", "moveDown")
		if direction:
			velocity.y = direction * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
		if readInputes:
			if Input.is_action_just_pressed("moveJump") and is_on_floor():
				velocity.y = JUMP_VELOCITY

	if readInputes:
		direction = Input.get_axis("moveLeft", "moveRight")
	else:
		direction = 0
	if direction:
		velocity.x = direction * SPEED
		if direction > 0:
			new_anim = "walk_right"
		elif direction < 0:
			new_anim = "walk_left"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if gridPos != playerGridPos:
		playerGridPos = gridPos
		var data = worldNode.getTraineModifyer(gridPos)
		climing = data[0]
		blockAir = data[1]

	if new_anim != current_anim:
		current_anim = new_anim
	move_and_slide()

# ---------- Process Function ----------
func _process(delta):
	if tryDigging:
		diggingRun(delta)
	if blockAir:
		if remaingAir <= 0:
			print("you dead")
		remaingAir -= delta
	else:
		if baseAir > remaingAir:
			remaingAir += delta
			if baseAir <= remaingAir:
				remaingAir = baseAir

# ---------- Digging Functions ----------
func diggingRun(delta: float):
	var gridPos: Vector2i = worldNode.posToGridPos(get_global_mouse_position())
	if tryDigging:
		if (gridPos-digTaget).length_squared() <= digRang:
			if not digging:
				statDiging()
		else:
			stopDiging()
	if gridPos == digTaget:
		if digging:
			digPoint += digSpeed * delta
			var level: float = (1 / digHp) * digPoint
			if digPoint >= digHp:
				digBlock(digTaget)
				stopDiging()
			else:
				worldNode.digLevel(digTaget, level)
	else:
		stopDiging()
		statDiging()

func statDiging():
	var gridPos: Vector2i = worldNode.posToGridPos(get_global_mouse_position())
	digHp = worldNode.getBlockHp(gridPos)
	if digHp > 0:
		digging = true
		digTaget = gridPos
	else:
		digging = false
		digTaget = gridPos

func stopDiging():
	digging = false
	digPoint = 0
	worldNode.digLevel(digTaget, -1)

func digBlock(pos: Vector2i):
	worldNode.breackTile.rpc(pos)
	var dropId: int = worldNode.breackTile(pos)
	if dropId > 0:
		playerInfo.addItem(dropId - 1)

# Function to place a block at a given position
func placeBlock(pos: Vector2i):
	if worldNode.isTileFree(pos):
		var block: Vector3i = playerInfo.placeItem()
		if block.z >= 0:
			worldNode.placeTile(pos, block.z, Vector2i(block.x, block.y))
			worldNode.placeTile.rpc(pos, block.z, Vector2i(block.x, block.y))

# ---------- Player Management ----------
@rpc("any_peer")
func set_player_name(value: String) -> void:
	$label.text = value
	var player_color := gamestate.get_player_color(value)
	$label.modulate = player_color
	$sprite.modulate = Color(0.5, 0.5, 0.5) + player_color

