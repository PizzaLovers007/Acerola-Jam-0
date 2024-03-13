class_name Captain
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export var is_faker: bool = false

var _cap_idle_img: CompressedTexture2D = preload("res://Sprites/captain_idle.png")
var _cap_whistle_img: CompressedTexture2D = preload("res://Sprites/captain_whistle.png")
var _faker_idle_img: CompressedTexture2D = preload("res://Sprites/faker_idle.png")
var _faker_whistle_img: CompressedTexture2D = preload("res://Sprites/faker_whistle.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
