extends CharacterAction
class_name UpDownActionC

func _init() -> void:
	component_name = "UpDownActionC"
	action_name = "Up/Down"
	commands = ['!up', '!down']


func apply_action():
	var character: Character = get_parent()
	var mine_section: MineSection = GameManager.locate_character(character)
	if mine_section:
		var floor_type: MineSection.FloorType = mine_section.find_character(character)
		
		var middle_pos = character.position
		middle_pos.x = mine_section.section_width * mine_section.section_index + mine_section.section_width / 2
		character.move_ended.connect(func (): _end_movement(mine_section, floor_type), Object.CONNECT_ONE_SHOT)
		character.call_deferred("set_target_position", middle_pos)
	else:
		await get_tree().create_timer(2).timeout
		action_ended.emit()

func _end_movement(mine_section: MineSection, floor_type: MineSection.FloorType):
	var character: Character = get_parent()
	character.force_walk = true
	await character.play_stair_animation(mine_section.is_ladder_mine, true)
	character.force_static = true
	var randomSide = [MineSection.SideType.LEFT, MineSection.SideType.RIGHT].pick_random()
	if floor_type == MineSection.FloorType.TOP:
		mine_section.add_character(character, MineSection.FloorType.BOTTOM, randomSide, false)
		if not mine_section.is_ladder_mine:
			character.position.y = mine_section.bottom_position_path_follow.global_position.y
	else:
		mine_section.add_character(character, MineSection.FloorType.TOP, randomSide, false)
		if not mine_section.is_ladder_mine:
			character.position.y = mine_section.top_position_path_follow.global_position.y
	
	if mine_section.is_ladder_mine:
		await character.climb_ended
	await character.play_stair_animation(mine_section.is_ladder_mine, false)
	character.force_static = false
	character.force_walk = false
	await get_tree().create_timer(2).timeout
	action_ended.emit()
