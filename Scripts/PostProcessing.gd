extends Node

@onready var wavy: ColorRect = get_node("Wavy/ColorRect");
@onready var dim: ColorRect = get_node("Dim/ColorRect");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	wavy.material.set_shader_parameter("time", Time.get_ticks_usec() / 1000000.0)
	dim.material.set_shader_parameter("time", Time.get_ticks_usec() / 1000000.0)
	pass
