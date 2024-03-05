class_name ObstacleSpawner
extends Node

const Y_SPAWN: float = -30

@export var spawning: bool = false
@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")

var _obstacle_scene: PackedScene = preload("res://Scenes/Objects/Obstacle.tscn")
var _next_spawn: int = 2
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conductor.beat_passed.connect(_on_beat_passed)
	pass # Replace with function body.


func _spawn_obstacle(column: int, y_offset: int) -> void:
	var obstacle: Obstacle = _obstacle_scene.instantiate()
	obstacle.transform.origin.y = Y_SPAWN - y_offset * Constants.OBSTACLE_HEIGHT
	obstacle.transform.origin.x = 160 + column * Constants.COLUMN_WIDTH
	add_child(obstacle)


func _on_beat_passed(beat: int) -> void:
	_handle_spawning(beat)
	for obstacle in get_children() as Array[Obstacle]:
		obstacle.move()
	
	
func _handle_spawning(beat: int) -> void:
	if beat < _next_spawn:
		return
	var pattern = Constants.PATTERNS.pick_random()
	for i in range(0, pattern.size()):
		var row = pattern[pattern.size()-i-1]
		for c in range(-2, 3):
			if (row >> (2-c)) % 2 == 1:
				_spawn_obstacle(c, i)
	_next_spawn += pattern.size() + _rng.randi_range(5, 8)
