@tool
extends Node2D

@export var display_torches: bool = true:
	set(new_value):
		display_torches = new_value
		update_display()

@export var display_cave: bool = true:
	set(new_value):
		display_cave = new_value
		update_display()

@export var display_ground: bool = true:
	set(new_value):
		display_ground = new_value
		update_display()

func _ready() -> void:
	update_display()
	
func update_display():
	%Torch.visible = display_torches
	%Torch2.visible = display_torches
	
	%Cave.visible = display_cave
	
	%GroundLayer.visible = display_ground
	
