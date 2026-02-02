extends Node2D

# Healing properties
@export var heal_amount: int = 1  # Amount to heal player
@export var pickup_sound: AudioStream  # Assign a sound in the Inspector

# Reference to the Area2D child node
@onready var pickup_area: Area2D = $Area2D

# Audio player
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	# Create or get audio player
	if has_node("AudioStreamPlayer2D"):
		audio_player = $AudioStreamPlayer2D
	else:
		audio_player = AudioStreamPlayer2D.new()
		add_child(audio_player)
	
	# Set the pickup sound if assigned
	if pickup_sound:
		audio_player.stream = pickup_sound
	
	# Connect the body_entered signal from the Area2D child
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	else:
		print("Error: Area2D child node not found in heart_item!")

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.is_in_group("Player"):
		pickup_item(body)

func pickup_item(player: Node2D) -> void:
	# Heal the player
	if player.has_method("heal"):
		player.heal(heal_amount)
		print("Player healed for ", heal_amount, " health")
	
	# Show floating text effect
	show_heal_text()
	
	# Play pickup sound if available
	if audio_player and audio_player.stream:
		# Hide the sprite so it looks picked up
		$Sprite2D.visible = false
		
		# Disable collision so it can't be picked up again
		pickup_area.set_deferred("monitoring", false)
		
		# Play sound
		audio_player.play()
		
		# Wait for sound to finish, then remove
		await audio_player.finished
		queue_free()
	else:
		# No sound, remove immediately
		queue_free()

func show_heal_text() -> void:
	"""Creates a floating heal text effect"""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	# Create a label for the floating heal text
	var heal_label = Label.new()
	heal_label.text = "+%d" % heal_amount
	heal_label.add_theme_font_size_override("font_size", 16)
	heal_label.modulate = Color(0.2, 0.8, 0.2)  # Green color for healing
	heal_label.z_index = 100  # Draw on top
	
	# Position above the item
	heal_label.position = global_position + Vector2(-15, -40)
	
	# Add to scene root
	tree.root.add_child(heal_label)
	
	# Animate the label (float up and fade out)
	var tween = heal_label.create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	tween.tween_property(heal_label, "position:y", heal_label.position.y - 50, 1.0)
	tween.tween_property(heal_label, "modulate:a", 0.0, 1.0)
	
	# Delete after animation
	tween.finished.connect(func(): heal_label.queue_free())
