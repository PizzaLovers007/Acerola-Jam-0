class_name ObstacleSpawner
extends Node

const Y_SPAWN: float = -Constants.OBSTACLE_HEIGHT

@export var spawning: bool = false
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var obstacles_node: Node2D = $Obstacles
@onready var tell_sprites_node: Node2D = $TellSprites
@onready var captain_node: Captain = get_tree().get_first_node_in_group("captain")
@onready var tell_tick: AudioStreamPlayer = $TellTick
@onready var tell_tick_inverse: AudioStreamPlayer = $TellTickInverse
@onready var move_tick: AudioStreamPlayer = $MoveTick
@onready var move_tick_inverse: AudioStreamPlayer = $MoveTickInverse

var _obstacle_scene: PackedScene = preload("res://Scenes/Objects/Obstacle.tscn")
var _down_arrow_img: CompressedTexture2D = preload("res://Sprites/down_arrow.png")
var _up_arrow_img: CompressedTexture2D = preload("res://Sprites/up_arrow.png")
var _dot_img: CompressedTexture2D = preload("res://Sprites/dot.png")
var _next_spawn: int = 2
var _next_pattern: Array = Constants.OBSTACLE_PATTERNS.pick_random()
var _move_pattern: Array[int] = [1,0,1,0,1,0,1,0]

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
			if _move_pattern[half_beat_norm] != 0:
				_tick(_move_pattern[half_beat_norm] == -1)
		_:
			if fract == 0:
				_tick()
	
	if fract == 0 and measure / 2 % 2 == 0:
		captain_node.idle()

func _schedule_sounds(beat: int, fract: int) -> void:
	var measure = beat / 4
	var beat_norm = beat % 4
	if measure % 4 == 1 and beat_norm == 0 and fract == 0:
		var pattern = [
			Constants.MOVE_PATTERNS.pick_random(),
			Constants.MOVE_PATTERNS.pick_random(),
			Constants.MOVE_INVERSE_PATTERNS.pick_random()
		].pick_random()
		for i in range(0, 8):
			_move_pattern[i] = pattern[i]
			
	var half_beat_norm = beat_norm * 2 + fract
	var tell_sprite = tell_sprites_node.get_child(half_beat_norm) as Sprite2D
	match measure % 4:
		2:
			if _move_pattern[half_beat_norm] == 1:
				tell_tick.play()
				tell_sprite.texture = _down_arrow_img
				captain_node.whistle(false)
			elif _move_pattern[half_beat_norm] == -1:
				tell_tick_inverse.play()
				tell_sprite.texture = _up_arrow_img
				captain_node.whistle(true)
		3:
			if _move_pattern[half_beat_norm] == 1:
				move_tick.play()
				captain_node.idle()
			if _move_pattern[half_beat_norm] == -1:
				move_tick_inverse.play()
				captain_node.idle()
	if measure % 4 == 0 and half_beat_norm == 0:
		for child in tell_sprites_node.get_children() as Array[Sprite2D]:
			child.texture = _dot_img


func _tick(inverse: bool = false) -> void:
	_handle_spawning(inverse)
	for obstacle in obstacles_node.get_children() as Array[Obstacle]:
		obstacle.move(inverse)

	
func _handle_spawning(inverse: bool = false) -> void:
	if inverse:
		_next_spawn += 1
		return
	if _next_spawn > 0:
		_next_spawn -= 1
		return
	var pattern = _next_pattern
	for i in range(0, pattern.size()):
		var row = pattern[pattern.size()-i-1]
		for c in range(-2, 3):
			if (row >> (2-c)) % 2 == 1:
				_spawn_obstacle(c, i)
				
	_next_pattern = Constants.OBSTACLE_PATTERNS.pick_random()
	_next_spawn += pattern.size() + randi_range(0, 2)
