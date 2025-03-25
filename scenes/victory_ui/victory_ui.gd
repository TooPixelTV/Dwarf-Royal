extends CanvasLayer

const CHARACTER = preload("res://scenes/character/character.tscn")
const MAIN_THEME = preload("res://assets/main_theme.tres")
const LOBBY = preload("res://scenes/lobby/lobby.tscn")

func _ready() -> void:
	_init_list()
	
func _init_list():	
	for winner in GameManager.winners:
		var char_label: Label = Label.new()
		char_label.custom_minimum_size.y = 120
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.text = winner.display_name
		char_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_label.theme = MAIN_THEME
		char_label["theme_override_colors/font_outline_color"] = Color.from_string("282e3b", "white")
		char_label["theme_override_constants/outline_size"] = 25
		%WinnersList.add_child(char_label)
		
		call_deferred("display_character", char_label, winner)


func display_character(char_label: Label, winner: Player):
	var character = CHARACTER.instantiate()
	character.display_infos = false
	character.player = winner
	%Characters.add_child(character)
	character.global_position = char_label.global_position
	character.position.x += 65
	character.position.y += 45


func _on_restart_btn_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_packed(LOBBY)
