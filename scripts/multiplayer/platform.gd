extends AnimatableBody2D

@export var animation_player_optional: AnimationPlayer

func _on_player_connected(id):
	# If we're on the client, stop the animation player
	if not multiplayer.is_server():
		animation_player_optional.stop()
		animation_player_optional.set_active(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# If we have an animation player, we need to kill it on the client.
	# Run it on the server so the platform is synchronized across all clients
	if animation_player_optional:
		multiplayer.peer_connected.connect(_on_player_connected)
