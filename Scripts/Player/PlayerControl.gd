class_name PlayerControl
extends Node

const COYOTE_TIME_MS = 80

@onready var player_state: PlayerState = get_tree().get_first_node_in_group("player")
@onready var hit_player: AudioStreamPlayer = get_node("../HitPlayer")

var _inside_count: int = 0
var _entered_obstacle_us: int = 0

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
	if _inside_count == 0:
		_entered_obstacle_us = Time.get_ticks_usec()
	_inside_count += 1


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not area.is_in_group("obstacle"):
		return
	if Time.get_ticks_usec() - _entered_obstacle_us <= COYOTE_TIME_MS * 1000:
		print("coyoted! ", (Time.get_ticks_usec() - _entered_obstacle_us) / 1000.0, "ms")
	_inside_count -= 1
	if _inside_count == 0:
		_entered_obstacle_us = 0


func _process_damage() -> void:
	if player_state.invuln_time > 0:
		return
	if _inside_count > 0 and Time.get_ticks_usec() - _entered_obstacle_us > COYOTE_TIME_MS * 1000:
		hit_player.play()
		player_state.health -= 1
		player_state.invuln_time = 4
