extends CanvasLayer

func _ready() -> void:
	%EnableLifesCheckbox.button_pressed = GameManager.enable_lifes

func _on_button_pressed() -> void:
	var twitch_channel: String = %ChannelLineEdit.text.strip_edges()
	if twitch_channel.length() > 0:
		if VerySimpleTwitch._twitch_chat:
			VerySimpleTwitch._twitch_chat = null
			
		VerySimpleTwitch.login_chat_anon(twitch_channel)
		get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")


func _on_enable_lifes_checkbox_toggled(toggled_on: bool) -> void:
	GameManager.enable_lifes = toggled_on
