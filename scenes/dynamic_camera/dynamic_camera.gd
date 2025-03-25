extends Camera2D
class_name DynamicCamera

@export var panning_size: int = 3
@export var panning_speed: float = 4
@export var default_smoothing: float = 3

@export var zoom_speed: float = 4

var target_pos: Vector2
var target_zoom: Vector2

var is_panning: bool = false
var panning_tween: Tween

var current_panning_min: int = 0
var current_panning_max: int = 0
var panning_right: bool = true


func _ready() -> void:
	GameManager.camera = self
	position_smoothing_speed = default_smoothing

func _process(delta: float) -> void:
	global_position = target_pos
	
	zoom = lerp(zoom, target_zoom, 4 * delta)

func move_camera(bounding_rect: Rect2):
	if bounding_rect.size != Vector2.ZERO:
		target_pos = bounding_rect.position + bounding_rect.size / 2

		var zoom_factor = get_box_zoom(bounding_rect)
		target_zoom = Vector2(zoom_factor, zoom_factor)


func get_box_zoom(bounding_rect: Rect2) -> float:
	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var bbox_ratio_x = screen_width / bounding_rect.size.x
	var bbox_ratio_y = screen_height / bounding_rect.size.y
	
	# Le zoom doit être suffisant pour que la bounding box tienne dans l'écran
	return min(bbox_ratio_x, bbox_ratio_y)


func center_camera():
	# TODO check min section
	center_camera_on_sections(0, GameManager.max_sections - 1)

func center_camera_on_sections(begin: int, end: int, panning: bool = false):
	is_panning = panning
	#if not is_panning:
		#position_smoothing_speed = default_smoothing
	
	var bounding_rect = get_sections_bounding_rect(begin, end)
	if not bounding_rect:
		return

	move_camera(bounding_rect)

func get_sections_bounding_rect(begin: int, end: int):
	# TODO check min / max
	var begin_section: MineSection = GameManager.get_section_by_index(begin)
	
	if not begin_section:
		return null
	
	var bounding_rect: Rect2 = Rect2()
	bounding_rect.position = begin_section.global_position
	bounding_rect.size = Vector2(begin_section.section_width * ((end - begin) + 1), begin_section.section_height)
	bounding_rect.size.y += 300
	bounding_rect.position.y -= 150
	return bounding_rect
	


# A VIRER UN JOUR CAR POTENTIELLEMENT INUTILE
func start_panning():
	is_panning = true	
	
	var min_bounding_rect = get_sections_bounding_rect(0, panning_size - 1)
	global_position = min_bounding_rect.position
	
	tween_panning(true)

func tween_panning(to_right: bool):
	var min_bounding_rect = get_sections_bounding_rect(0, panning_size - 1)
	var max_bounding_rect = get_sections_bounding_rect(GameManager.max_sections - 1 - panning_size, GameManager.max_sections - 1)
	
	var zoom_value = get_box_zoom(min_bounding_rect)
	zoom = Vector2(zoom_value, zoom_value)
	
	var min_pos: Vector2 = min_bounding_rect.position
	min_pos.x = min_pos.x + (min_bounding_rect.size.x / 2)
	min_pos.y = min_pos.y + (min_bounding_rect.size.y / 2)
	var max_pos: Vector2 = max_bounding_rect.position
	max_pos.x = max_pos.x + (max_bounding_rect.size.x / 2)
	max_pos.y = max_pos.y + (max_bounding_rect.size.y / 2)

	if panning_tween and panning_tween.is_running():
		panning_tween.stop()
	
	panning_tween = get_tree().create_tween()
	
	var to_position = min_pos
	if to_right:
		to_position = max_pos
		
	panning_tween.tween_property(self, "global_position", to_position * zoom_value, panning_speed).set_trans(Tween.TRANS_LINEAR)
	panning_tween.play()
	await panning_tween.finished
	tween_panning(!to_right)

func old_start_panning_camera():
	is_panning = true
	
	panning_right = true
	current_panning_min = 0
	current_panning_max = panning_size - 1
	_panning_camera()

func _panning_camera():
	center_camera_on_sections(current_panning_min, current_panning_max, true)
	
	var new_smoothing: float = (panning_speed * default_smoothing)
	position_smoothing_speed = new_smoothing
	
	await get_tree().create_timer(panning_speed).timeout
	
	_determine_next_panning()
	
	if is_panning:
		_panning_camera()

func _determine_next_panning():
	if panning_right:
		if current_panning_max < GameManager.max_sections - 1:
			current_panning_min += 1
			current_panning_max += 1
		else:
			panning_right = false
			_determine_next_panning()
	else:
		if current_panning_min > 0:
			current_panning_min -= 1
			current_panning_max -= 1
		else:
			panning_right = true
			_determine_next_panning()
