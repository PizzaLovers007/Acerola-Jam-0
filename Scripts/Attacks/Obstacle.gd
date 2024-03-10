class_name Obstacle
extends Node2D

@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if transform.origin.y > Constants.SCREEN_HEIGHT * 1.5:
		queue_free()


func move() -> void:
	var target_origin = transform.origin + Constants.OBSTACLE_HEIGHT * Vector2.DOWN
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", target_origin, conductor.get_beat_time() / 4)
	tween.play()
