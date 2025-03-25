extends CanvasLayer

func _on_pause_btn_pressed() -> void:
	%PauseUI.visible = not %PauseUI.visible
	get_tree().paused = %PauseUI.visible


func _on_quit_btn_pressed() -> void:
	GameManager.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
