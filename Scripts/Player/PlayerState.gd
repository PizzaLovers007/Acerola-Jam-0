class_name PlayerState
extends Node2D

@onready var sprite: Sprite2D = get_node("Sprite")

@export var health: int = 3
@export var column: int = 0:
	set(value):
		if value >= -2 and value <= 2:
			column = value
			transform.origin.x = Constants.MIDDLE_X + value * Constants.COLUMN_WIDTH
			
@export var is_controllable: bool = true
@export var invuln_time: float = 0:
	set(value):
		if invuln_time == value:
			return
		invuln_time = value
		if value != 0:
			sprite.modulate.a = 0.5
		else:
			sprite.modulate.a = 1
