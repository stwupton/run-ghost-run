extends Node

const _LEVEL_MAX = 7
const _GHOST_SCN = preload('res://Ghost/Ghost.tscn')

onready var _tween = $Tween

var _current_level_id = 1
var _current_level_scn
var _current_level
var _ghost

func _input(event):
	if event is InputEventKey && event.scancode == KEY_ESCAPE:
		get_tree().quit()

func _ready():
	set_process_input(true)

	# Set up first level.
	_load_level()
	_show_level()

func _load_level():
	_current_level_scn = load('res://Levels/Level' + str(_current_level_id) + '.tscn')

func _hide_level():
	# Tween out level.
	_tween.interpolate_property( \
		_current_level, 
		'position', \
		Vector2(0, 0), \
		Vector2(0, 1080), \
		.4, \
		Tween.TRANS_LINEAR, \
		Tween.EASE_IN \
	)
	_tween.connect('tween_completed', self, '_on_hide_tween_complete')
	_tween.start()

func _on_hide_tween_complete(_o, _np):
	_tween.disconnect('tween_completed', self, '_on_hide_tween_complete')
	_show_level()

func _show_level():
	if _current_level != null:
		_current_level.queue_free()

	# Instance level.
	_current_level = _current_level_scn.instance()
	_current_level.global_position.y = -1080
	add_child(_current_level)

	# Add ghost.
	_ghost = _GHOST_SCN.instance()
	var starting_position = _current_level.get_node('Start').position
	_ghost.position = starting_position
	_current_level.get_node('Wall').add_child(_ghost)
	_ghost.connect('captured', self, '_on_ghost_captured')
	_ghost.connect('entered_door', self, '_on_ghost_entered_door')

	# Tween in level.
	_tween.interpolate_property( \
		_current_level, \
		'position', \
		Vector2(0, -1080), \
		Vector2(0, 0), \
		.8, \
		Tween.TRANS_LINEAR, \
		Tween.EASE_OUT\
	)
	_tween.start()

	_ghost.get_node('Dialogue/AnimationPlayer').play('Level' + str(_current_level_id))

func _on_ghost_captured():
	_hide_level()

func _on_ghost_entered_door():
	_current_level_id += 1
	if _current_level_id > _LEVEL_MAX:
		_current_level_id = 1
	_load_level()
	_hide_level()