extends Component
class_name CharacterAction

signal action_ended

@export var commands: Array[String] = []

var action_name: String

func _init() -> void:
	component_name = "CharacterAction"
	action_name = "No action name"

func _ready() -> void:
	VerySimpleTwitch.chat_message_received.connect(_on_twitch_message)

func _on_twitch_message(data: Chatter):
	if GameManager.current_phase != GameManager.GamePhase.PLANNING:
		return
	
	var character: Character = get_parent()
	
	if character.current_action != null:
		return
	
	if not is_player_character(data):
		return
	
	if command_valid(data):
		character.current_action = self
		GameManager.game.check_all_everyone_played()

func is_player_character(data: Chatter) -> bool:
	var character: Character = get_parent()
	return character.player.login == data.login
	

func command_valid(data: Chatter) ->  bool:
	var message = data.message.to_lower()
	
	for command in commands:
		if message.begins_with(command):
			return true
	
	return false

func apply_action():
	action_ended.emit()
