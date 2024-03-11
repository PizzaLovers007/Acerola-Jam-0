class_name Conductor
extends Node

# Signals for when beats pass (4th, 8th, etc.)
signal quarter_passed(beat: int)
signal eighth_passed(beat: int, fract: int)
signal twelth_passed(beat: int, fract: int)
signal sixteenth_passed(beat: int, fract: int)

# Same as above signals but AudioServer.get_output_latency() seconds earlier
# (for beat playing)
signal quarter_passed_without_latency(beat: int)
signal eighth_passed_without_latency(beat: int, fract: int)
signal twelth_passed_without_latency(beat: int, fract: int)
signal sixteenth_passed_without_latency(beat: int, fract: int)

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


func stop() -> void:
	player.stop()
	is_playing = false

	
func get_beat_time() -> float:
	return 60 / bpm


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_playing:
		return
	
	var time_raw = (
			player.get_playback_position()
			+ AudioServer.get_time_since_last_mix())
	
	# Web occasionally has a big number here, so ignore these frames
	if time_raw > 1000:
		return
	
	# Skip processing jitters, but not loops
	if time_raw < prev_time_raw:
		if prev_time_raw - time_raw < 0.1:
			return
		print("big reverse: prev=", prev_time_raw, " curr=", time_raw, " delta=", prev_time_raw - time_raw)
		loops += 1
		prev_time_raw -= song_length_beats / bpm * 60
	
	var raw_beat = time_raw / 60 * bpm
	var prev_raw_beat = prev_time_raw / 60 * bpm
	var beat_latency = cached_latency / 60 * bpm
	
	curr_beat_without_latency = raw_beat + loops * song_length_beats - beat_latency
	curr_beat = raw_beat + loops * song_length_beats
	
	if floor(raw_beat) > floor(prev_raw_beat):
		quarter_passed_without_latency.emit(floor(curr_beat))
	if floor(raw_beat*2) > floor(prev_raw_beat*2):
		eighth_passed_without_latency.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 2))
	if floor(raw_beat*3) > floor(prev_raw_beat*3):
		twelth_passed_without_latency.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 3))
	if floor(raw_beat*4) > floor(prev_raw_beat*4):
		sixteenth_passed_without_latency.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 4))
	
	raw_beat -= beat_latency
	prev_raw_beat -= beat_latency
	
	if floor(raw_beat) > floor(prev_raw_beat):
		quarter_passed.emit(floor(curr_beat))
	if floor(raw_beat*2) > floor(prev_raw_beat*2):
		eighth_passed.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 2))
	if floor(raw_beat*3) > floor(prev_raw_beat*3):
		twelth_passed.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 3))
	if floor(raw_beat*4) > floor(prev_raw_beat*4):
		sixteenth_passed.emit(floor(curr_beat), floor((curr_beat - floor(curr_beat)) * 4))
	
	prev_time_raw = time_raw
