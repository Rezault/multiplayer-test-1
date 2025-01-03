extends Node

const SERVER_PORT = 8080

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)
var username

var players = {}

func become_host(uname):
	print("Starting host!")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	# Set global username
	username = uname
	
	_remove_single_player()
	_add_player_to_game(1)
	_set_username(1, uname)
	
	upnp_setup()
	
func join_as_player_2(uname, ip):
	print("Player 2 joining: " + uname)
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	# Set global username
	username = uname
	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(ip, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer
	
	# Listen for the server's confirmation of connection
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	_remove_single_player()

func _on_connected_to_server():
	print("Connected to server, sending username " + username)
	_send_username_to_server()
	
	#for player in _players_spawn_node.get_children():
		#player.get_node("AudioManager").setupAudio()

func _add_player_to_game(id):
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	
	# Set up audio
	player_to_add.get_node("AudioManager").set_multiplayer_authority(id)
	player_to_add.get_node("AudioManager").setupAudio(id)
	
	await get_tree().create_timer(1.0).timeout
	_setup_audio_for_new_player.rpc(id)
	_setup_audio_for_existing_players.rpc_id(id)
	#for p in _players_spawn_node.get_children():
		#if p.has_node("AudioManager"):
			#p.get_node("AudioManager").set_multiplayer_authority(id)
			## Notify new player about existing player, including self
			#_setup_audio_for_existing_player.rpc_id(id, str(p.name))
			#
			## Notify existing players about new player
			#_setup_audio_for_new_player.rpc_id(int(str(p.name)), id)

	#rpc_id(id, "_setup_audio_remote", id)
	#_setup_audio_remote.rpc(id)

func _del_player(id):
	print("Player %s left the game!" % id)
	if id in players:
		players.erase(id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	
func _remove_single_player():
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()

@rpc("any_peer", "call_local")
func _set_username(id, uname):
	_chat_new_message.rpc("SERVER", uname + " has joined the server.")
	players[id] = uname
	if _players_spawn_node:
		var plr = _players_spawn_node.get_node(str(id))
		plr.username = uname
		
		_update_usernames.rpc(players)
		#for p in _players_spawn_node.get_children():
			#_update_usernames.rpc_id(str(p.name).to_int(), players)
	
func _send_username_to_server():
	_set_username.rpc_id(1, multiplayer.get_unique_id(), username)

@rpc("any_peer", "call_local")
func _update_usernames(server_players):
	var local_id = str(multiplayer.get_unique_id())
	if _players_spawn_node:
		for id in server_players:
			var uname = server_players[id]
			var player = _players_spawn_node.get_node(str(id))
			if player:
				player.get_node("Username").text = uname

func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
		
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
		
	var map_result = upnp.add_port_mapping(SERVER_PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join address: %s" % upnp.query_external_address())

# Chat stuff
func send_message_to_server(message):
	receive_client_message.rpc_id(1, multiplayer.get_unique_id(), message)
	
@rpc("any_peer", "call_local")
func receive_client_message(sender_id, message):
	var sender = players[sender_id]
	_chat_new_message.rpc(sender, message)

@rpc("any_peer", "call_local")
func _chat_new_message(sender, message):
	var chat = get_tree().get_current_scene().get_node("Chat")

	var message_template = chat.get_node("Background").get_node("MessageTemplate")
	var label = message_template.duplicate()
	label.visible = true
	label.text = "[" + sender + "]: " + message
		
	var list_layout = chat.get_node("Background").get_node("ScrollContainer").get_node("ListLayout")
	list_layout.add_child(label)

@rpc("any_peer")
func _setup_audio_for_existing_players():
	for plr in _players_spawn_node.get_children():
		if int(str(plr.name)) != multiplayer.get_unique_id():
			if plr.has_node("AudioManager"):
				var plrId = int(str(plr.name))
				plr.get_node("AudioManager").set_multiplayer_authority(plrId)
				plr.get_node("AudioManager").setupAudio(plrId)
		
@rpc("any_peer")
func _setup_audio_for_new_player(id):
	id = str(id)
	var plr = _players_spawn_node.get_node(id)
	if plr:
		plr.get_node("AudioManager").set_multiplayer_authority(int(id))
		plr.get_node("AudioManager").setupAudio(int(id))
