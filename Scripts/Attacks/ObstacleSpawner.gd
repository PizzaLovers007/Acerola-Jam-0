class_name ObstacleSpawner
extends Node

const Y_SPAWN: float = -Constants.OBSTACLE_HEIGHT

@export var spawning: bool = false
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var obstacles_node: Node2D = $Obstacles
@onready var tell_tick: AudioStreamPlayer = $TellTick
@onready var move_tick: AudioStreamPlayer = $MoveTick

var _obstacle_scene: PackedScene = preload("res://Scenes/Objects/Obstacle.tscn")
var _next_spawn: int = 2
var _next_pattern: Array = Constants.PATTERNS.pick_random()
var _move_pattern: Array[bool] = [true, false, true, false, true, false, true, false]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conductor.eighth_passed.connect(_spawn_and_move)
	conductor.eighth_passed_without_latency.connect(_schedule_sounds)
	_move_pattern.resize(8)
	pass # Replace with function body.


func _spawn_obstacle(column: int, y_offset: int) -> void:
	var obstacle: Obstacle = _obstacle_scene.instantiate()
	obstacle.transform.origin.y = Y_SPAWN - y_offset * Constants.OBSTACLE_HEIGHT
	obstacle.transform.origin.x = Constants.MIDDLE_X + column * Constants.COLUMN_WIDTH
	obstacles_node.add_child(obstacle)


func _spawn_and_move(beat: int, fract: int) -> void:
	var measure = beat / 4
	var beat_norm = beat % 4
	match measure % 4:
		3:
			var half_beat_norm = beat_norm * 2 + fract
			if _move_pattern[half_beat_norm]:
				_tick()
		_:
			if fract == 0:
				_tick()

func _schedule_sounds(beat: int, fract: int) -> void:
	var measure = beat / 4
	var beat_norm = beat % 4
	if measure % 4 == 1 and beat_norm == 0 and fract == 0:
		var pattern = Constants.MOVE_PATTERNS.pick_random()
		for i in range(0, 8):
			_move_pattern[i] = (pattern & (1 << (7-i))) != 0
			
	var half_beat_norm = beat_norm * 2 + fract
	match measure % 4:
		2:
			if _move_pattern[half_beat_norm]:
				tell_tick.play()
		3:
			if _move_pattern[half_beat_norm]:
				move_tick.play()


func _tick() -> void:
	_handle_spawning()
	for obstacle in obstacles_node.get_children() as Array[Obstacle]:
		obstacle.move()

	
func _handle_spawning() -> void:
	if _next_spawn > 0:
		_next_spawn -= 1
		return
	var pattern = _next_pattern
	for i in range(0, pattern.size()):
		var row = pattern[pattern.size()-i-1]
		for c in range(-2, 3):
			if (row >> (2-c)) % 2 == 1:
				_spawn_obstacle(c, i)
				
	_next_pattern = Constants.PATTERNS.pick_random()
	_next_spawn += pattern.size() + randi_range(5, 8)
