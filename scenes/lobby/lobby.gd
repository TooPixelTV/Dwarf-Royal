extends CanvasLayer

const CHARACTER = preload("res://scenes/character/character.tscn")
const MAIN_THEME = preload("res://assets/main_theme.tres")

@export var min_players: int = 6
var players: Array[Player] = []
func _ready() -> void:
	VerySimpleTwitch.chat_message_received.connect(_on_twitch_message)


func _on_twitch_message(data: Chatter):
	var message = data.message.to_lower()
	var login = data.login
	
	if players.filter(func (e: Player): return e.login == login).size() == 0 and message.begins_with("!join"):
		if players.size() < 6:
			var player: Player = Player.new()
			player.login = login
			player.display_name = data.tags.display_name
			players.append(player)
			update_players_list()
		return
	
	if players.filter(func (e: Player): return e.login == login).size() > 0 and message.begins_with("!quit"):
		players = players.filter(func (e: Player): return e.login != login)
		update_players_list()
		return
	
	if players.filter(func (e: Player): return e.login == login).size() > 0 and message.begins_with("!color"):
		var found_players = players.filter(func (e: Player): return e.login == login)
		
		if found_players.size() == 1:
			var found_player = found_players[0]
			var color_text = message.replace("!color ", "");
			found_player.color = Color.from_string(color_text, Color.WHITE)
		update_players_list()
		return

func update_players_list():
	for element in %PlayersList.get_children():
		element.queue_free()
		
	for player in players:
		var login_label: Label = Label.new()
		login_label.custom_minimum_size.y = 120
		login_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		login_label.text = player.display_name
		login_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		login_label.theme = MAIN_THEME
		login_label["theme_override_colors/font_outline_color"] = Color.from_string("282e3b", "white")
		login_label["theme_override_constants/outline_size"] = 25
		%PlayersList.add_child(login_label)
		
		var player_character: Character = CHARACTER.instantiate()
		player_character.display_infos = false
		player_character.player = player
		login_label.add_child(player_character)
		player_character.global_position = login_label.global_position
		player_character.global_position.x += 65
		player_character.global_position.y += 45


func _on_start_btn_pressed() -> void:
	var missing_players: int = min_players - players.size()
	for i in missing_players:
		var playerBot: Player = Player.new()
		playerBot.bot = true
		playerBot.login ="bot_" + str(i + 1)
		playerBot.display_name = "Bot " + str(i + 1)
		players.append(playerBot)
	
	GameManager.players = players
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")


func _on_back_button_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
