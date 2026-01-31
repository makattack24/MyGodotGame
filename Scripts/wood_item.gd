extends Node2D

# Item pickup properties
@export var item_name: String = "wood"
@export var pickup_amount: int = 1

# Reference to the Area2D child node
@onready var pickup_area: Area2D = $Area2D

func _ready() -> void:
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
	# Add item to the inventory singleton
	Inventory.add_item(item_name, pickup_amount)
	print("Picked up ", pickup_amount, " ", item_name)
	
	# Remove the item from the scene
	queue_free()
