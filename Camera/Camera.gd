extends KinematicBody2D

const AIFaceDirection = preload('res://AI/AIFaceDirection.gd')
const Ghost = preload('res://Ghost/Ghost.gd')

onready var _ai_commands = $AICommands
onready var _viewports = $Viewports
onready var _animated_sprite = $AnimatedSprite
onready var _timer = $Timer
onready var _alert_animation = $AlertIcon/AnimationPlayer

var _command_index = 0
var _commands = []
var _ghost_in_viewport

func _ready():
	set_physics_process(true)

	for viewport in _viewports.get_children():
		viewport.connect('body_entered', self, '_on_body_entered')
		viewport.connect('body_exited', self, '_on_body_exited')

	_commands = _ai_commands.get_children()
	if _commands.empty():
		return
	
	_run_command()

func _physics_process(delta):
	if _ghost_in_viewport != null && _ghost_in_viewport.absorbed_light > .8:
		var success = _ghost_in_viewport.capture()
		if success:
			set_physics_process(false)
			_timer.stop()
			_alert_animation.play('Alerted')

func _next_command():
	_command_index += 1
	
	if _command_index >= _commands.size():
		_command_index = 0

	_run_command()
		
func _on_body_entered(body):
	if body is Ghost:
		_ghost_in_viewport = body

func _on_body_exited(body):
	if body is Ghost:
		_ghost_in_viewport = null

func _run_command():
	var command = _commands[_command_index]
	
	if command is AIFaceDirection:
		var direction_node_name
		if command.x > 0:
			direction_node_name = 'Right'
		if command.x < 0:
			direction_node_name = 'Left'
		if command.y > 0:
			direction_node_name = 'Down'
		if command.y < 0:
			direction_node_name = 'Up'

		if direction_node_name == null:
			_next_command()
			return
		
		for direction_node in _viewports.get_children():
			if direction_node.name != direction_node_name:
				direction_node.visible = false
				direction_node.get_node('CollisionShape2D').disabled = true
			else:
				direction_node.visible = true
				direction_node.get_node('CollisionShape2D').disabled = false
				match direction_node_name:
					'Right':
						_animated_sprite.play('Side')
						_animated_sprite.flip_h = false
					'Left':
						_animated_sprite.play('Side')
						_animated_sprite.flip_h = true
					_:
						_animated_sprite.play(direction_node_name)

				# Use timer to run next command.
				_timer.wait_time = command.duration
				_timer.connect('timeout', self, '_next_command')
				_timer.start()
				
