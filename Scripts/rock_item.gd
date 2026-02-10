extends Node2D

# Rock item pickup - dropped when mining rocks

@export var item_name: String = "rock"
@export var pickup_amount: int = 1

@onready var pickup_area: Area2D = $Area2D
@onready var audio_player: AudioStreamPlayer2D = null

func _ready() -> void:
	# Get audio player if it exists
	if has_node("PickupSound"):
		audio_player = $PickupSound
	elif has_node("AudioStreamPlayer2D"):
		audio_player = $AudioStreamPlayer2D
	
	# Play drop sound when spawned
	if has_node("DropSound"):
		$DropSound.play()
	
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	else:
		print("Error: Area2D child node not found in rock_item!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		pickup_item()

func pickup_item() -> void:
	Inventory.show_pickup_text(item_name, pickup_amount, global_position)
	Inventory.add_item(item_name, pickup_amount)
	print("Picked up ", pickup_amount, " ", item_name)
	
	if get_node_or_null("/root/GameStats"):
		GameStats.record_item_collected("rock")

	if audio_player and audio_player.stream:
		var scene_root = get_tree().root
		remove_child(audio_player)
		scene_root.add_child(audio_player)
		audio_player.global_position = global_position
		
		# Hide sprite so it looks picked up
		if has_node("Sprite2D"):
			$Sprite2D.visible = false
		
		pickup_area.set_deferred("monitoring", false)
		audio_player.play()
		audio_player.finished.connect(func(): queue_free())
	else:
		queue_free()
