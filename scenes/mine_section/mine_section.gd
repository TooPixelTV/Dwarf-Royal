extends Node2D
class_name MineSection

enum FloorType {
	TOP,
	BOTTOM
}

enum SideType {
	LEFT,
	RIGHT
}

enum SectionState {
	NORMAL,
	WARNING,
	COLLAPSED
}

@export var section_index: int = 0

@export var section_width: float = 500
@export var section_height: float = 600

@export var is_ladder_mine: bool = false
@export var is_fake_mine: bool = false

@export var current_section_state: SectionState = SectionState.NORMAL

@onready var top_position_path_follow: PathFollow2D = $TopPositionPath/TopPositionPathFollow
@onready var bottom_position_path_follow: PathFollow2D = $BottomPositionPath/BottomPositionPathFollow

@onready var collapsed_top: GPUParticles2D = $CollapsedTop
@onready var collapsed_bottom: GPUParticles2D = $CollapsedBottom
@onready var warning_collapse_top: GPUParticles2D = $WarningCollapseTop
@onready var warning_collapse_bottom: GPUParticles2D = $WarningCollapseBottom

func _ready() -> void:
	if not is_fake_mine:
		GameManager.mine_sections.push_front(self)
		GameManager.round_changed.connect(_on_round_change)
		is_ladder_mine = [true, false].pick_random()
	
		if is_ladder_mine:
			%LadderProps.show()
		else:
			%ExitProps.show()
	else:
		%FakeMineShadow.show()
		

func add_character(character: Character, floor_type: FloorType, side: SideType = SideType.LEFT, teleport: bool = false):
	var old_mine_section = character.get_parent().get_parent()
	if floor_type == FloorType.TOP:
		character.reparent(%TopCharacters)
		if(side == SideType.LEFT):
			%TopCharacters.move_child(character, 0)
	else:
		character.reparent(%BottomCharacters)
		if(side == SideType.LEFT):
			%BottomCharacters.move_child(character, 0)
	
	if is_instance_of(old_mine_section, MineSection):
		old_mine_section.call_deferred("calculate_positions")
	
	call_deferred("calculate_positions")
	
	if teleport:
		call_deferred("_teleport_character", character)
	
	if current_section_state == SectionState.COLLAPSED:
		if teleport:
			character.healthC.kill()
		else:
			character.move_ended.connect(func (): character.healthC.kill())

func get_characters_list(floor_type: FloorType):
	var result: Array[Character]
	if floor_type == FloorType.TOP:
		result.assign(%TopCharacters.get_children())
	else:
		result.assign(%BottomCharacters.get_children())
	return result

func _teleport_character(character: Character):
	character.global_position = character.target_position
	

func calculate_positions():
	_calculate_floor_position(FloorType.TOP)
	_calculate_floor_position(FloorType.BOTTOM)
	
	
func _calculate_floor_position(floor_type: FloorType):
	var characters: Array[Character] = get_characters_list(floor_type)
	var path_follow: PathFollow2D = top_position_path_follow
	if floor_type == FloorType.BOTTOM:
		path_follow = bottom_position_path_follow
	
	var position_step: float = 1.0 / float(characters.size() + 1)
	
	for i in characters.size():
		var character: Character = characters[i]
		path_follow.progress_ratio = position_step * float(i + 1)
		character.set_target_position(path_follow.global_position)
		

func find_character(character: Character):
	if get_characters_list(FloorType.TOP).has(character):
		return FloorType.TOP
	
	if get_characters_list(FloorType.BOTTOM).has(character):
		return FloorType.BOTTOM
	
	return null

func reset_section_state():
	current_section_state = SectionState.NORMAL

func upgrade_section_state():
	if current_section_state == SectionState.NORMAL:
		current_section_state = SectionState.WARNING
		%WarningCountdown.show()
	else:
		%CollapseSound.play()
		current_section_state = SectionState.COLLAPSED
		%WarningCountdown.hide()
	
	_apply_state()
	
	await get_tree().create_timer(1).timeout
	if current_section_state == SectionState.COLLAPSED:
		for character in get_characters_list(FloorType.TOP):
			character.healthC.kill()
		for character in get_characters_list(FloorType.BOTTOM):
			character.healthC.kill()

func _apply_state():
	match current_section_state:
		SectionState.NORMAL:
			call_deferred("set_warning_collapse", false)
			call_deferred("set_collapse", false)
		SectionState.WARNING:
			call_deferred("set_warning_collapse", true)
			call_deferred("set_collapse", false)
		SectionState.COLLAPSED:
			call_deferred("set_warning_collapse", false)
			call_deferred("set_collapse", true)

func set_warning_collapse(value: bool):
	warning_collapse_top.emitting = value
	warning_collapse_bottom.emitting = value

func set_collapse(value: bool):
	collapsed_top.emitting = value
	collapsed_bottom.emitting = value


func _on_round_change(current_round: int):
	%WarningCountdown.text = str(GameManager.game.rounds_until_collapse - current_round % GameManager.game.rounds_until_collapse)
