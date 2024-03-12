class_name Captain
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var _idle_img: CompressedTexture2D = preload("res://Sprites/captain_idle.png")
var _whistle_img: CompressedTexture2D = preload("res://Sprites/captain_whistle.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func idle() -> void:
	sprite.flip_h = not sprite.flip_h
	sprite.texture = _idle_img


func whistle(inverse: bool) -> void:
	sprite.flip_h = not inverse
	sprite.texture = _whistle_img
