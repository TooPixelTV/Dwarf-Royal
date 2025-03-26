extends Component
class_name HealthC

signal died
signal health_updated(value: int)

@export var max_health: int = 3

@onready var current_health: int = max_health

func _init() -> void:
	component_name = "HealthC"

func _ready() -> void:
	health_updated.emit(current_health)
	

func reset():
	current_health = max_health
	health_updated.emit(current_health)
	
func take_damage():
	if GameManager.enable_lifes:
		current_health -= 1
		if current_health <= 0:
			current_health = 0
			died.emit()
		health_updated.emit(current_health)

func kill():
	current_health = 0;
	died.emit()
