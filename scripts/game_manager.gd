extends Node

var score = 0
@onready var coins_label: Label = $CoinsLabel

func add_point():
	score += 1
	coins_label.text = "You collected " + str(score) + " coins!"
	
func become_host():
	var username = %MultiplayerHUD/Panel/VBoxContainer/Username.text
	if username == "":
		return
		
	%MultiplayerHUD.hide()
	%Chat.show()
	MultiplayerManager.become_host(username)
	
func join_as_player_2():
	var username = %MultiplayerHUD/Panel/VBoxContainer/Username.text
	if username == "":
		return
		
	var ip = %MultiplayerHUD/Panel/VBoxContainer/GameCode.text
	if ip == "":
		ip = "127.0.0.1"
		
	%MultiplayerHUD.hide()
	%Chat.show()
		
	MultiplayerManager.join_as_player_2(username, ip)
