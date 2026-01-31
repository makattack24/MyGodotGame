extends CharacterBody2D

# Health and behavior of the slime
@export var health: int = 3                    # Health of the slime
@export var knockback_strength: float = 300.0  # Knockback strength when hit
@export var speed: float = 50.0                # Movement speed of the slime

# Reference to the player (set this in the Inspector or dynamically during gameplay)
@export var player: CharacterBody2D                     # Target player node to follow

# Visual/audio feedback (optional)
@onready var death_effect: CPUParticles2D = $DeathEffect
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _physics_process(_delta: float) -> void:
	# Move toward the player
	if player == null:
		velocity = Vector2.ZERO  # Stop moving if player is missing
	else:
		velocity = (player.global_position - global_position).normalized() * speed
	
	# Move the slime based on the velocity
	move_and_slide()

func _on_hit(damage: int, knockback_direction: Vector2) -> void:
	# Reduce health based on damage received
	health -= damage
	print("Enemy hit! Remaining health: ", health)

	# Apply knockback effect
	velocity = knockback_direction.normalized() * knockback_strength
	
	# Trigger hit visual/audio effects
	play_hit_feedback()

	# Check if the enemy is dead
	if health <= 0:
		die()  # Handle death behavior

func play_hit_feedback() -> void:
	# Play feedback effects when hit (optional)
	if hit_sound:
		hit_sound.play()

	# Emit particles for visual feedback
	if death_effect:
		death_effect.emitting = true

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
	
	# Ensure player reference exists (if assigned dynamically)
	if player == null:
		print("Warning: Player is not assigned to this enemy!")