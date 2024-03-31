class_name Metronome
extends Node

@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var hi_tick_player: AudioStreamPlayer = get_node("HiTick")
@onready var lo_tick_player: AudioStreamPlayer = get_node("LoTick")
@onready var eighth_tick_player: AudioStreamPlayer = get_node("8thTick")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conductor.eighth_will_pass.connect(_on_eighth_passed)
	pass # Replace with function body.


func _on_eighth_passed(beat: int, fract: int) -> void:
	var measure = beat / 4;
	var beat_norm = beat % 4
	var half_beat_norm = beat_norm * 2 + fract
	if measure % 4 == 3:
		return
	
	if fract == 0:
		if beat_norm == 0:
			hi_tick_player.play()
		else:
			lo_tick_player.play()
	else:
		eighth_tick_player.play()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
