extends MultiplayerSynchronizer

@onready var player = $".."
@onready var message_input = get_tree().get_current_scene().get_node("Chat").get_node("Background").get_node("Message")

var input_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get_unique_id gives the current id/peer it's on
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		# Check who the authority is. If the authority is not equal to the current peer it's on, shut them off
		# That means it's not running on this current client's computer. Probably the server.
		set_process(false)
		set_physics_process(false)
	
	if not message_input.has_focus():
		input_direction = Input.get_axis("left", "right")

func _physics_process(delta: float) -> void:
	if not message_input.has_focus():
		input_direction = Input.get_axis("left", "right")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("up") and not message_input.has_focus():
		jump.rpc()
		
@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
