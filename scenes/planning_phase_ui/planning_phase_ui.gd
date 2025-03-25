extends CanvasLayer
class_name PlanningPhaseUI

const TIMER_START = preload("res://assets/sfx/timer_start.wav")
const TIMER_END = preload("res://assets/sfx/timer_end.wav")

@export var planning_time: int = 30

var remaining_time: int = 0

func _ready() -> void:
	GameManager.planning_phase_ui = self

func start_planning():
	%TimerSFX.stream = TIMER_START
	%TimerSFX.play()
	remaining_time = planning_time
	%RemainingTimeProgress.max_value = planning_time
	%RemainingTimeProgress.value = remaining_time
	%Timer.start()
	update_remaining_time()
	

func _on_timer_timeout() -> void:
	remaining_time -= 1
	
	if remaining_time <= 10 and not %TimerLoopSFX.playing:
		%TimerLoopSFX.play()
	
	if remaining_time <= 0:
		remaining_time = 0
		%Timer.stop()
		planning_end()
	
	update_remaining_time()

func update_remaining_time():
	%RemainingTime.text = str(remaining_time)
	%RemainingTimeProgress.value = remaining_time

func planning_end():
	%TimerSFX.stream = TIMER_END
	%TimerSFX.play()
	%TimerLoopSFX.stop()
	GameManager.change_phase(GameManager.GamePhase.ACTION)
	
func cancel_planning():
	await get_tree().create_timer(2).timeout
	%Timer.stop()
	planning_end()
	
