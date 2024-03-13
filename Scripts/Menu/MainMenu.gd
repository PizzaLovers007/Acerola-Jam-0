class_name MainMenu
extends Node

const _PLAYER_MOVES: Array[int] = [1, 0, -1, 0, 0, 0, 0, 0]
const _CAPTAIN_MOVES: Array[int] = [1, 0, -1, 0, 0, 0, 0, 0]
const _FAKER_MOVES: Array[int] = [0, 0, 0, 0, 1, 0, -1, 0]
const _ANT_MOVES: Array[int] = [1, 0, -1, 0, 0, 0, 0, 0]

@onready var conductor: Conductor = get_tree().get_first_node_in_group("conductor")
@onready var obstacles_node: Node2D = $MainCanvasLayer/Obstacles
@onready var captain: Captain = $MainCanvasLayer/Captain
@onready var captain_tell: Sprite2D = $MainCanvasLayer/Captain/Tell
@onready var faker: Captain = $MainCanvasLayer/Faker
@onready var faker_tell: Sprite2D = $MainCanvasLayer/Faker/Tell
@onready var player: Player = $MainCanvasLayer/Player
@onready var left_key_sprite: Sprite2D = $MainCanvasLayer/LeftKey
@onready var right_key_sprite: Sprite2D = $MainCanvasLayer/RightKey
@onready var title_sprite: Sprite2D = $MainCanvasLayer/Title
@onready var play_text: RichTextLabel = $MainCanvasLayer/PlayText
@onready var tutorial_text: RichTextLabel = $MainCanvasLayer/TutorialText

var _down_arrow_img: CompressedTexture2D = preload("res://Sprites/down_arrow.png")
var _up_arrow_img: CompressedTexture2D = preload("res://Sprites/up_arrow.png")
var _dot_img: CompressedTexture2D = preload("res://Sprites/dot.png")
var _key_up_img: CompressedTexture2D = preload("res://Sprites/right_key_up.png")
var _key_down_img: CompressedTexture2D = preload("res://Sprites/right_key_down.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	conductor.quarter_passed.connect(_bounce_title)
	conductor.quarter_passed.connect(func(beat: int): _animate_text(play_text, beat))
	conductor.quarter_passed.connect(func(beat: int): _animate_text(tutorial_text, beat))
	conductor.quarter_passed.connect(_move_obstacles)


func _bounce_title(beat: int) -> void:
	var sign = 1 if beat % 2 == 0 else -1
	var target_origin = title_sprite.position + Vector2.DOWN * 30 * sign
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(title_sprite, "position", target_origin, conductor.get_beat_time() / 4)
	tween.play()


func _animate_text(text: RichTextLabel, beat: int) -> void:
	var target_scale = 1.1 if beat % 2 == 0 else 1
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(text, "scale", Vector2.ONE * target_scale, conductor.get_beat_time() / 4)
	tween.play()


func _move_obstacles(beat: int) -> void:
	match _CAPTAIN_MOVES[beat % 8]:
		-1:
			captain.whistle(true)
			captain_tell.texture = _up_arrow_img
		0: 
			captain.idle()
			captain_tell.texture = _dot_img
		1: 
			captain.whistle(false)
			captain_tell.texture = _down_arrow_img
	match _FAKER_MOVES[beat % 8]:
		-1:
			faker.whistle(true)
			faker_tell.texture = _up_arrow_img
		0: 
			faker.idle()
			faker_tell.texture = _dot_img
		1: 
			faker.whistle(false)
			faker_tell.texture = _down_arrow_img
	match _ANT_MOVES[beat % 8]:
		-1:
			for ant in obstacles_node.get_children() as Array[Obstacle]:
				ant.move_menu(-90)
		0:
			for ant in obstacles_node.get_children() as Array[Obstacle]:
				ant.idle()
		1:
			for ant in obstacles_node.get_children() as Array[Obstacle]:
				ant.move_menu(90)
	player.move(_PLAYER_MOVES[beat % 8])
	match _PLAYER_MOVES[beat % 8]:
		-1:
			left_key_sprite.texture = _key_down_img
			right_key_sprite.texture = _key_up_img
		0:
			left_key_sprite.texture = _key_up_img
			right_key_sprite.texture = _key_up_img
		1:
			left_key_sprite.texture = _key_up_img
			right_key_sprite.texture = _key_down_img


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not conductor.is_playing:
		conductor.play()
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")
