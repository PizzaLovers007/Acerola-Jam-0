class_name Conductor
extends Node

# Signals for when beats pass (4th, 8th, etc.)
signal quarter_passed(beat: int)
signal eighth_passed(beat: int, fract: int)
signal twelth_passed(beat: int, fract: int)
signal sixteenth_passed(beat: int, fract: int)

# Same as above signals but AudioServer.get_output_latency() seconds earlier
# (for audio scheduling)
signal quarter_will_pass(beat: int)
signal eighth_will_pass(beat: int, fract: int)
signal twelth_will_pass(beat: int, fract: int)
signal sixteenth_will_pass(beat: int, fract: int)

@export var curr_beat: float = 0
@export var curr_beat_without_latency: float = 0
@export var bpm: float = 130
@export var is_playing: bool = false
@export var audio_offset_ms: int = 0
@export var visual_offset_ms: int = 0

@onready var player: AudioStreamPlayer = $Player

# Caching this since getting output latency is expensive. This value doesn't
# change, so we only need to lookup once
var _cached_latency = AudioServer.get_output_latency()
var _num_beats_in_song: int = 0
var _prev_time_seconds: float = 0
var _loops: int = 0
var _quarter_passed_incrementor: BeatIncrementor = BeatIncrementor.new(quarter_passed)
var _eighth_passed_incrementor: BeatIncrementor = BeatIncrementor.new(eighth_passed, 2)
var _twelth_passed_incrementor: BeatIncrementor = BeatIncrementor.new(twelth_passed, 3)
var _sixteenth_passed_incrementor: BeatIncrementor = BeatIncrementor.new(sixteenth_passed, 4)
var _quarter_will_pass_incrementor: BeatIncrementor = BeatIncrementor.new(quarter_will_pass)
var _eighth_will_pass_incrementor: BeatIncrementor = BeatIncrementor.new(eighth_will_pass, 2)
var _twelth_will_pass_incrementor: BeatIncrementor = BeatIncrementor.new(twelth_will_pass, 3)
var _sixteenth_will_pass_incrementor: BeatIncrementor = BeatIncrementor.new(sixteenth_will_pass, 4)


class BeatIncrementor:
	var _fract_mod: int
	var _signal: Signal
	var _last_beat: int = -1
	var _last_fract: int
	
	
	func _init(sig: Signal, fract_mod: int = 1):
		_fract_mod = fract_mod
		_signal = sig
		_last_fract = fract_mod - 1
	
	
	func increment_to(beat: int, fract: int = 0):
		while beat > _last_beat or fract > _last_fract:
			_last_fract += 1
			if _last_fract == _fract_mod:
				_last_beat += 1
				_last_fract = 0
			
			if _fract_mod == 1:
				_signal.emit(_last_beat)
			else:
				_signal.emit(_last_beat, _last_fract)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func play() -> void:
	_prev_time_seconds = -_cached_latency - 0.001
	curr_beat = _prev_time_seconds / 60 * bpm
	_loops = 0
	_num_beats_in_song = round(player.stream.get_length() / 60 * bpm)
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
	
	var time_seconds = (
			player.get_playback_position()
			+ AudioServer.get_time_since_last_mix()
			- _cached_latency
			- audio_offset_ms / 1000.0)
	
	# Validation
	if not _is_valid_update(time_seconds):
		return
	
	if time_seconds - _prev_time_seconds < -5:
		print("big reverse: prev=", _prev_time_seconds, " curr=", time_seconds, " delta=", _prev_time_seconds - time_seconds)
		# Loop happened!
		_loops += 1
		# Make prev time on the same "loop" as the curr time. It's not
		# recommended to use song length directly as there can be small
		# inaccuracies with audio looping and the song itself
		_prev_time_seconds -= _num_beats_in_song / bpm * 60
	
	var beat = time_seconds / 60 * bpm
	var prev_beat = _prev_time_seconds / 60 * bpm
	
	# Now add additional beats from previous loops
	beat += _loops * _num_beats_in_song
	prev_beat += _loops * _num_beats_in_song
	
	# Apply visual beat offset
	beat -= visual_offset_ms / 60000.0 * bpm
	prev_beat -= visual_offset_ms / 60000.0 * bpm
	
	# Signal the beats that are happening (with offset)
	curr_beat = beat
	if floor(beat) > floor(prev_beat):
		_quarter_passed_incrementor.increment_to(floor(beat))
	if floor(beat*2) > floor(prev_beat*2):
		_eighth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 2))
	if floor(beat*3) > floor(prev_beat*3):
		_twelth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 3))
	if floor(beat*4) > floor(prev_beat*4):
		_sixteenth_passed_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 4))
	
	# Unapply visual beat offset
	beat += visual_offset_ms / 60000.0 * bpm
	prev_beat += visual_offset_ms / 60000.0 * bpm
	
	# Now adjust the time to be in the future
	var latency_in_beats = _cached_latency / 60 * bpm
	beat += latency_in_beats
	prev_beat += latency_in_beats
	
	# Signal the beats that will happen soon
	curr_beat_without_latency = beat
	if floor(beat) > floor(prev_beat):
		_quarter_will_pass_incrementor.increment_to(floor(beat))
	if floor(beat*2) > floor(prev_beat*2):
		_eighth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 2))
	if floor(beat*3) > floor(prev_beat*3):
		_twelth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 3))
	if floor(beat*4) > floor(prev_beat*4):
		_sixteenth_will_pass_incrementor.increment_to(floor(beat), floor((beat - floor(beat)) * 4))
	
	# Keep track of the previous frame's time
	_prev_time_seconds = time_seconds


func _is_valid_update(time_seconds: float) -> bool:
	return (
		# No weird web issue
		time_seconds < 1000 and (
			# Time moved forward
			time_seconds > _prev_time_seconds or
			# Loop happened
			time_seconds - _prev_time_seconds < -5))
