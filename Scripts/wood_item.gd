extends Node2D

# Item pickup properties
@export var item_name: String = "wood"
@export var pickup_amount: int = 1

# Reference to the Area2D child node
@onready var pickup_area: Area2D = $Area2D
@onready var audio_player: AudioStreamPlayer2D = null

func _ready() -> void:
	# Get audio player if it exists (check multiple possible names)
	if has_node("WoodPickupSound"):
		audio_player = $WoodPickupSound
	elif has_node("AudioStreamPlayer2D"):
		audio_player = $AudioStreamPlayer2D
	
	# Connect the body_entered signal from the Area2D child
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	else:
		print("Error: Area2D child node not found in wood_item!")

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
	
	# Track stat
	if get_node_or_null("/root/GameStats"):
		GameStats.record_item_collected("wood")

	if audio_player and audio_player.stream:
		print("Playing wood pickup sound...")
		
		# Reparent audio player to scene root so it doesn't get deleted
		var scene_root = get_tree().root
		remove_child(audio_player)
		scene_root.add_child(audio_player)
		audio_player.global_position = global_position
		
		# Hide the sprite so it looks picked up
		if has_node("Sprite2D"):
			$Sprite2D.visible = false
		elif has_node("WoodItemSprite"):
			$WoodItemSprite.visible = false
		
		# Disable collision so it can't be picked up again
		pickup_area.set_deferred("monitoring", false)
		
		# Play sound
		audio_player.play()
		
		# Remove the visual item immediately
		queue_free()
		
		# The audio player will auto-delete after finishing
		await audio_player.finished
		audio_player.queue_free()
	else:
		print("No audio player or stream found!")
		# No sound, just remove immediately
		queue_free()
