extends Node

@onready var part_1: CanvasLayer = $Part1
@onready var part_2: CanvasLayer = $Part2
@onready var part_3: CanvasLayer = $Part3
@onready var part_4: CanvasLayer = $Part4

var tutorial_steps: Array[CanvasLayer]

var current_step: int = 0

func _ready() -> void:
	tutorial_steps = [
		part_1,
		part_2,
		part_3,
		part_4
	]
	
	current_step = 0
	update_steps()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event: InputEvent) -> void:
	if (event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
		current_step += 1
		update_steps()
	
	if current_step >= tutorial_steps.size():
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func update_steps() -> void:
	for i in range(tutorial_steps.size()):
		if i == current_step:
			tutorial_steps[i].show()
		else:
			tutorial_steps[i].hide()
