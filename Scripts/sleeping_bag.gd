extends Node2D

## Sleeping Bag - Placeable near campfires. Interact to sleep and advance time.

@export var item_name: String = "sleeping_bag"
@export var interaction_range: float = 50.0
@export var campfire_required_range: float = 80.0  # Must be within this range of a campfire to place

# Sleep settings
@export var sleep_hours: float = 8.0  # How many in-game hours to skip forward
@export var wake_time: float = 0.3    # Wake up at ~7:12 AM (0.3 of day cycle)

# State
var is_placed: bool = false
var player_nearby: Node2D = null
var is_sleeping: bool = false

# References
@onready var sprite: Sprite2D = $Sprite2D
var interaction_area: Area2D = null
var interaction_label: Label = null

func _ready() -> void:
	add_to_group("persist")
	add_to_group("SleepingBags")
	add_to_group("PlacedObjects")
	
	# Create interaction area
	_setup_interaction_area()
	
	# Create floating interaction label
	_setup_interaction_label()
	
	# Start semi-transparent if not placed
	if not is_placed:
		modulate = Color(1, 1, 1, 0.5)

func _setup_interaction_area() -> void:
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	add_child(interaction_area)
	
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	interaction_area.add_child(collision_shape)
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _setup_interaction_label() -> void:
	interaction_label = Label.new()
	interaction_label.name = "InteractionLabel"
	interaction_label.text = "Press Enter to Sleep"
	interaction_label.add_theme_font_size_override("font_size", 10)
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.position = Vector2(-45, -30)
	interaction_label.modulate = Color(1, 1, 0.7, 0.9)
	interaction_label.z_index = 10
	interaction_label.visible = false
	add_child(interaction_label)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and is_placed:
		player_nearby = body
		if interaction_label:
			interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null
		if interaction_label:
			interaction_label.visible = false

func _process(_delta: float) -> void:
	if player_nearby and is_placed and not is_sleeping:
		if Input.is_action_just_pressed("ui_accept"):
			start_sleep()

# ─── Sleep Logic ───

func start_sleep() -> void:
	if is_sleeping:
		return
	
	is_sleeping = true
	
	var hud = get_tree().root.find_child("HUD", true, false)
	
	# Fade to black
	var fade_rect = _create_sleep_overlay()
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.tween_callback(func():
		# Advance time
		_advance_time()
		
		# Show "morning" notification
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Good morning!", 2.0)
	)
	# Hold black briefly
	tween.tween_interval(1.0)
	# Fade back in
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	tween.tween_callback(func():
		fade_rect.queue_free()
		is_sleeping = false
	)

func _advance_time() -> void:
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night and "time_of_day" in day_night:
		var current_time: float = day_night.time_of_day
		var target_time: float = wake_time
		
		# If it's already past the wake time, sleep to the next day's wake time
		if current_time >= target_time - 0.01:
			# This means we cross midnight — the weather system will detect the day increment
			target_time += 1.0
		
		# Set time directly (the day_night_cycle will wrap naturally via fmod)
		day_night.time_of_day = fmod(target_time, 1.0)
		
		# Manually trigger day increment in weather system if we crossed midnight
		var weather_sys = get_tree().get_first_node_in_group("WeatherSystem")
		if weather_sys:
			if current_time > target_time or target_time > 1.0:
				# Crossed midnight
				weather_sys.day_count += 1
				weather_sys.last_day_time = day_night.time_of_day
		
		print("[SleepingBag] Advanced time from %.2f to %.2f" % [current_time, day_night.time_of_day])

func _create_sleep_overlay() -> ColorRect:
	# Create a full-screen black overlay on a high CanvasLayer
	var canvas = CanvasLayer.new()
	canvas.layer = 110  # Above HUD
	get_tree().root.add_child(canvas)
	
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	
	# The rect will clean up the canvas layer too
	rect.tree_exited.connect(func():
		if is_instance_valid(canvas):
			canvas.queue_free()
	)
	
	return rect

# ─── Campfire Proximity Check (used by build system) ───

static func is_near_campfire(pos: Vector2, tree: SceneTree, required_range: float = 80.0) -> bool:
	"""Check if a position is within range of any placed campfire."""
	var campfires = tree.get_nodes_in_group("Campfires")
	for campfire in campfires:
		if is_instance_valid(campfire) and campfire.is_placed:
			if campfire.global_position.distance_to(pos) <= required_range:
				return true
	return false

# ─── Place / Pickup (same pattern as campfire, saw_mill) ───

func place_machine() -> void:
	is_placed = true
	modulate = Color(1, 1, 1, 1.0)
	print("Sleeping bag placed!")

func pickup_machine() -> void:
	if not is_placed:
		return
	
	print("Picking up sleeping bag!")
	Inventory.show_pickup_text("sleeping_bag", 1, global_position)
	Inventory.add_item("sleeping_bag", 1)
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Picked up Sleeping Bag", 1.5)
	
	queue_free()

# ─── Save / Load ───

func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_placed": is_placed
	}

func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	is_placed = data.get("is_placed", false)
	if is_placed:
		modulate = Color(1, 1, 1, 1.0)