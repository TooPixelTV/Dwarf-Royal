extends Node2D
class_name CharacterInfos

@export var character: Character

func _ready() -> void:
	if not GameManager.enable_lifes:
		%HealthLabel.hide()
	
	if character:
		character.infos_updated.connect(_update_stats)
		character.healthC.health_updated.connect(_update_health_label)
		character.tree_exited.connect(_on_character_free)
		_update_health_label(character.healthC.current_health)
		_update_stats()
		
func _process(delta: float) -> void:
	if is_instance_valid(character):
		global_position = character.global_position
	else:
		queue_free()

func _on_character_free():
	if character.is_queued_for_deletion():
		queue_free()

func _update_stats():
	if character:
		%Name.text = character.player.display_name
		if character.can_free_flip:
			%FreeFlipSprite.show()
		else:
			%FreeFlipSprite.hide()

func _update_health_label(value: int):
	var health_text: String = ""
	for i in value:
		health_text += "❤️"
	
	%HealthLabel.text = health_text
