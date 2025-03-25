extends CanvasLayer
class_name ActionUI

func _ready() -> void:
	GameManager.action_ui = self

func display_action(username: String, action_name: String):
	%LoginAction.text = username
	%ActionName.text = action_name
	show()

func hide_action():
	hide()
