class_name ObstacleSpawner
extends Node

signal did_tick

const Y_SPAWN: float = -Constants.OBSTACLE_HEIGHT

@export var spawning: bool = false
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var obstacles_node: Node2D = $Obstacles
@onready var tell_sprites_node: Node2D = $TellSprites
@onready var captains_node: Node2D = get_tree().get_first_node_in_group("captains")
@onready var tell_tick: AudioStreamPlayer = $TellTick
@onready var tell_tick_inverse: AudioStreamPlayer = $TellTickInverse
@onready var move_tick: AudioStreamPlayer = $MoveTick
@onready var move_tick_inverse: AudioStreamPlayer = $MoveTickInverse
@onready var fake_tick: AudioStreamPlayer = $FakeTick
@onready var fake_tick_inverse: AudioStreamPlayer = $FakeTickInverse

var _obstacle_scene: PackedScene = preload("res://Scenes/Objects/Obstacle.tscn")
var _down_arrow_img: CompressedTexture2D = preload("res://Sprites/down_arrow.png")
var _up_arrow_img: CompressedTexture2D = preload("res://Sprites/up_arrow.png")
var _dot_img: CompressedTexture2D = preload("res://Sprites/dot.png")
var _next_spawn: int = 2
var _pattern_spawn_count: int = 0
var _pattern_bag: Array = Constants.EASY_OBSTACLE_PATTERNS.duplicate()
var _move_pattern: Array[int] = [1,0,1,0,1,0,1,0]
var _faker_pattern: Array[bool] = [false,false,false,false,false,false,false,false]


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
	var half_beat_norm = beat_norm * 2 + fract
	match measure % 4:
		3:
			if _move_pattern[half_beat_norm] != 0 and not _faker_pattern[half_beat_norm]:
				_tick(_move_pattern[half_beat_norm] == -1)
		_:
			if fract == 0:
				_tick()
	
	for captain in captains_node.get_children() as Array[Captain]:
		if fract == 0 and measure / 2 % 2 == 0:
			captain.idle()
		if measure >= 4:
			if measure % 4 == 0 and half_beat_norm == 0:
				captain.move(-100)
			if measure % 4 == 1 and half_beat_norm == 0:
				captain.move(100)


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
				tell_sprite.texture = _down_arrow_img
				var captain = captains_node.get_child(half_beat_norm) as Captain
				if captain.is_faker:
					fake_tick.play()
				else:
					tell_tick.play()
				captain.whistle(false)
			elif _move_pattern[half_beat_norm] == -1:
				tell_sprite.texture = _up_arrow_img
				var captain = captains_node.get_child(half_beat_norm) as Captain
				if captain.is_faker:
					fake_tick.play()
				else:
					tell_tick_inverse.play()
				captain.whistle(true)
		3:
			if _move_pattern[half_beat_norm] == 1:
				if _faker_pattern[half_beat_norm]:
					fake_tick_inverse.play()
				else:
					move_tick.play()
				for captain in captains_node.get_children() as Array[Captain]:
					captain.idle()
			if _move_pattern[half_beat_norm] == -1:
				if _faker_pattern[half_beat_norm]:
					fake_tick_inverse.play()
				else:
					move_tick_inverse.play()
				for captain in captains_node.get_children() as Array[Captain]:
					captain.idle()
	if measure % 4 == 0 and half_beat_norm == 0:
		for child in tell_sprites_node.get_children() as Array[Sprite2D]:
			child.texture = _dot_img
	if measure % 4 == 0 and half_beat_norm == 4:
		_faker_pattern.fill(false)
		for captain in captains_node.get_children() as Array[Captain]:
			captain.is_faker = false
		var faker_index_bag = [0,1,2,3,4,5,6,7]
		faker_index_bag.shuffle()
		var num_faker = randi_range(max(0, measure / 24), min(3, measure / 8))
		for i in range(0, num_faker):
			_faker_pattern[faker_index_bag[i]] = true
			var captain = captains_node.get_child(faker_index_bag[i]) as Captain
			captain.is_faker = true


func _tick(inverse: bool = false) -> void:
	_handle_spawning(inverse)
	for obstacle in obstacles_node.get_children() as Array[Obstacle]:
		obstacle.move(inverse)
	did_tick.emit()


func _handle_spawning(inverse: bool = false) -> void:
	if inverse:
		_next_spawn += 1
		return
	if _next_spawn > 0:
		_next_spawn -= 1
		return
	var pattern = _pattern_bag.pick_random()
	for i in range(0, pattern.size()):
		var row = pattern[pattern.size()-i-1]
		for c in range(-2, 3):
			if (row >> (2-c)) % 2 == 1:
				_spawn_obstacle(c, i)
	
	var gap_size = randi_range(0, 2)
	if gap_size == 2:
		var c_gap = randi_range(-1, 1)
		for c in range(-2, 3):
			if c_gap != c:
				_spawn_obstacle(c, pattern.size()+1)
	
	_next_spawn += pattern.size() + gap_size
	
	_pattern_spawn_count += 1
	if _pattern_spawn_count == 3:
		_pattern_bag.append_array(Constants.MEDIUM_OBSTACLE_PATTERNS)
	if _pattern_spawn_count == 7:
		_pattern_bag.append_array(Constants.HARD_OBSTACLE_PATTERNS)
