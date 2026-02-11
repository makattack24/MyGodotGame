extends Node2D

# Rock item pickup - dropped when mining rocks

@export var item_name: String = "rock"
@export var pickup_amount: int = 1
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var pickup_area: Area2D = $Area2D

func _ready() -> void:
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

	# Disable further pickups and hide the sprite immediately
	pickup_area.set_deferred("monitoring", false)
	if has_node("Sprite2D"):
		$Sprite2D.visible = false

	if pickup_sound and pickup_sound.stream:
		# Reparent the sound so it keeps playing after we free this node
		var pos = global_position
		remove_child(pickup_sound)
		get_tree().root.add_child(pickup_sound)
		pickup_sound.global_position = pos
		pickup_sound.play()
		pickup_sound.finished.connect(pickup_sound.queue_free)
		queue_free()
	else:
		queue_free()
