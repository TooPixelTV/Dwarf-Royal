extends RigidBody2D
class_name Character

const CHARACTER_INFOS = preload("res://scenes/character_infos/character_infos.tscn")
const WALK_SOUNDS = [
	preload("res://assets/sfx/walk_1.wav"),
	preload("res://assets/sfx/walk_2.wav"),
	preload("res://assets/sfx/walk_3.wav"),
	preload("res://assets/sfx/walk_4.wav")
]
const DAMAGE = preload("res://assets/sfx/damage.wav")
const DIE = preload("res://assets/sfx/die.wav")

signal move_ended
signal kick_end
signal infos_updated
signal climb_ended
signal died_complete

@export var player: Player
@export var healthC: HealthC
@export var axe_start_point: Marker2D
@export var walk_speed: float = 200.0
@export var kick_force: float = 700.0
@export var player_color: Color = Color.WEB_GRAY
@export var _facing_left: bool = false
@export var display_infos: bool = true

var current_action: CharacterAction
var target_position: Vector2
var target_reached: bool = true
var is_down: bool = false
var can_free_flip: bool = false
var free_flip_used: bool = false
var delayed_free_flip: bool = false
var force_walk: bool = false
var force_static: bool = false
var climbing: bool = false

var init_complete: bool = false


var start_point_x: float
var collision_x: float
var last_standing_y: float

var infos: CharacterInfos

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stair_change_animation_player: AnimationPlayer = $StairChangeAnimationPlayer
@onready var main_animation_player: AnimationPlayer = $MainAnimationPlayer

func _ready() -> void:
	set_facing(_facing_left)
	start_point_x = %AxeStartPoint.position.x
	collision_x = %Collision.position.x
	
	current_action = null
	%ColorSprite.self_modulate = player.color
	
	healthC.died.connect(_on_player_die)
	
	if(display_infos):
		var char_infos: CharacterInfos = CHARACTER_INFOS.instantiate()
		char_infos.character = self
		get_tree().root.add_child(char_infos)
		infos = char_infos
	
	%WalkAudio.finished.connect(play_walk_sound)
	
func _process(delta: float) -> void:
	if climbing:
		play_walk_sound()
		if abs(global_position.y - target_position.y) > 2:
			if target_position.y - position.y > 0:
				position.y += walk_speed * delta
			else:
				position.y -= walk_speed * delta
		else:
			global_position.y = target_position.y
			climbing = false
			%Light.show()
			%WalkAudio.stop()
			climb_ended.emit()
	
	if not target_reached and not force_static:
		play_walk_sound()
		if global_position.distance_to(target_position) > 2:
			if target_position.x - position.x > 0:
				position.x += walk_speed * delta
			else:
				position.x -= walk_speed * delta
		else:
			position.x = target_position.x
			target_reached = true
			%WalkAudio.stop()
			move_ended.emit()

func play_stair_animation(is_ladder: bool, is_in: bool):
	if is_ladder:
		if is_in:
			%Light.hide()
			climbing = true
	else:
		if is_in:
			stair_change_animation_player.play("cave_in")
		else:
			stair_change_animation_player.play("cave_out")
		await stair_change_animation_player.animation_finished

func play_walk_sound():
	if not %WalkAudio.playing:
		%WalkAudio.stream = WALK_SOUNDS.pick_random()
		%WalkAudio.play()

func stop_walk_sound():
	%WalkAudio.stop()


func set_target_position(value: Vector2):
	target_position = value
	target_reached = false
	

func set_facing(facing_left: bool): 
	_facing_left = facing_left
	%Sprite.flip_h = _facing_left
	%ColorSprite.flip_h = _facing_left
	if _facing_left:
		%Light.scale.x = -5
		%Light.position.x = -15.0
		%AxeStartPoint.position.x = start_point_x * -1
		%Collision.position.x = collision_x * -1
	else:
		%Light.scale.x = 5
		%Light.position.x = 15.0
		%AxeStartPoint.position.x = start_point_x
		%Collision.position.x = collision_x


func play_current_action():
	if current_action != null:
		if not is_down:
			_handle_free_flip()
			GameManager.action_ui.display_action(player.display_name, current_action.action_name)
			current_action.apply_action()
		else:
			await stand()
			if not delayed_free_flip:
				_handle_free_flip()
			else:
				delayed_free_flip = false
				
			await get_tree().create_timer(1).timeout
			current_action.action_ended.emit()
	else:
		if is_down:
			await stand()
	current_action = null


func _handle_free_flip():
	if can_free_flip == true and free_flip_used == true:
		GameManager.action_ui.display_action(player.display_name, "Free Flip")
		var flip_action: FlipActionC = Component.get_child_component(self, FlipActionC)
		if flip_action:
			flip_action.apply_action()
	
	free_flip_used = false
	can_free_flip = false
	infos_updated.emit()


func define_bot_action():
	var actions: Array[CharacterAction]
	actions.assign(Component.get_multiple_child_components(self, CharacterAction))
	actions.shuffle()
	
	#actions = actions.filter(func (e): return e is AttackActionC) 
	
	current_action = actions.pop_front()


func _on_player_die():
	%SFXPlayer.stream = DIE
	%SFXPlayer.play()
	force_static = true
	
	if display_infos:
		infos.hide()
	
	await get_tree().create_timer(1).timeout
	%MainAnimationPlayer.play("die")
	await get_tree().create_timer(1.5).timeout
	

func die_end():
	GameManager.characters.erase(self)
	died_complete.emit()
	GameManager.call_deferred("check_character_placement")
	queue_free()

func stand():
	GameManager.action_ui.display_action(player.display_name, "Standing")
	is_down = false
	set_damagable(true)
	await get_tree().create_timer(2).timeout

func kick_anim(to_left: bool):
	%SFXPlayer.stream = DAMAGE
	%SFXPlayer.play()
	call_deferred("_apply_kick", to_left)

func set_damagable(value: bool):
	%Collision.set_deferred("disabled", !value)

func _apply_kick(to_left: bool):
	freeze = false
	last_standing_y = position.y
	var direction = Vector2.RIGHT
	if to_left:
		direction = Vector2.LEFT
	
	direction.y = 0.5
	
	apply_central_impulse(direction * kick_force)
	await get_tree().create_timer(3).timeout
	rotation = 0
	position.y = last_standing_y
	is_down = true
	set_damagable(false)
	can_free_flip = true
	free_flip_used = false
	delayed_free_flip = current_action != null
	freeze = true
	kick_end.emit()
	infos_updated.emit()
	
