class_name SaveSystem
extends Node

static var high_score: int = 0:
	set(value):
		high_score = value
		_mark_dirty()
static var volume: float = -6:
	set(value):
		volume = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
		_mark_dirty()
static var visual_delay: int = 0:
	set(value):
		visual_delay = value
		_mark_dirty()

static var _unsaved_values: bool = false
static var _debounce_time: float = 0


static func _static_init() -> void:
	var file = FileAccess.open("user://save.dat", FileAccess.READ)
	if file == null:
		print("no file")
		return
	high_score = file.get_32()
	volume = file.get_float()
	visual_delay = file.get_32()
	print("loaded! high_score=", high_score, " volume=", volume, " visual_delay=", visual_delay)


func _process(delta: float) -> void:
	_debounce_time += delta
	if _debounce_time > 3:
		_save_changes()


static func _mark_dirty() -> void:
	_unsaved_values = true
	_debounce_time = 0


static func _save_changes() -> void:
	if not _unsaved_values:
		return
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_32(high_score)
	file.store_float(volume)
	file.store_32(visual_delay)
	_unsaved_values = false
	print("saved!")


func _exit_tree() -> void:
	_save_changes()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_changes()
		get_tree().quit()
