class_name GameController
extends Node

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var game_over_text: RichTextLabel = get_tree().get_first_node_in_group("gui").get_node("GameOver")
@onready var lives_node: Node2D = get_tree().get_first_node_in_group("lives")

var has_started: bool = false
var curr_state: GameState = GameState.START

enum GameState {START, PLAYING, DEAD}


func _ready() -> void:
	player.player_died.connect(_on_player_died)
	player.player_damaged.connect(_on_player_damaged)


func _on_player_died() -> void:
	conductor.stop()
	curr_state = GameState.DEAD
	game_over_text.visible = true


func _on_player_damaged() -> void:
	lives_node.get_child(lives_node.get_child_count()-1).queue_free()


func _process(delta: float) -> void:
	match curr_state:
		GameState.START:
			conductor.play()
			curr_state = GameState.PLAYING
		GameState.DEAD:
			if Input.is_action_just_pressed("ui_accept"):
				get_tree().reload_current_scene()
