class_name Conductor
extends Node

## Emitted when a beat happens.
signal beat_passed(beat: int)
## Emitted when a beat is just about to happen, approximately
## [method]AudioServer.get_output_latency()[/method] seconds before the beat.
## Useful if some audio needs to play exactly on the beat.
signal beat_passed_without_latency(beat: int)

@export var curr_beat: float = 0
@export var curr_beat_without_latency: float = 0
@export var bpm: float = 130
@export var is_playing: bool = false

var cached_latency = AudioServer.get_output_latency()
var song_length_beats: int = 0
var player: AudioStreamPlayer
var prev_time_raw: float = 0
var loops: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = $Player


func play() -> void:
	prev_time_raw = -1
	curr_beat = 0
	loops = 0
	song_length_beats = round(player.stream.get_length() / 60 * bpm)
	player.play()
	is_playing = true
	
	
func get_beat_time() -> float:
	return 60 / bpm


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_playing:
		return
	
	var time_raw = (
			player.get_playback_position()
			+ AudioServer.get_time_since_last_mix())
	
	# Skip processing jitters, but not loops
	if time_raw < prev_time_raw:
		if prev_time_raw - time_raw < 0.1:
			return
		print("big reverse: ", prev_time_raw - time_raw)
		loops += 1
		prev_time_raw -= song_length_beats / bpm * 60
	
	var raw_beat = time_raw / 60 * bpm
	var prev_raw_beat = prev_time_raw / 60 * bpm
	var beat_latency = cached_latency / 60 * bpm
	
	curr_beat_without_latency = raw_beat + loops * song_length_beats - beat_latency
	curr_beat = raw_beat + loops * song_length_beats
	
	if floor(raw_beat) > floor(prev_raw_beat):
		beat_passed_without_latency.emit(floor(curr_beat))
	if floor(raw_beat - beat_latency) > floor(prev_raw_beat - beat_latency):
		beat_passed.emit(floor(curr_beat))
	
	prev_time_raw = time_raw
