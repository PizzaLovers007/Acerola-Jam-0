class_name GameController
extends Node

@onready var player_state: PlayerState = get_tree().get_first_node_in_group("player")
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")

var has_started: bool = false
var curr_state: GameState = GameState.START

enum GameState {START, PLAYING, DEAD}


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not conductor.is_playing:
		conductor.play()
	pass
