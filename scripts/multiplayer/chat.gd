extends CanvasLayer

@onready var message_template: Label = $Background/MessageTemplate
@onready var list_layout: VBoxContainer = $Background/ScrollContainer/ListLayout
@onready var message: LineEdit = $Background/Message
@onready var scroll_container: ScrollContainer = $Background/ScrollContainer

var Debounce = false

func _input(ev):
	if ev is InputEventMouseButton and ev.pressed:
		if not message.get_global_rect().has_point(ev.position):
			unfocus_line_edit()
	elif Input.is_key_pressed(KEY_SLASH) and not message.has_focus():
		message.grab_focus()
		await get_tree().create_timer(0.01).timeout
		message.text = ""
	elif Input.is_key_pressed(KEY_ENTER) and message.has_focus():
		unfocus_line_edit()
		if message.text != "" and not Debounce:
			Debounce = true
			MultiplayerManager.send_message_to_server(message.text)
			message.text = ""
			Debounce = false

func unfocus_line_edit():
	if message.has_focus():
		message.release_focus()  # Unfocus the LineEdit

func _on_list_layout_child_entered_tree() -> void:
	await get_tree().create_timer(0.1).timeout
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
