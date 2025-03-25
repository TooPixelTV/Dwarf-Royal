extends Node2D
class_name Game

const MINE_SECTION = preload("res://scenes/mine_section/mine_section.tscn")
const CHARACTER = preload("res://scenes/character/character.tscn")

enum ActionPhaseState {
	INIT,
	PROCESSING_ACTION,
	NEXT_ACTION,
	END_CURRENT_ACTION,
	END_ACTION_PHASE,
}

@export var rounds_until_collapse: int = 3

var action_characters: Array[Character]
var current_collapsing_section: MineSection
var current_action_phase: ActionPhaseState = ActionPhaseState.INIT


func _ready() -> void:
	BackgroundMusic.set_music_level(1)
	GameManager.round_changed.connect(_on_round_change)
	GameManager.game = self
	generate_mine()
	GameManager.camera.center_camera()
	spawn_players()
	
	await get_tree().create_timer(3).timeout
	GameManager.start_game()
	call_deferred("select_collapsing_section")

func spawn_players():
	var players = GameManager.players.duplicate(true)
	players.shuffle()
	
	for mine_section: MineSection in %MineSections.get_children():
		if players.size() > 0:
			var character: Character = CHARACTER.instantiate()
			character.player = players.pop_front()
			GameManager.characters.push_front(character)
			add_child(character)
			character.call_deferred("set_facing", [true, false].pick_random())
			character.died_complete.connect(_on_player_die)
			
			var selected_floor: MineSection.FloorType = MineSection.FloorType.TOP
			if randi_range(0, 1) == 0:
				selected_floor = MineSection.FloorType.BOTTOM
			
			mine_section.add_character(character, selected_floor, MineSection.SideType.LEFT, true)


func generate_mine():
	GameManager.max_sections = GameManager.players.size() + 1
	
	for i in GameManager.max_sections:
		var section: MineSection = MINE_SECTION.instantiate()
		section.position.x = i * section.section_width
		section.section_index = i
		%MineSections.add_child(section)
	
	for index in [-2,-1, GameManager.max_sections, GameManager.max_sections + 1]:
		var fake_left_mine: MineSection = MINE_SECTION.instantiate()
		fake_left_mine.position.x = index * fake_left_mine.section_width
		fake_left_mine.section_index = index
		fake_left_mine.is_fake_mine = true
		%MineSections.add_child(fake_left_mine)
 

func get_mine_section(section_index: int):
	for mine_section: MineSection in %MineSections.get_children():
		if mine_section.section_index == section_index:
			return mine_section
	
	return null


func start_action_phase():
	action_characters = GameManager.characters.duplicate(true)
	action_characters.shuffle()
	
	for character in action_characters:
		if character.player.bot:
			character.define_bot_action()
	
	current_action_phase = ActionPhaseState.NEXT_ACTION


func _play_next_action():
	if action_characters.size() <= 0:
		current_action_phase = ActionPhaseState.END_ACTION_PHASE
		return
	
	if !is_instance_valid(action_characters[0]):
		action_characters.remove_at(0)
		if action_characters.size() <= 0:
			current_action_phase = ActionPhaseState.END_ACTION_PHASE
			return
		
	var character: Character = action_characters.pop_front()
	if character.healthC.current_health <= 0:
		current_action_phase = ActionPhaseState.NEXT_ACTION
		return
	
	determine_action_camera(character)
	await get_tree().create_timer(2).timeout
	if character.current_action:
		character.current_action.action_ended.connect(end_current_action, Object.CONNECT_ONE_SHOT)
	character.call_deferred("play_current_action")
	
	if not character.current_action:
		current_action_phase = ActionPhaseState.END_CURRENT_ACTION

func end_current_action():
	GameManager.action_ui.hide_action()
	GameManager.camera.center_camera()
	await get_tree().create_timer(2).timeout
	current_action_phase = ActionPhaseState.NEXT_ACTION

func determine_action_camera(character: Character):
	if character.current_action:
		match character.current_action.component_name:
			"FlipActionC", "UpDownActionC":
				var mine_section: MineSection = GameManager.locate_character(character)
				if mine_section:
					GameManager.camera.center_camera_on_sections(mine_section.section_index, mine_section.section_index)
			"AttackActionC":
				var mine_section: MineSection = GameManager.locate_character(character)
				var attack_range: int =(character.current_action as AttackActionC).attack_range + 1
				var facing_left = character._facing_left
				
				var other_index: int = mine_section.section_index - attack_range
				if not facing_left:
					other_index = mine_section.section_index + attack_range
				# TODO get min section
				other_index = clamp(other_index, 0, GameManager.max_sections - 1)
				
				var min_section: int
				var max_section: int
				if facing_left:
					min_section = other_index
					max_section = mine_section.section_index
				else:
					max_section = other_index
					min_section = mine_section.section_index
				
				GameManager.camera.center_camera_on_sections(min_section, max_section)
			"MoveActionC":
				var mine_section: MineSection = GameManager.locate_character(character)
				var facing_left = character._facing_left
				
				var section_min: int = 0
				var section_max: int = 0
				if facing_left:
					section_min = mine_section.section_index - 1
					section_max = mine_section.section_index
				else:
					section_min = mine_section.section_index
					section_max = mine_section.section_index + 1
				
				GameManager.camera.center_camera_on_sections(section_min, section_max)
				
		

func _end_action_phase():
	GameManager.action_ui.hide_action()
	GameManager.change_phase(GameManager.GamePhase.PLANNING)


func _on_round_change(current_round: int):
	adapt_background_music(current_round)
	if current_round != 0 and current_round % rounds_until_collapse == 0:
		if current_round == (GameManager.max_sections * rounds_until_collapse) - 1:
			victory_scene()
		else:
			if current_collapsing_section:
				current_collapsing_section.upgrade_section_state()
			select_collapsing_section()

func adapt_background_music(current_round: int):
	if current_round < 6:
		BackgroundMusic.set_music_level(1)
	elif current_round < 10:
		BackgroundMusic.set_music_level(2)
	elif current_round < 16:
		BackgroundMusic.set_music_level(3)

func select_collapsing_section():
	var on_left: bool = [true, false].pick_random()
	
	current_collapsing_section = GameManager.get_end_section(on_left)
	current_collapsing_section.upgrade_section_state()


func check_all_everyone_played():
	for character in GameManager.characters:
		if not character.player.bot:
			if character.current_action == null:
				return
	
	GameManager.planning_phase_ui.cancel_planning()

func _on_player_die():
	if GameManager.characters.size() == 1:
		victory_scene()

func victory_scene():
	BackgroundMusic.set_music_level(0)
	GameManager.winners.clear()
	
	for character in GameManager.characters:
		GameManager.winners.append(character.player)
	
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://scenes/victory_ui/victory_ui.tscn")
	


func _on_action_phase_timer_timeout() -> void:
	if GameManager.current_phase == GameManager.GamePhase.ACTION:
		match current_action_phase:
			ActionPhaseState.INIT or ActionPhaseState.PROCESSING_ACTION:
				return
			ActionPhaseState.NEXT_ACTION:
				current_action_phase = ActionPhaseState.PROCESSING_ACTION
				_play_next_action()
				return
			ActionPhaseState.END_ACTION_PHASE:
				current_action_phase = ActionPhaseState.PROCESSING_ACTION
				_end_action_phase()
				return
			ActionPhaseState.END_CURRENT_ACTION:
				current_action_phase = ActionPhaseState.PROCESSING_ACTION
				end_current_action()
				return
