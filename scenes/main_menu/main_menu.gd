extends CanvasLayer

func _on_button_pressed() -> void:
	var twitch_channel: String = %ChannelLineEdit.text.strip_edges()
	if twitch_channel.length() > 0:
		if VerySimpleTwitch._twitch_chat:
			VerySimpleTwitch._twitch_chat = null
			
		VerySimpleTwitch.login_chat_anon(twitch_channel)
		get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
