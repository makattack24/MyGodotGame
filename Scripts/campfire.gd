extends Node2D
# Campfire properties
@export var item_name: String = "campfire"
@export var interaction_range: float = 50.0

# Light properties
@export var light_energy_day: float = 0.6
@export var light_energy_night: float = 2.0
@export var light_radius: float = 120.0

# State
var is_placed: bool = false

# References
@onready var interaction_area: Area2D = null
@onready var sprite: Sprite2D = $Sprite2D
@onready var point_light: PointLight2D = null

func _ready() -> void:
	# Add to persist group for saving/loading
	add_to_group("persist")
	# Add to Campfires group for placement collision detection
	add_to_group("Campfires")
	# Add to PlacedObjects group for general collision detection
	add_to_group("PlacedObjects")
	
	# Create interaction area
	setup_interaction_area()
	
	# Create light effect
	setup_light()
	
	# Start as semi-transparent if not placed
	if not is_placed:
		modulate = Color(1, 1, 1, 0.5)
		if point_light:
			point_light.enabled = false

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

func setup_light() -> void:
	point_light = PointLight2D.new()
	point_light.energy = light_energy_day
	point_light.color = Color(1.0, 0.7, 0.3)  # Warm orange glow
	point_light.texture = _create_light_texture()
	point_light.texture_scale = light_radius / 64.0
	point_light.shadow_enabled = true
	add_child(point_light)

func _create_light_texture() -> GradientTexture2D:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.set_offset(0, 0.0)
	gradient.set_offset(1, 1.0)
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	return tex

var player_nearby: Node2D = null
var day_night_cycle: Node = null

func _process(_delta: float) -> void:
	if not is_placed or not point_light:
		return
	# Dynamically adjust light based on time of day
	if day_night_cycle == null:
		var nodes = get_tree().get_nodes_in_group("DayNightCycle")
		if nodes.size() > 0:
			day_night_cycle = nodes[0]
	if day_night_cycle and "time_of_day" in day_night_cycle:
		var t = day_night_cycle.time_of_day
		# Calculate darkness factor: 1.0 at midnight, 0.0 during day
		var darkness: float
		if t < 0.25:
			# Night to dawn: dark fading out
			darkness = 1.0 - (t / 0.25) * 0.8
		elif t < 0.35:
			# Dawn to day
			darkness = lerp(0.2, 0.0, (t - 0.25) / 0.1)
		elif t < 0.65:
			# Day
			darkness = 0.0
		elif t < 0.75:
			# Day to dusk
			darkness = lerp(0.0, 0.3, (t - 0.65) / 0.1)
		else:
			# Dusk to night
			darkness = lerp(0.3, 1.0, (t - 0.75) / 0.25)
		point_light.energy = lerp(light_energy_day, light_energy_night, darkness)
		# Also slightly expand radius at night
		point_light.texture_scale = (light_radius / 64.0) * (1.0 + darkness * 0.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and is_placed:
		player_nearby = body
		show_interaction_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null
		hide_interaction_prompt()

func show_interaction_prompt() -> void:
	print("Press E to pickup campfire")

func hide_interaction_prompt() -> void:
	pass

func pickup_machine() -> void:
	if not is_placed:
		return
	
	print("Picking up campfire!")
	
	# Show floating text effect
	Inventory.show_pickup_text("campfire", 1, global_position)
	
	# Add item back to inventory
	Inventory.add_item("campfire", 1)
	
	# Show notification
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Picked up Campfire", 1.5)
	
	# Remove from scene
	queue_free()

func place_machine() -> void:
	is_placed = true
	modulate = Color(1, 1, 1, 1.0)  # Full opacity when placed
	if point_light:
		point_light.enabled = true
	print("Campfire placed!")

# Save campfire data
func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_placed": is_placed
	}

# Load campfire data
func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	is_placed = data.get("is_placed", false)
	if is_placed:
		modulate = Color(1, 1, 1, 1.0)
		if point_light:
			point_light.enabled = true