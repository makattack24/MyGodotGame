extends Node2D

# Machine properties
@export var machine_name: String = "saw_mill"
@export var interaction_range: float = 50.0

# State
var is_placed: bool = false
var machine_processing: bool = false

# References
@onready var interaction_area: Area2D = null
@onready var sprite: Sprite2D = $SawMillMachineSprite

func _ready() -> void:
	# Add to persist group for saving/loading
	add_to_group("persist")
	# Add to SawMills group for placement collision detection
	add_to_group("SawMills")
	# Add to PlacedObjects group for general collision detection
	add_to_group("PlacedObjects")
	
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

func _process(_delta: float) -> void:
	if player_nearby and is_placed:
		# E to pickup
		if Input.is_action_just_pressed("pickup"):
			pickup_machine()
		# Enter to interact (use)
		elif Input.is_action_just_pressed("ui_accept"):
			interact()

func interact() -> void:
	print("Interacting with saw mill machine!")
	# Add your saw mill logic here (e.g., convert wood to planks)
	# For now, just a simple message
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Saw Mill Machine activated!", 2.0)

func show_interaction_prompt() -> void:
	# You can add a Label or sprite here to show "Press E to interact"
	print("Press E to pickup | Press Enter to interact with Saw Mill")

func hide_interaction_prompt() -> void:
	pass

func pickup_machine() -> void:
	if not is_placed:
		return
	
	print("Picking up saw mill machine!")
	
	# Show floating text effect
	Inventory.show_pickup_text("saw_mill", 1, global_position)
	
	# Add item back to inventory
	Inventory.add_item("saw_mill", 1)
	
	# Show notification
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Picked up Saw Mill Machine", 1.5)
	
	# Remove from scene
	queue_free()

func place_machine() -> void:
	is_placed = true
	modulate = Color(1, 1, 1, 1.0)  # Full opacity when placed
	print("Saw mill machine placed!")

# Save machine data
func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_placed": is_placed,
		"machine_processing": machine_processing
	}

# Load machine data
func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	is_placed = data.get("is_placed", false)
	machine_processing = data.get("machine_processing", false)
	if is_placed:
		modulate = Color(1, 1, 1, 1.0)
