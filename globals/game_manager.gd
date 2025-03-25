extends Node

signal phase_changed(new_phase: GamePhase)
signal round_changed(current_round: int)

enum GamePhase {
	PLANNING,
	ACTION,
}

var current_phase: GamePhase = GamePhase.PLANNING

var max_sections: int = 0
var players: Array[Player] = []
var characters: Array[Character] = []
var mine_sections: Array[MineSection] = []
var rounds: int = 0
var winners: Array[Player] = []

var camera: DynamicCamera
var game: Game

# UI
var action_ui: ActionUI
var planning_phase_ui: PlanningPhaseUI
	
func start_game():
	rounds = 0
	change_phase(GamePhase.PLANNING)
	
func reset_game():
	current_phase = GamePhase.PLANNING
	max_sections = 0
	players.clear()
	characters.clear()
	mine_sections.clear()
	rounds = 0
	winners.clear()

func locate_character(character: Character) -> MineSection:
	for mine_section: MineSection in mine_sections:
		var findResult = mine_section.find_character(character)
		if findResult != null:
			return mine_section

	return null

func check_character_placement():
	for mine_section: MineSection in mine_sections:
		mine_section.calculate_positions()

func get_section_by_index(section_index: int) -> MineSection:
	for mine_section: MineSection in mine_sections:
		if mine_section.section_index == section_index:
			return mine_section
	
	return null
	
func change_phase(new_phase: GamePhase):
	if current_phase == GamePhase.ACTION and new_phase == GamePhase.PLANNING:
		rounds += 1
		round_changed.emit(rounds)
	
	current_phase = new_phase
	
	if current_phase == GamePhase.PLANNING:
		planning_phase_ui.show()
		planning_phase_ui.start_planning()
		game.check_all_everyone_played()
	else:
		planning_phase_ui.hide()
	
	if current_phase == GamePhase.ACTION:
		GameManager.camera.center_camera()
		await get_tree().create_timer(2).timeout
		game.current_action_phase = Game.ActionPhaseState.INIT
		game.start_action_phase()
	
	phase_changed.emit(current_phase)

func get_end_section(on_left: bool) -> MineSection:
	var last_normal_section: MineSection
	
	for section in mine_sections:
		if section.current_section_state == MineSection.SectionState.NORMAL:
			if on_left:
				return section
			last_normal_section = section
	
	return last_normal_section

func get_normal_section_count() -> int:
	var count: int = 0
	
	for section in mine_sections:
		if section.current_section_state == MineSection.SectionState.NORMAL:
			count += 1
	
	return count
