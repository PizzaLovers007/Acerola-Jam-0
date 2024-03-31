class_name Obstacle
extends Area2D

@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var sprite: Sprite2D = $Sprite2D
@onready var anger_sprite: Sprite2D = $AngerSprite

@export var initial_flip_v = false
@export var initial_flip_h = false

var _tween_instance: TweenManager.TweenInstance


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.flip_v = initial_flip_v
	sprite.flip_h = initial_flip_h
	_tween_instance = TweenManager.create_instance(self)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if transform.origin.y > Constants.SCREEN_HEIGHT * 1.5:
		queue_free()


func idle() -> void:
	sprite.flip_h = not sprite.flip_h


func move(inverse: bool = false) -> void:
	sprite.flip_v = inverse
	sprite.flip_h = not sprite.flip_h
	
	var tween = _tween_instance.create_tween("move")
	var move_vector = Constants.OBSTACLE_HEIGHT * Vector2.DOWN * (-1 if inverse else 1)
	var target_origin = transform.origin + move_vector
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position", target_origin, conductor.get_beat_time() / 4)
	tween.play()


func move_menu(y_amount: float) -> void:
	sprite.flip_v = y_amount < 0
	
	var tween = _tween_instance.create_tween("move")
	var target_y = position.y + y_amount
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position:y", target_y, conductor.get_beat_time() / 4)
	tween.play()


func show_angry() -> void:
	anger_sprite.visible = true
	anger_sprite.rotation_degrees = 180 if sprite.flip_v else 0
	sprite.modulate = Color.ORANGE_RED


func is_down() -> bool:
	return not sprite.flip_v
