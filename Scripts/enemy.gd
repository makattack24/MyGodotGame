extends CharacterBody2D

# Health and behavior of the slime
@export var health: int = 3                    # Health of the slime
@export var knockback_strength: float = 300.0  # Knockback strength when hit
@export var hop_speed: float = 120.0           # Speed during hop
@export var player_hit_knockback: float = 150.0  # Knockback when hitting player
@export var attack_cooldown_time: float = 1.0  # Time between attacks
@export var aggro_range: float = 200.0         # Distance to detect and chase player
@export var return_home_range: float = 400.0   # Distance before returning to camp

# Hop/Bounce settings
@export var hop_distance: float = 25.0         # Distance of each hop
@export var hop_duration: float = 0.4          # Time each hop takes
@export var rest_time_min: float = 0.2         # Min pause between hops
@export var rest_time_max: float = 0.6         # Max pause between hops
@export var separation_distance: float = 20.0  # Distance to maintain from other slimes

# Loot settings
@export var coin_drop_chance: float = 1.0      # Chance to drop coins (0.0 to 1.0)
@export var min_coins: int = 1                 # Minimum coins to drop
@export var max_coins: int = 3                 # Maximum coins to drop

# Reference to the player (set this in the Inspector or dynamically during gameplay)
@export var player: CharacterBody2D                     # Target player node to follow

# Camp behavior
var camp_position: Vector2 = Vector2.ZERO      # Home position (camp center)
var is_aggro: bool = false                     # Whether enemy is chasing player

# Attack cooldown tracking
var attack_cooldown: float = 0.0
var knockback_timer: float = 0.0  # Timer for knockback from being hit

# Hop state machine
enum HopState { RESTING, WINDING_UP, HOPPING }
var hop_state: HopState = HopState.RESTING
var hop_timer: float = 0.0
var hop_start_pos: Vector2 = Vector2.ZERO
var hop_target_pos: Vector2 = Vector2.ZERO
var hop_progress: float = 0.0

# Visual/audio feedback (optional)
@onready var death_effect: CPUParticles2D = $DeathEffect
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var death_sound: AudioStreamPlayer2D = null
@onready var sprite: Sprite2D = $Sprite2D

# Shadow
var shadow: Polygon2D = null

# Coin drop scene
var coin_scene = preload("res://Scenes/coin_item.tscn")

func _physics_process(_delta: float) -> void:
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= _delta
	
	# Update knockback timer
	if knockback_timer > 0:
		knockback_timer -= _delta
		# During knockback, slow down naturally
		velocity = velocity.lerp(Vector2.ZERO, _delta * 5.0)
		move_and_slide()
		return
	
	# Check if player is in range
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		var distance_to_camp = global_position.distance_to(camp_position)
		
		# Determine aggro state
		if distance_to_player <= aggro_range:
			is_aggro = true
		elif distance_to_camp > return_home_range:
			is_aggro = false
		elif distance_to_player > aggro_range * 1.5:
			is_aggro = false
	
	# Hop state machine
	match hop_state:
		HopState.RESTING:
			velocity = Vector2.ZERO
			hop_timer -= _delta
			
			# Idle squash animation
			if sprite:
				var squash_amount = sin(Time.get_ticks_msec() / 200.0) * 0.05
				sprite.scale = Vector2(0.65, 0.65) * Vector2(1.0 + squash_amount, 1.0 - squash_amount)
			
			if hop_timer <= 0:
				start_windup()
		
		HopState.WINDING_UP:
			velocity = Vector2.ZERO
			hop_timer -= _delta
			
			# Squash down animation
			if sprite:
				var progress = 1.0 - (hop_timer / 0.15)
				var squash = 1.0 + (progress * 0.5)
				var stretch = 1.0 - (progress * 0.3)
				sprite.scale = Vector2(0.65, 0.65) * Vector2(squash, stretch)
			
			if hop_timer <= 0:
				start_hop()
		
		HopState.HOPPING:
			hop_timer += _delta
			hop_progress = hop_timer / hop_duration
			
			if hop_progress >= 1.0:
				finish_hop()
			else:
				# Smooth hop movement using ease out
				var t = ease_out_quad(hop_progress)
				global_position = hop_start_pos.lerp(hop_target_pos, t)
				
				# Stretch animation during hop
				if sprite:
					var jump_height = sin(hop_progress * PI) * 0.4
					sprite.scale = Vector2(0.65, 0.65) * Vector2(1.0 - jump_height, 1.0 + jump_height)
					
					# Adjust sprite position for jump height effect
					sprite.position.y = -jump_height * 8
					
					# Shrink shadow during hop
					if shadow:
						var shadow_scale = 1.0 - (jump_height * 0.4)
						shadow.scale = Vector2(shadow_scale, shadow_scale)
	
	move_and_slide()
	
	# Check collision with player
	if attack_cooldown <= 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("Player"):
				if collider.has_method("take_damage"):
					collider.call("take_damage", 1)
				
				# Bounce back
				var knockback_dir = (global_position - collider.global_position).normalized()
				velocity = knockback_dir * player_hit_knockback
				knockback_timer = 0.3
				attack_cooldown = attack_cooldown_time
				hop_state = HopState.RESTING
				hop_timer = randf_range(rest_time_min, rest_time_max)
				break

func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func start_windup() -> void:
	hop_state = HopState.WINDING_UP
	hop_timer = 0.15  # Short windup time

func start_hop() -> void:
	hop_state = HopState.HOPPING
	hop_timer = 0.0
	hop_progress = 0.0
	hop_start_pos = global_position
	
	# Determine hop direction and distance
	var hop_direction: Vector2
	var distance_multiplier = 1.0
	
	if is_aggro and player != null:
		# Hop toward player with randomness
		var to_player = (player.global_position - global_position).normalized()
		var random_angle = randf_range(-0.4, 0.4)
		hop_direction = to_player.rotated(random_angle)
		
		# Apply separation from other slimes
		hop_direction = apply_separation(hop_direction)
		
		# Sometimes do a bigger hop
		if randf() < 0.25:
			distance_multiplier = 1.8
	else:
		# Return to camp or random idle hop
		var distance_to_camp = global_position.distance_to(camp_position)
		if distance_to_camp > 10.0:
			hop_direction = (camp_position - global_position).normalized()
			hop_direction = apply_separation(hop_direction)
			distance_multiplier = 0.7
		else:
			# Random idle hop
			var random_angle = randf() * TAU
			hop_direction = Vector2(cos(random_angle), sin(random_angle))
			hop_direction = apply_separation(hop_direction)
			distance_multiplier = 0.5
	
	hop_target_pos = global_position + (hop_direction * hop_distance * distance_multiplier)
	
	# Play hop sound occasionally (20% chance to avoid spam)
	if hit_sound and randf() < 0.2:
		hit_sound.pitch_scale = randf_range(0.8, 1.2)
		hit_sound.volume_db = -18
		hit_sound.play()

func apply_separation(desired_direction: Vector2) -> Vector2:
	"""Avoid crowding with other slimes"""
	var separation = Vector2.ZERO
	var nearby_count = 0
	
	# Check for nearby enemies
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < separation_distance and distance > 0:
			# Push away from this enemy
			var away = (global_position - enemy.global_position).normalized()
			var strength = (separation_distance - distance) / separation_distance
			separation += away * strength
			nearby_count += 1
	
	# Blend desired direction with separation
	if nearby_count > 0:
		separation = separation.normalized()
		# Weight more heavily toward separation if crowded
		var separation_weight = min(nearby_count * 0.4, 0.8)
		return (desired_direction * (1.0 - separation_weight) + separation * separation_weight).normalized()
	
	return desired_direction

func create_shadow() -> void:
	"""Create a simple shadow sprite under the slime"""
	shadow = Polygon2D.new()
	shadow.name = "Shadow"
	
	# Create an ellipse shape for the shadow
	var points = PackedVector2Array()
	var num_points = 16
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		var x = cos(angle) * 10
		var y = sin(angle) * 5
		points.append(Vector2(x, y))
	
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.5)  # Semi-transparent black
	shadow.position = Vector2(0, 6)  # Slightly below center
	
	# Make sure shadow renders below sprite
	if sprite:
		add_child(shadow)
		move_child(shadow, 0)  # Move to first position (renders first)
	else:
		add_child(shadow)
	
	print("Shadow created for enemy")

func finish_hop() -> void:
	hop_state = HopState.RESTING
	global_position = hop_target_pos
	
	# Landing squash effect
	if sprite:
		sprite.position.y = 0
		sprite.scale = Vector2(0.65, 0.65) * Vector2(1.4, 0.6)
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(sprite, "scale", Vector2(0.65, 0.65), 0.3)
	
	# Reset shadow
	if shadow:
		shadow.scale = Vector2(1.0, 1.0)
	
	# Set random rest time
	hop_timer = randf_range(rest_time_min, rest_time_max)

func _on_hit(damage: int, knockback_direction: Vector2) -> void:
	# Reduce health based on damage received
	health -= damage
	print("Enemy hit! Remaining health: ", health)
	
	# Show damage indicator
	show_damage_text(damage)

	# Apply knockback effect
	velocity = knockback_direction.normalized() * knockback_strength
	knockback_timer = 0.4
	
	# Reset to resting state
	hop_state = HopState.RESTING
	hop_timer = 0.2
	
	# Flash/squash effect when hit
	if sprite:
		sprite.scale = Vector2(0.65, 0.65) * Vector2(0.8, 1.2)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(0.65, 0.65), 0.15)
	
	# Trigger hit visual/audio effects
	play_hit_feedback()

	# Check if the enemy is dead
	if health <= 0:
		die()  # Handle death behavior

func play_hit_feedback() -> void:
	# Play feedback effects when hit (optional)
	if hit_sound:
		hit_sound.play()

	# Emit particles for visual feedback (brief burst)
	if death_effect:
		death_effect.emitting = true
		get_tree().create_timer(0.5).timeout.connect(func(): 
			if death_effect:
				death_effect.emitting = false
		)

func show_damage_text(damage: int) -> void:
	"""Creates a floating damage text effect"""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	# Create a label for the floating damage text
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.modulate = Color(0.7, 0.15, 0.15)  # Darker red color
	damage_label.z_index = 100  # Draw on top
	
	# Position above the enemy
	damage_label.position = global_position + Vector2(-15, -40)
	
	# Add to scene root
	tree.root.add_child(damage_label)
	
	# Animate the label (float up and fade out)
	var tween = damage_label.create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	
	# Delete after animation
	tween.finished.connect(func(): damage_label.queue_free())

func die() -> void:
	# Handle death behavior
	print("Enemy died!")
	
	# Drop coins
	drop_coins()
	
	# Play death feedback (animation or effects)
	if death_effect:
		death_effect.emitting = true
	
	# Play death sound and wait for it to finish
	if death_sound and death_sound.stream:
		# Reparent death sound to scene root so it doesn't get deleted
		var scene_root = get_tree().root
		remove_child(death_sound)
		scene_root.add_child(death_sound)
		death_sound.global_position = global_position
		death_sound.play()
		
		# Remove the enemy visuals immediately
		queue_free()
		
		# Wait for sound to finish then delete audio player
		await death_sound.finished
		death_sound.queue_free()
	else:
		# No death sound, remove immediately
		queue_free()

func drop_coins() -> void:
	"""Drop coins when enemy dies"""
	# Check if coins should drop based on chance
	if randf() <= coin_drop_chance:
		# Determine number of coins to drop
		var num_coins = randi_range(min_coins, max_coins)
		
		# Spawn each coin with slight position variation
		for i in range(num_coins):
			var coin = coin_scene.instantiate()
			
			# Add random offset so coins don't stack perfectly
			var offset = Vector2(
				randf_range(-15, 15),
				randf_range(-15, 15)
			)
			coin.global_position = global_position + offset
			
			# Add to parent (deferred to avoid issues)
			get_parent().add_child.call_deferred(coin)

func set_player_reference(player_ref: Node2D) -> void:
	# Set the player reference for this enemy
	player = player_ref

func set_camp_position(camp_pos: Vector2) -> void:
	"""Set the enemy's camp/home position"""
	camp_position = camp_pos

func _ready() -> void:
	# Add enemy to the Enemies group for player attack detection
	add_to_group("Enemies")
	print("Enemy added to Enemies group!")
	
	# Get death sound if it exists
	if has_node("DeathSound"):
		death_sound = $DeathSound
	
	# Set camp position to current position if not set
	if camp_position == Vector2.ZERO:
		camp_position = global_position
	
	# Ensure player reference exists (if assigned dynamically)
	if player == null:
		print("Warning: Player is not assigned to this enemy!")
	
	# Create shadow
	create_shadow()
	
	# Start in resting state with random initial delay
	hop_state = HopState.RESTING
	hop_timer = randf_range(0.1, 0.5)