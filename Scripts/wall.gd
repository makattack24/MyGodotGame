extends StaticBody2D

# Wall properties
@export var item_name: String = "wall"
@export var interaction_range: float = 50.0

# State
var is_placed: bool = false

# References
@onready var interaction_area: Area2D = null

func _ready() -> void:
	# Add to persist group for saving/loading
	add_to_group("persist")
	# Already in PlacedObjects group (set in scene)
	
	# Create interaction area
	setup_interaction_area()
	
	# Start as semi-transparent if not placed
	if not is_placed:
		modulate = Color(1, 1, 1, 0.5)

func setup_interaction_area() -> void:
	interaction_area = Area2D.new()
	add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

var player_nearby: Node2D = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and is_placed:
		player_nearby = body
		show_interaction_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null
		hide_interaction_prompt()

func show_interaction_prompt() -> void:
	print("Press E to pickup wall")

func hide_interaction_prompt() -> void:
	pass

func pickup_machine() -> void:
	if not is_placed:
		return
	
	print("Picking up wall!")
	
	# Show floating text effect
	Inventory.show_pickup_text("wall", 1, global_position)
	
	# Add item back to inventory
	Inventory.add_item("wall", 1)
	
	# Show notification
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Picked up Wall", 1.5)
	
	# Remove from scene
	queue_free()

func place_machine() -> void:
	is_placed = true
	modulate = Color(1, 1, 1, 1.0)  # Full opacity when placed
	print("Wall placed!")

# Save wall data
func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_placed": is_placed
	}

# Load wall data
func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	is_placed = data.get("is_placed", false)
	if is_placed:
		modulate = Color(1, 1, 1, 1.0)
