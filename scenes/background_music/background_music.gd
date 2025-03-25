extends Node

var fade_weight: int = 4
var current_level: int = 0

func _process(delta: float) -> void:
	pass
	for index in %MusicPlayer.stream.stream_count:
		if index > 0:
			if index == current_level:
				var value = lerp(int(%MusicPlayer.stream.get_sync_stream_volume(index)), 0, fade_weight * delta)
				%MusicPlayer.stream.set_sync_stream_volume(index, value)
			else:
				var value = lerp(int(%MusicPlayer.stream.get_sync_stream_volume(index)), -60, fade_weight * delta)
				%MusicPlayer.stream.set_sync_stream_volume(index, value)

func set_music_level(level: int):
	current_level = level
