extends Area2D
class_name Axe

signal target_reached

@export var move_speed: float = 500.0

var from_player: Character
var target_position: Vector2

var starting_position: Vector2
var going_left: bool = false
var damage_dealed: bool = false
var anim_speed_scale: float

func _ready() -> void:
	anim_speed_scale = %AxeSprite.speed_scale

func initAxe() -> void:
	starting_position = global_position
	var direction = starting_position.direction_to(target_position)
	if direction.x > 0:
		going_left = false
		%AxeSprite.speed_scale = anim_speed_scale
	else:
		going_left = true
		%AxeSprite.speed_scale = anim_speed_scale * -1
	%MoveAudio.play()

func _process(delta: float) -> void:
	if damage_dealed:
		return
	
	if not going_left and starting_position.distance_to(global_position) < starting_position.distance_to(target_position):
		global_position.x += move_speed * delta
	elif going_left and  starting_position.distance_to(global_position) < starting_position.distance_to(target_position):
		global_position.x -= move_speed * delta
	else:
		target_reached.emit()
		%MoveAudio.stop()
		%Explosion.set_deferred("emitting", true)
		%Explosion.finished.connect(func(): queue_free())

func _on_body_entered(body: Node2D) -> void:
	if damage_dealed:
		return
		
	if body is Character:
		if body.player.login == from_player.player.login:
			return
		%MoveAudio.stop()
		%Explosion.set_deferred("emitting", true)
		damage_dealed = true
		%AxeSprite.hide()
		%Collision.set_deferred("disabled", true)
		body.kick_end.connect(func (): _apply_damage(body, going_left), Object.CONNECT_ONE_SHOT)
		body.kick_anim(going_left)

func _apply_damage(character: Character, _going_left: bool):
	var healthC: HealthC = Component.get_child_component(character, HealthC)
	if healthC:
		healthC.take_damage()
	if healthC and healthC.current_health <= 0:
		await character.tree_exited
	else:
		var current_section: MineSection = GameManager.locate_character(character)
		var character_floor: MineSection.FloorType = current_section.find_character(character)
		if current_section:
			var going_section_index: int = 0
			var from_side: MineSection.SideType = MineSection.SideType.LEFT
			if _going_left:
				from_side = MineSection.SideType.RIGHT
				going_section_index = current_section.section_index - 1
			else:
				from_side = MineSection.SideType.LEFT
				going_section_index = current_section.section_index + 1
			
			if going_section_index < 0 || going_section_index > GameManager.max_sections - 1:
				character.healthC.kill()
			else:
				var destination_section: MineSection = GameManager.get_section_by_index(going_section_index)
				if destination_section:
					destination_section.add_character(character, character_floor, from_side)
					
	await get_tree().create_timer(1).timeout
	target_reached.emit()
	queue_free()
	
