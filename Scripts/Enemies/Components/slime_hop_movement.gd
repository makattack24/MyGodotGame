extends EnemyMovement
class_name SlimeHopMovement

## Slime-specific hopping movement behavior

@export var hop_distance: float = 25.0
@export var hop_duration: float = 0.4
@export var rest_time_min: float = 0.2
@export var rest_time_max: float = 0.6

enum HopState { RESTING, WINDING_UP, HOPPING }

var hop_state: HopState = HopState.RESTING
var hop_timer: float = 0.0
var hop_start_pos: Vector2 = Vector2.ZERO
var hop_target_pos: Vector2 = Vector2.ZERO
var hop_progress: float = 0.0

var sprite: Sprite2D
var shadow: Polygon2D
var hop_sound: AudioStreamPlayer2D

signal hop_started
signal hop_finished
signal windup_started

func initialize(p_enemy: CharacterBody2D, p_data: EnemyData) -> void:
	super.initialize(p_enemy, p_data)
	sprite = enemy.get_node_or_null("Sprite2D")
	shadow = enemy.get_node_or_null("Shadow")
	hop_sound = enemy.get_node_or_null("HopSound")
	
	hop_state = HopState.RESTING
	hop_timer = randf_range(0.1, 0.5)

func physics_process(delta: float) -> void:
	match hop_state:
		HopState.RESTING:
			_process_resting(delta)
		HopState.WINDING_UP:
			_process_windup(delta)
		HopState.HOPPING:
			_process_hopping(delta)

func reset_to_resting() -> void:
	hop_state = HopState.RESTING
	hop_timer = randf_range(rest_time_min, rest_time_max)

# Private methods

func _process_resting(delta: float) -> void:
	enemy.velocity = Vector2.ZERO
	hop_timer -= delta
	
	# Idle squash animation using lambda
	if sprite:
		var animate_idle = func():
			var squash_amount = sin(Time.get_ticks_msec() / 200.0) * 0.05
			sprite.scale = Vector2(0.65, 0.65) * Vector2(1.0 + squash_amount, 1.0 - squash_amount)
		animate_idle.call()
	
	if hop_timer <= 0:
		_start_windup()

func _process_windup(delta: float) -> void:
	enemy.velocity = Vector2.ZERO
	hop_timer -= delta
	
	# Squash down animation
	if sprite:
		var progress = 1.0 - (hop_timer / 0.15)
		var squash = 1.0 + (progress * 0.5)
		var stretch = 1.0 - (progress * 0.3)
		sprite.scale = Vector2(0.65, 0.65) * Vector2(squash, stretch)
	
	if hop_timer <= 0:
		_start_hop()

func _process_hopping(delta: float) -> void:
	hop_timer += delta
	hop_progress = hop_timer / hop_duration
	
	if hop_progress >= 1.0:
		_finish_hop()
	else:
		# Smooth hop movement
		var t = _ease_out_quad(hop_progress)
		enemy.global_position = hop_start_pos.lerp(hop_target_pos, t)
		
		# Stretch animation during hop using lambda
		if sprite:
			var animate_hop = func():
				var jump_height = sin(hop_progress * PI) * 0.4
				sprite.scale = Vector2(0.65, 0.65) * Vector2(1.0 - jump_height, 1.0 + jump_height)
				sprite.position.y = -jump_height * 8
				
				if shadow:
					var shadow_scale = 1.0 - (jump_height * 0.4)
					shadow.scale = Vector2(shadow_scale, shadow_scale)
			
			animate_hop.call()

func _start_windup() -> void:
	hop_state = HopState.WINDING_UP
	hop_timer = 0.15
	emit_signal("windup_started")

func _start_hop() -> void:
	hop_state = HopState.HOPPING
	hop_timer = 0.0
	hop_progress = 0.0
	hop_start_pos = enemy.global_position
	
	# Determine hop direction
	var hop_direction = _get_hop_direction()
	var distance_multiplier = _get_distance_multiplier()
	
	hop_target_pos = enemy.global_position + (hop_direction * hop_distance * distance_multiplier)
	
	# Play hop sound occasionally
	if hop_sound and randf() < 0.2 and player:
		var distance_to_player = get_distance_to_player()
		if distance_to_player <= data.aggro_range * 2.0:
			hop_sound.pitch_scale = randf_range(0.8, 1.2)
			hop_sound.volume_db = -18
			hop_sound.play()
	
	emit_signal("hop_started")

func _finish_hop() -> void:
	hop_state = HopState.RESTING
	enemy.global_position = hop_target_pos
	
	# Landing squash effect
	if sprite:
		sprite.position.y = 0
		sprite.scale = Vector2(0.65, 0.65) * Vector2(1.4, 0.6)
		
		var tween = enemy.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(sprite, "scale", Vector2(0.65, 0.65), 0.3)
	
	if shadow:
		shadow.scale = Vector2(1.0, 1.0)
	
	hop_timer = randf_range(rest_time_min, rest_time_max)
	emit_signal("hop_finished")

func _get_hop_direction() -> Vector2:
	if is_aggro and player:
		var to_player = get_direction_to_player()
		var random_angle = randf_range(-0.4, 0.4)
		var direction = to_player.rotated(random_angle)
		return apply_separation(direction)
	else:
		var distance_to_camp = get_distance_to_camp()
		if distance_to_camp > 10.0:
			var direction = get_direction_to_camp()
			return apply_separation(direction)
		else:
			var random_angle = randf() * TAU
			var direction = Vector2(cos(random_angle), sin(random_angle))
			return apply_separation(direction)

func _get_distance_multiplier() -> float:
	if is_aggro and randf() < 0.25:
		return 1.8  # Bigger hop sometimes
	elif not is_aggro:
		if get_distance_to_camp() > 10.0:
			return 0.7  # Return to camp
		else:
			return 0.5  # Idle hop
	return 1.0

func _ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
