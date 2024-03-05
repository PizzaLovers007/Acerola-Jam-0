extends Node

@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var hi_tick_player: AudioStreamPlayer = get_node("HiTick")
@onready var lo_tick_player: AudioStreamPlayer = get_node("LoTick")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conductor.beat_passed_without_latency.connect(_on_beat_passed)
	pass # Replace with function body.


func _on_beat_passed(beat: int) -> void:
	if beat % 4 == 0:
		hi_tick_player.play()
	else:
		lo_tick_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
