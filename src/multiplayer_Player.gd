extends CharacterBody2D

#laver referrancer til ander nodes som kommer til at bliver bruget af player så som world og ui updating
@onready var worldNode = $"/root/worldNode"
@onready var status_bar = $"/root/worldNode/playerInfo/CanvasLayer/statusBar"
@onready var chat_box = $"/root/worldNode/playerInfo/CanvasLayer/chatBox/GridContainer/LineEdit"
@onready var item_list = $"/root/worldNode/playerInfo/itemList"
@onready var playerInfo = $"/root/worldNode/playerInfo"


#setter player movemt speed og jump power
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

#her bruger vi et string til at set vilken player animatin som skal brugers når var bliver update om det er fra sync-node eller fra local code vil den update animatin automatisk så det altid er i sync mellem aller spiller
@export var current_anim: String = "standing":
	set(newAnim):
		current_anim = newAnim
		$anim.play(newAnim)

#låser inputs når chat is open 
var readInputes: bool = true
#nem måder at tjekker om denner spiller er din eller en ander spiller
var localPlayer: bool = false

#diging valuers
var tryDigging: bool = false
var digging: bool = false
var digPoint: float
@export var digSpeed: float = 1
@export var digRang: int = 3
var digHp: float
var digTaget: Vector2i

#player modfyers
var climing: bool = false
var blockAir: bool = false
var playerGridPos: Vector2i

#player stats
@export var baseAir:int = 30
var maxAir: int = baseAir
var remaingAir: float = baseAir:
	set(newAirLevel):
		status_bar.setAir(newAirLevel)
		remaingAir = newAirLevel

@export var baseHp:int = 30
var maxHp: int = baseHp
var remaingHp: float = baseHp:
	set(newHpLevel):
		status_bar.setHp(newHpLevel)
		remaingHp = newHpLevel

#seter id af spiller så clinet self har control over denner node
@export var playerId: int = 1:
	set(id):
		playerId = id
		set_multiplayer_authority(playerId)
		

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#køre denner koder når denner node og all dens child nodes er loadet
func _ready():
	#tjeker om det er en clinet siden server alrader har id for vilken user den her tilhøre men clinet skal også vider det så den ved vilken den kan sender data på
	if !multiplayer.is_server():
		playerId = name.to_int()
	#tjekker om det her er din player for setup
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		#vis det ikke er din sluker den all clinet ting så som inputs, physics og så vider 
		set_process(false)
		set_physics_process(false)
		$Camera2D.enabled = false
		localPlayer = false
	else:
		#derimode vis det her er din spiller setter den ui elmenter og connetrs up
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

#låser player input når chat er open
func blockInput():
	readInputes = false
func openInput():
	readInputes = true


#event som bliver bruget for player inputs med untaglser af player movemt
func _input(event):
	#tjeker om det er din spiller
	if localPlayer:
		#starter mining state all blockes der bliver hovert over vil bliver mind intil knapen bliver released
		if Input.is_action_just_pressed("click"):
			tryDigging = true
			statDiging()
		#stopper mining state
		elif Input.is_action_just_released("click"):
			tryDigging = false
			stopDiging()
		#bruger item der er i vaglet slot
		if Input.is_action_just_pressed("rightClick"):
			placeBlock(worldNode.posToGridPos(get_global_mouse_position()))
		#tjeker om chat felt er open
		if readInputes:
			#show/hide inv
			if Input.is_action_just_pressed("invertory"):
				playerInfo.swapInvertoryState()
			#seter vilken slot right click vil bruger
			if Input.is_action_just_pressed("hotBarSlot0"):
				playerInfo.hotBarTaget = 0
			if Input.is_action_just_pressed("hotBarSlot1"):
				playerInfo.hotBarTaget = 1
			if Input.is_action_just_pressed("hotBarSlot2"):
				playerInfo.hotBarTaget = 2
			if Input.is_action_just_pressed("hotBarSlot3"):
				playerInfo.hotBarTaget = 3

#køre player move inputs og tager sig af at mover player baaset on state af player så som staires
func _physics_process(delta):
	#convter player pos til grid pos så jeg kan tjekker hvad effect der er på en givet tile
	var gridPos = worldNode.posToGridPos(position)
	var direction: float = 0
	#setter vilken anime som spiller defaulter til
	var new_anim := "standing"

	#tjeker om spiler er i en tile hvor at spiler kan kravler op og ned
	if climing:
		#tjeker om chat er open
		if readInputes:
			direction = Input.get_axis("moveUp", "moveDown")
		if direction:
			velocity.y = direction * SPEED
		else:
			velocity.y = move_toward(velocity.y, 0, SPEED)
	else:
		#tjeker om spiler er i luften for at slå graviti til
		if not is_on_floor():
			velocity.y += gravity * delta
		#tjeker om chat er open
		if readInputes:
			#vis player presser jump tjeker den om spiler er på jorend så man ikke kan jump når man er i luften
			if Input.is_action_just_pressed("moveJump") and is_on_floor():
				velocity.y = JUMP_VELOCITY

	#tjeker om chat er open
	if readInputes:
		direction = Input.get_axis("moveLeft", "moveRight")
	else:
		direction = 0
	#tjeker om direction ikke er 0 siden resten ikke er nøvdiger vis der ikke er noget input
	if direction:
		velocity.x = direction * SPEED
		#setter animtion bast på input
		if direction > 0:
			new_anim = "walk_right"
		elif direction < 0:
			new_anim = "walk_left"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#tjeker om grid pos er det sammer som den gammel pos så jeg kun update envimter når der er en ny tile
	if gridPos != playerGridPos:
		playerGridPos = gridPos
		#henter modfyers for givet tile
		var data = worldNode.getTraineModifyer(gridPos)
		#gemmer data i player fra tile modfires
		climing = data[0]
		blockAir = data[1]

	#updater kun anime når der er en ny for at misker hvor ofter den bliver update
	if new_anim != current_anim:
		current_anim = new_anim
	#køre game engine physics på denner spiller(køre kun local rasten bliver send over net)
	move_and_slide()

#køre diging, luft og hp systemer
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
			digPoint += digSpeed*delta
			var level: float = (1/digHp)*digPoint
			if digPoint >= digHp:
				digBlock(digTaget)
				stopDiging()
			else:
				worldNode.digLevel(digTaget,level)
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
	worldNode.digLevel(digTaget,-1)

func digBlock(pos: Vector2i):
	worldNode.breackTile.rpc(pos)
	var dropId: int = worldNode.breackTile(pos)
	if dropId > 0:
		playerInfo.addItem(dropId-1)
func placeBlock(pos: Vector2i):
	if worldNode.isTileFree(pos):
		var block: Vector3i = playerInfo.placeItem()
		if block.z >= 0:
			worldNode.placeTile(pos,block.z,Vector2i(block.x,block.y))
			worldNode.placeTile.rpc(pos,block.z,Vector2i(block.x,block.y))
			

#seter name og faver på denner figuer hvor faven er lavet base på navent af spillen
@rpc("any_peer")
func set_player_name(value: String) -> void:
	$label.text = value
	var player_color := gamestate.get_player_color(value)
	$label.modulate = player_color
	$sprite.modulate = Color(0.5, 0.5, 0.5) + player_color
