extends KinematicBody2D

const Ghost = preload('res://Ghost/Ghost.gd')
const AIFaceDirection = preload('res://AI/AIFaceDirection.gd')
const AIMoveBy = preload('res://AI/AIMoveBy.gd')

export(float) var _walking_speed = 1

onready var _ai_commands = $AICommands
onready var _lights = $Lights
onready var _animated_sprite = $AnimatedSprite
onready var _timer = $Timer
onready var _alert_animation = $AlertIcon/AnimationPlayer

var _ghost_in_light
var _current_light
var _command_index = 0
var _commands = []
var _move_to

func _ready():
	set_physics_process(true)

	for light in _lights.get_children():
		light.connect('body_entered', self, '_on_body_entered_light')
		light.connect('body_exited', self, '_on_body_exited_light')
	
	# Start AI.
	_commands = _ai_commands.get_children()
	if _commands.empty():
		return
	
	_run_command()

func _physics_process(delta):
	if _current_light != null && _ghost_in_light != null:
		var space_state = get_world_2d().direct_space_state
		var emission_point = _current_light.get_node('EmissionPoint')
		var result = space_state.intersect_ray( \
			emission_point.global_position, \
			_ghost_in_light.global_position, \
			[self, _current_light, _ghost_in_light.get_node('Area2D')] \
		)
		
		if result.has('collider') && result.collider == _ghost_in_light:
			if emission_point.global_position.distance_to(result.position) < 80:
				var success = _ghost_in_light.capture()
				if success:
					set_physics_process(false)
					_alert_animation.play('Alerted')
			else:
				_ghost_in_light.absorb_light()

	# AIMoveBy.
	if !_commands.empty() && _commands[_command_index] is AIMoveBy:
		if _move_to == null:
			var command = _commands[_command_index]
			var direction_node_name
			if command.x_axis:
				_move_to = Vector2(position.x + command.value, position.y)
				direction_node_name = 'Right' if command.value > 0 else 'Left'
			else:
				_move_to = Vector2(position.x, position.y + command.value)
				direction_node_name = 'Down' if command.value > 0 else 'Up'

			if direction_node_name == null:
				_next_command()
				return

			for light in _lights.get_children():
				if light.name != direction_node_name:
					light.visible = false
					light.get_node('CollisionPolygon2D').disabled = true
				else:
					light.visible = true
					light.get_node('CollisionPolygon2D').disabled = false
					_current_light = light

			match direction_node_name:
				'Right':
					_animated_sprite.play('SideMove')
					_animated_sprite.flip_h = false
				'Left':
					_animated_sprite.play('SideMove')
					_animated_sprite.flip_h = true
				_:
					_animated_sprite.play(direction_node_name + 'Move')

		else:
			var direction = (_move_to - position).normalized()

			move_and_slide(direction * _walking_speed)

			if position.distance_to(_move_to) <= 1:
				position = _move_to
				_next_command()


func _on_body_entered_light(body):
	if body is Ghost:
		_ghost_in_light = body

func _on_body_exited_light(body):
	if body == _ghost_in_light:
		_ghost_in_light = null

func _next_command():
	_command_index += 1
	_move_to = null
	
	if _command_index >= _commands.size():
		_command_index = 0

	_run_command()
		

func _run_command():
	var command = _commands[_command_index]
	
	# AIFaceDirection
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
		
		for direction_node in _lights.get_children():
			if direction_node.name != direction_node_name:
				direction_node.visible = false
				direction_node.get_node('CollisionPolygon2D').disabled = true
			else:
				direction_node.visible = true
				direction_node.get_node('CollisionPolygon2D').disabled = false
				_current_light = direction_node

		match direction_node_name:
			'Right':
				_animated_sprite.play('SideStatic')
				_animated_sprite.flip_h = false
			'Left':
				_animated_sprite.play('SideStatic')
				_animated_sprite.flip_h = true
			_:
				_animated_sprite.play(direction_node_name + 'Static')

		# Use timer to run next command.
		_timer.wait_time = command.duration
		_timer.connect('timeout', self, '_next_command')
		_timer.start()
