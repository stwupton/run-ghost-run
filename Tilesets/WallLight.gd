extends Node2D

const Ghost = preload('res://Ghost/Ghost.gd')

export(bool) var on = false setget _set_on

onready var _lights = $Lights

var _ghost_in_light

func _ready():
	_set_on(on)
	set_physics_process(true)

	for light in _lights.get_children():
		light.connect('body_entered', self, '_on_body_entered')
		light.connect('body_exited', self, '_on_body_exited')

func _physics_process(delta):
	if _ghost_in_light != null:
		_ghost_in_light.absorb_light()

func _on_body_entered(body):
	if body is Ghost:
		_ghost_in_light = body

func _on_body_exited(body):
	if body is Ghost:
		_ghost_in_light = null

func _set_on(x):
	on = x
	if !is_inside_tree() || _lights == null:
		return 
	for light in _lights.get_children():
		light.get_node('Light2D').enabled = x
		light.get_node('CollisionShape2D').disabled = !x

