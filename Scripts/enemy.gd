extends CharacterBody2D

# Health and behavior of the slime
@export var health: int = 3                    # Health of the slime
@export var knockback_strength: float = 300.0  # Knockback strength when hit
@export var speed: float = 50.0                # Movement speed of the slime
@export var player_hit_knockback: float = 150.0  # Knockback when hitting player
@export var attack_cooldown_time: float = 1.0  # Time between attacks
@export var aggro_range: float = 200.0         # Distance to detect and chase player
@export var return_home_range: float = 400.0   # Distance before returning to camp

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

# Visual/audio feedback (optional)
@onready var death_effect: CPUParticles2D = $DeathEffect
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var death_sound: AudioStreamPlayer2D = null

# Coin drop scene
var coin_scene = preload("res://Scenes/coin_item.tscn")

func _physics_process(_delta: float) -> void:
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= _delta
	
	# Update knockback timer
	if knockback_timer > 0:
		knockback_timer -= _delta
	
	# Check if player is in range
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		var distance_to_camp = global_position.distance_to(camp_position)
		
		# Determine aggro state
		if distance_to_player <= aggro_range:
			is_aggro = true
		elif distance_to_camp > return_home_range:
			is_aggro = false  # Too far from camp, return home
		elif distance_to_player > aggro_range * 1.5:
			is_aggro = false  # Player left range, stop chasing
	
	# Movement logic
	if player == null:
		velocity = Vector2.ZERO  # Stop moving if player is missing
	elif knockback_timer > 0:
		# During knockback from sword hit, slow down naturally (friction)
		velocity = velocity.lerp(Vector2.ZERO, _delta * 5.0)
	elif attack_cooldown > 0:
		# During attack cooldown, slow down the knockback naturally (friction)
		velocity = velocity.lerp(Vector2.ZERO, _delta * 3.0)
	elif is_aggro:
		# Chase player when aggro
		velocity = (player.global_position - global_position).normalized() * speed
	else:
		# Return to camp when not aggro
		var distance_to_camp = global_position.distance_to(camp_position)
		if distance_to_camp > 10.0:  # Only move if far from camp
			velocity = (camp_position - global_position).normalized() * (speed * 0.5)
		else:
			velocity = Vector2.ZERO  # Idle at camp
	
	# Move the slime based on the velocity
	move_and_slide()
	
	# Check if we collided with the player (only if cooldown is done)
	if attack_cooldown <= 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("Player"):
				if collider.has_method("take_damage"):
					collider.call("take_damage", 1)  # Deal 1 damage to player
				
				# Bounce back from player
				var knockback_dir = (global_position - collider.global_position).normalized()
				velocity = knockback_dir * player_hit_knockback
				
				# Start attack cooldown
				attack_cooldown = attack_cooldown_time
				break  # Only process one collision

func _on_hit(damage: int, knockback_direction: Vector2) -> void:
	# Reduce health based on damage received
	health -= damage
	print("Enemy hit! Remaining health: ", health)
	
	# Show damage indicator
	show_damage_text(damage)

	# Apply knockback effect
	velocity = knockback_direction.normalized() * knockback_strength
	knockback_timer = 0.3  # 0.3 seconds of knockback
	
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