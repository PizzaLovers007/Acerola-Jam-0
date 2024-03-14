class_name GameController
extends Node

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var obstacle_spawner: ObstacleSpawner = get_tree().get_first_node_in_group("spawner")
@onready var game_over_node: Node = get_tree().get_first_node_in_group("gui")
@onready var score_text: RichTextLabel = get_tree().get_first_node_in_group("score")
@onready var save_system: SaveSystem = get_tree().get_first_node_in_group("save_system")

var has_started: bool = false
var curr_state: GameState = GameState.START
var _score: int = 0

enum GameState {START, PLAYING, DEAD}


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	obstacle_spawner.did_tick.connect(_on_tick)


func _on_player_died() -> void:
	conductor.stop()
	curr_state = GameState.DEAD
	score_text.visible = false
	game_over_node.visible = true
	var game_over_score_text = game_over_node.get_node("Score") as RichTextLabel
	if _score > save_system.high_score:
		game_over_score_text.text = "[center]Final score: %d\n[color=yellow]New high score![/color][/center]" % _score
	else:
		game_over_score_text.text = "[center]Final score: %d\nHigh score: %d[/center]" % [_score, save_system.high_score]
	save_system.high_score = max(_score, save_system.high_score)


func _on_tick() -> void:
	_score += 1
	score_text.text = "Score:\n%d" % _score


func _process(delta: float) -> void:
	match curr_state:
		GameState.START:
			conductor.play()
			curr_state = GameState.PLAYING
		GameState.DEAD:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().reload_current_scene()
			elif Input.is_action_just_pressed("ui_cancel"):
				get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
