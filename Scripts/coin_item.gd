extends Node2D

# Item pickup properties
@export var item_name: String = "coin"
@export var pickup_amount: int = 1
@export var pickup_sound: AudioStream  # Assign a sound in the Inspector

# Reference to the Area2D child node
@onready var pickup_area: Area2D = $Area2D

# Audio player (will be created if doesn't exist)
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
		print("Error: Area2D child node not found in coin_item!")

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.is_in_group("Player"):
		pickup_item()

func pickup_item() -> void:
	# Show floating text effect
	Inventory.show_pickup_text(item_name, pickup_amount, global_position)
	
	# Add item to the inventory singleton
	Inventory.add_item(item_name, pickup_amount)
	print("Picked up ", pickup_amount, " ", item_name)
	
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
