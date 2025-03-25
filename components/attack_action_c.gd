extends CharacterAction
class_name AttackActionC

const AXE = preload("res://scenes/axe/axe.tscn")

@export var attack_range: int = 2

func _init() -> void:
	component_name = "AttackActionC"
	action_name = "Attack"
	commands = ['!shoot', '!attack', '!atk', '!fire']

func apply_action():
	var character: Character = get_parent()
	var mine_section: MineSection = GameManager.locate_character(character)
	if mine_section:
		var axe_instance: Axe = AXE.instantiate()
		axe_instance.from_player = character
		
		# TODO check min mine section
		var start_position = character.axe_start_point.global_position
		var target_index: int = 0
		if character._facing_left:
			target_index = mine_section.section_index - attack_range
		else:
			target_index = mine_section.section_index + attack_range
		
		target_index = clamp(target_index, 0, GameManager.max_sections - 1)
		var target_mine_section: MineSection = GameManager.get_section_by_index(target_index)
		var target_position = start_position
		target_position.x = target_mine_section.global_position.x
		
		if not character._facing_left:
			target_position.x += mine_section.section_width
		
		axe_instance.target_position = target_position
		get_tree().root.add_child(axe_instance)
		axe_instance.global_position = start_position
		axe_instance.initAxe()
		axe_instance.target_reached.connect(func (): action_ended.emit())
		
