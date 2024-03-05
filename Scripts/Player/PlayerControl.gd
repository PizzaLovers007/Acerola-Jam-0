class_name PlayerControl
extends Node

const COYOTE_TIME_MS = 50

@onready var player_state: PlayerState = get_tree().get_first_node_in_group("player")
@onready var hit_player: AudioStreamPlayer = get_node("../HitPlayer")

var _is_inside_obstacle: bool = false
var _entered_obstacle_ms: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	player_state.invuln_time = max(player_state.invuln_time - delta, 0)
	_process_damage()
	if not player_state.is_controllable:
		return
	if Input.is_action_just_pressed("ui_left"):
		player_state.column -= 1
	elif Input.is_action_just_pressed("ui_right"):
		player_state.column += 1


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not area.is_in_group("obstacle"):
		return
	_is_inside_obstacle = true
	_entered_obstacle_ms = Time.get_ticks_msec()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not area.is_in_group("obstacle"):
		return
	if Time.get_ticks_msec() - _entered_obstacle_ms <= COYOTE_TIME_MS:
		print("coyoted! ", Time.get_ticks_msec() - _entered_obstacle_ms)
	_is_inside_obstacle = false
	_entered_obstacle_ms = 0


func _process_damage() -> void:
	if player_state.invuln_time > 0:
		return
	if _is_inside_obstacle and Time.get_ticks_msec() - _entered_obstacle_ms > COYOTE_TIME_MS:
		hit_player.play()
		player_state.health -= 1
		player_state.invuln_time = 4
