extends CharacterAction
class_name FlipActionC

func _init() -> void:
	component_name = "FlipActionC"
	action_name = "Flip"
	commands = ['!flip', '!f']
	
func _on_twitch_message(data: Chatter):
	if GameManager.current_phase != GameManager.GamePhase.PLANNING:
		return
	
	var character: Character = get_parent()
	if not is_player_character(data):
		return
	
	if command_valid(data):
		if character.can_free_flip == true:
			character.free_flip_used = true
			return
	
	super._on_twitch_message(data)

func apply_action() -> void:
	var character: Character = get_parent()
	character.set_facing(not character._facing_left)
	await get_tree().create_timer(2).timeout
	action_ended.emit()
