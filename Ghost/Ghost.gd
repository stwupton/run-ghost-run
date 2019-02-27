extends KinematicBody2D

signal captured
signal entered_door

const PowerKey = preload('res://PowerKey/PowerKey.gd')
const PowerDoor = preload('res://PowerDoor/PowerDoor.gd')

export(float) var _movement_speed = 1.0

onready var _animated_sprite = $AnimatedSprite
onready var _area2d = $Area2D
onready var _powered_up_particles = $AnimatedSprite/PoweredUpParticles
onready var _phase_particles = $PhaseParticles
onready var _tween = $Tween
onready var _light = $AnimatedSprite/Light2D
onready var _timer = $Timer
onready var _phase_sound = $PhaseSound
onready var _power_key_sound = $PowerKeySound
onready var _captured_sound = $CapturedSound

var _powered_up = false
var _captured = false
var _phased = false
var absorbed_light = 0

func _ready():
	set_physics_process(true)
	
	_area2d.connect('area_entered', self, '_on_area_entered')
	
func _on_area_entered(area):
	if area is PowerKey:
		area.queue_free()
		_powered_up = true
		_powered_up_particles.emitting = true

		# Change colour to red.
		_animated_sprite.modulate.g = 0
		_animated_sprite.modulate.b = 0

		_power_key_sound.play()
	elif area is PowerDoor:
		if _powered_up && !_phased:
			# Fade sprite.
			var from = _animated_sprite.modulate
			var to = _animated_sprite.modulate
			to.a = 0
			_tween.interpolate_property( \
				_animated_sprite, \
				'modulate', \
				from, \
				to, \
				2, \
				Tween.TRANS_LINEAR, \
				Tween.EASE_IN_OUT \
			)
			_tween.connect('tween_completed', self, '_on_fade_tween_complete')
			_tween.start()
			_phase_particles.emitting = true
			_phased = true
			_phase_sound.play()
			set_physics_process(false)

func _on_fade_tween_complete(_o, _np):
	emit_signal('entered_door')

func _physics_process(delta):
	absorbed_light -= .002
	absorbed_light = clamp(absorbed_light, 0, 1.5)
	_light.energy = absorbed_light

	var direction = Vector2()
	if Input.is_action_pressed('ui_left'):
		direction.x -= 1
	if Input.is_action_pressed('ui_right'):
		direction.x += 1
	if Input.is_action_pressed('ui_up'):
		direction.y -= 1
	if Input.is_action_pressed('ui_down'):
		direction.y += 1
		
	var new_animation
	_animated_sprite.flip_h = false
	if direction.y < 0:
		new_animation = 'Up'
	else:
		new_animation = 'Down'
	if direction.x > 0:
		new_animation = 'Side'
	elif direction.x < 0:
		new_animation = 'Side'
		_animated_sprite.flip_h = true
		
	if _animated_sprite.animation != new_animation:
		_animated_sprite.play(new_animation)
	
	direction = direction.normalized()

	move_and_slide(direction * _movement_speed)

# Method called by other nodes to capture the ghost.
func capture():
	if !_captured && !_phased:
		set_physics_process(false)
		_captured = true
		_timer.connect('timeout', self, '_emit_captured_callback')
		_timer.start()
		_captured_sound.play()
		return true
	else:
		return false

func _emit_captured_callback():
	emit_signal('captured')

func absorb_light():
	absorbed_light += .02
	absorbed_light = clamp(absorbed_light, 0, 1.5)
	_light.energy = absorbed_light