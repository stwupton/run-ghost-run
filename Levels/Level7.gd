extends Node2D

onready var _animation = $AnimationPlayer

func _ready():
	set_process(true)
	_animation.connect('animation_finished', self, '_on_animation_finished')
	_animation.play('End')

func _process(delta):
	if $Wall.has_node('Ghost'):
		$Wall/Ghost.set_physics_process(false)

func _on_animation_finished(_n):
	$Wall/Ghost.emit_signal('entered_door')
