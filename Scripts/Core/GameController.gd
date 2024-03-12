class_name GameController
extends Node

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var game_over_node: Node = get_tree().get_first_node_in_group("gui")

var has_started: bool = false
var curr_state: GameState = GameState.START

enum GameState {START, PLAYING, DEAD}


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	Engine.time_scale = 1


func _on_player_died() -> void:
	conductor.stop()
	curr_state = GameState.DEAD
	game_over_node.visible = true
	Engine.time_scale = 0


func _process(delta: float) -> void:
	match curr_state:
		GameState.START:
			conductor.play()
			curr_state = GameState.PLAYING
		GameState.DEAD:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().reload_current_scene()
