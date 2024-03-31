class_name Captain
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export var is_faker: bool = false

var _cap_idle_img: CompressedTexture2D = preload("res://Sprites/captain_idle.png")
var _cap_whistle_img: CompressedTexture2D = preload("res://Sprites/captain_whistle.png")
var _faker_idle_img: CompressedTexture2D = preload("res://Sprites/faker_idle.png")
var _faker_whistle_img: CompressedTexture2D = preload("res://Sprites/faker_whistle.png")
var _start_x: float
var _tween_instance: TweenManager.TweenInstance


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_x = position.x
	_tween_instance = TweenManager.create_instance(self)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func idle() -> void:
	sprite.flip_h = not sprite.flip_h
	sprite.texture = _faker_idle_img if is_faker else _cap_idle_img


func whistle(inverse: bool) -> void:
	sprite.flip_h = not inverse
	sprite.texture = _faker_whistle_img if is_faker else _cap_whistle_img


func move(x_amount: float) -> void:
	var tween = _tween_instance.create_tween("move")
	var target_x = sprite.position.x + x_amount
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(sprite, "position:x", target_x, 0.4)
	tween.play()
