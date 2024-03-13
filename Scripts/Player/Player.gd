class_name Player
extends Node2D

const COYOTE_TIME_MS = 40

signal player_damaged
signal player_died

@onready var hit_player: AudioStreamPlayer = $HitPlayer
@onready var kill_player: AudioStreamPlayer = $KillPlayer
@onready var sprite: Sprite2D = get_node("Sprite")
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")

@export var health: int = 1
@export var column: int = 0
@export var is_controllable: bool = true
@export var invuln_time: float = 0
@export var column_offset: float = 0

var _obstacle_inside: Obstacle = null
var _entered_obstacle_us: int = 0
var _move_tween: Tween = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if invuln_time > 0:
		invuln_time = max(invuln_time - delta, 0)
		if invuln_time == 0:
			sprite.modulate.a = 1
	_process_damage()
	_process_inputs()


func _process_damage() -> void:
	if invuln_time > 0:
		return
	if _obstacle_inside != null and Time.get_ticks_usec() - _entered_obstacle_us > COYOTE_TIME_MS * 1000:
		health -= 1
		_obstacle_inside.show_angry()
		player_damaged.emit()
		if health > 0:
			hit_player.play()
			invuln_time = 4
			sprite.modulate.a = 0.5
		if health == 0:
			player_died.emit()
			kill_player.play()
			invuln_time = 1000
			is_controllable = false
			sprite.modulate.a = 0
			await get_tree().create_timer(5).timeout
			queue_free()


func _process_inputs() -> void:
	if not is_controllable:
		return
		
	if Input.is_action_just_pressed("ui_left"):
		move(-1)
	elif Input.is_action_just_pressed("ui_right"):
		move(1)


func move(dir: int) -> void:
	if _move_tween != null:
		return
	
	column += dir
	if column < -2 or column > 2:
		column = clamp(column, -2, 2)
		return
	
	var target_x = Constants.MIDDLE_X + column_offset + column * Constants.COLUMN_WIDTH
	_move_tween = get_tree().create_tween()
	_move_tween.set_ease(Tween.EASE_OUT)
	_move_tween.set_trans(Tween.TRANS_QUINT)
	_move_tween.tween_property(self, "position:x", target_x, conductor.get_beat_time() / 4)
	_move_tween.tween_callback(func(): _move_tween = null)
	_move_tween.play()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not area.is_in_group("obstacle"):
		return
	_entered_obstacle_us = Time.get_ticks_usec()
	_obstacle_inside = area as Obstacle


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not area.is_in_group("obstacle"):
		return
	if Time.get_ticks_usec() - _entered_obstacle_us <= COYOTE_TIME_MS * 1000:
		print("coyoted! ", (Time.get_ticks_usec() - _entered_obstacle_us) / 1000.0, "ms")
	_obstacle_inside = null
	_entered_obstacle_us = 0
