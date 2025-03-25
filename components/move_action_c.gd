extends CharacterAction
class_name MoveActionC


func _init() -> void:
	component_name = "MoveActionC"
	action_name = "Move"
	commands = ["!walk", "!move"]

func apply_action():
	var character: Character = get_parent()
	var mine_section: MineSection = GameManager.locate_character(character)
	if mine_section:
		character.move_ended.connect(action_ended.emit, Object.CONNECT_ONE_SHOT)
		var floor_type: MineSection.FloorType = mine_section.find_character(character)
		if character._facing_left:
			if mine_section.section_index > 0:
				var target_section: MineSection = GameManager.get_section_by_index(mine_section.section_index - 1)
				if target_section:
					target_section.add_character(character, floor_type, MineSection.SideType.RIGHT)
			else:
				action_ended.emit()
				return;
		else:
			if mine_section.section_index < GameManager.max_sections - 1:
				var target_section: MineSection = GameManager.get_section_by_index(mine_section.section_index + 1)
				if target_section:
					target_section.add_character(character, floor_type, MineSection.SideType.LEFT)
			else:
				action_ended.emit()
				return;
	else:
		action_ended.emit()
