extends CharacterBody2D

# Health and behavior of the slime
@export var health: int = 3                    # Health of the slime
@export var knockback_strength: float = 300.0  # Knockback strength when hit
@export var speed: float = 50.0                # Movement speed of the slime
@export var player_hit_knockback: float = 150.0  # Knockback when hitting player
@export var attack_cooldown_time: float = 1.0  # Time between attacks

# Reference to the player (set this in the Inspector or dynamically during gameplay)
@export var player: CharacterBody2D                     # Target player node to follow

# Attack cooldown tracking
var attack_cooldown: float = 0.0
var knockback_timer: float = 0.0  # Timer for knockback from being hit

# Visual/audio feedback (optional)
@onready var death_effect: CPUParticles2D = $DeathEffect
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _physics_process(_delta: float) -> void:
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= _delta
	
	# Update knockback timer
	if knockback_timer > 0:
		knockback_timer -= _delta
	
	# Only move toward player if not in cooldown/knockback
	if player == null:
		velocity = Vector2.ZERO  # Stop moving if player is missing
	elif knockback_timer > 0:
		# During knockback from sword hit, slow down naturally (friction)
		velocity = velocity.lerp(Vector2.ZERO, _delta * 5.0)
	elif attack_cooldown <= 0:
		# Normal chase behavior when cooldown is done
		velocity = (player.global_position - global_position).normalized() * speed
	else:
		# During attack cooldown, slow down the knockback naturally (friction)
		velocity = velocity.lerp(Vector2.ZERO, _delta * 3.0)
	
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

func die() -> void:
	# Handle death behavior
	print("Enemy died!")
	
	# Play death feedback (animation or effects)
	if death_effect:
		death_effect.emitting = true
	
	# Remove the enemy from the scene
	queue_free()

func set_player_reference(player_ref: Node2D) -> void:
	# Set the player reference for this enemy
	player = player_ref

func _ready() -> void:
	# Add enemy to the Enemies group for player attack detection
	add_to_group("Enemies")
	print("Enemy added to Enemies group!")
	
	# Ensure player reference exists (if assigned dynamically)
	if player == null:
		print("Warning: Player is not assigned to this enemy!")