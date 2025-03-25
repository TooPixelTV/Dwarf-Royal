extends Resource
class_name Player

@export var login: String
@export var display_name: String
@export var bot: bool = false
@export var color: Color = Color.from_hsv(randf(), randf(), randf())

var ores: int = 0

func reset_player():
	ores = 0
