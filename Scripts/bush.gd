extends Area2D

# Reference to the sprite
@onready var sprite: Sprite2D = $Sprite2D

# Sway animation variables
var is_swaying: bool = false
var sway_amplitude: float = 10.0  # How much to sway (in degrees) - increased from 5
var sway_speed: float = 15.0  # Speed of the sway animation - increased from 10

# Original rotation
var original_rotation: float = 0.0

func _ready() -> void:
	# Add to Bushes group for identification
	add_to_group("Bushes")
	
	# Store original rotation
	if sprite:
		original_rotation = sprite.rotation_degrees
	
	# Connect area signals to detect player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Make sure monitoring is enabled
	monitoring = true
	monitorable = true
	
	# Set collision layers
	collision_layer = 4  # Layer 3 (binary 100)
	collision_mask = 1   # Detect layer 1 (player)

func _process(delta: float) -> void:
	# Handle swaying animation
	if is_swaying and sprite:
		# Sway back and forth using sine wave
		var time = Time.get_ticks_msec() / 1000.0
		sprite.rotation_degrees = original_rotation + sin(time * sway_speed) * sway_amplitude
	elif sprite:
		# Smoothly return to original rotation when not swaying
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, original_rotation, delta * 5.0)

func _on_body_entered(body: Node2D) -> void:
	# Start swaying when player enters
	if body.is_in_group("Player"):
		is_swaying = true
		print("Bush: Player entered, swaying!")

func _on_body_exited(body: Node2D) -> void:
	# Stop swaying when player exits
	if body.is_in_group("Player"):
		is_swaying = false
		print("Bush: Player exited, stopping sway")

func destroy() -> void:
	"""Called when bush is hit by player's attack"""
	# Create a simple particle effect (fade and shrink)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.2, 0.2), 0.3)
	tween.tween_property(self, "position:y", position.y - 10, 0.3)
	
	# Delete after animation
	await tween.finished
	queue_free()
