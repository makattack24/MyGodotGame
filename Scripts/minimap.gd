extends Control

# Minimap settings
@export var map_size: Vector2 = Vector2(150, 150)  # Size of the minimap in pixels
@export var zoom_level: float = 0.1  # How much of the world to show (lower = more zoomed out)
@export var update_interval: float = 0.1  # How often to update the map (in seconds)

# References
var player: Node2D = null
var world_bounds: Rect2 = Rect2(-1000, -1000, 2000, 2000)  # Default world bounds

# UI Elements
@onready var map_panel: Panel = $MapPanel
@onready var map_viewport: SubViewport = $MapPanel/SubViewportContainer/SubViewport
@onready var map_camera: Camera2D = null
@onready var player_marker: ColorRect = $MapPanel/PlayerMarker

# Tracking
var tracked_objects: Array = []  # NPCs, enemies, etc.
var object_markers: Dictionary = {}  # Markers for tracked objects
var update_timer: float = 0.0

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("Player")
	
	# Setup map viewport camera
	setup_map_camera()
	
	# Setup player marker
	if player_marker:
		player_marker.size = Vector2(6, 6)
		player_marker.color = Color.GREEN
		player_marker.position = map_size / 2 - player_marker.size / 2
	
	# Position minimap in top-right corner
	position = Vector2(get_viewport().size.x - map_size.x - 20, 20)
	custom_minimum_size = map_size

func setup_map_camera() -> void:
	# Create a camera in the viewport to track the player
	if map_viewport:
		map_camera = Camera2D.new()
		map_camera.enabled = true
		map_viewport.add_child(map_camera)

func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	# Update camera position to follow player
	if map_camera:
		map_camera.global_position = player.global_position
		map_camera.zoom = Vector2(zoom_level, zoom_level)
	
	# Update tracked objects
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_tracked_objects()

func update_tracked_objects() -> void:
	# Find NPCs, enemies, etc.
	var npcs = get_tree().get_nodes_in_group("NPC")
	var enemies = get_tree().get_nodes_in_group("Enemies")
	
	# Update or create markers for NPCs
	for npc in npcs:
		if not object_markers.has(npc):
			create_marker(npc, Color.BLUE, 4)
		else:
			update_marker(npc, object_markers[npc])
	
	# Update or create markers for enemies
	for enemy in enemies:
		if not object_markers.has(enemy):
			create_marker(enemy, Color.RED, 4)
		else:
			update_marker(enemy, object_markers[enemy])
	
	# Clean up markers for objects that no longer exist
	var to_remove = []
	for obj in object_markers.keys():
		if not is_instance_valid(obj):
			object_markers[obj].queue_free()
			to_remove.append(obj)
	
	for obj in to_remove:
		object_markers.erase(obj)

func create_marker(obj: Node2D, color: Color, marker_size: float) -> void:
	var marker = ColorRect.new()
	marker.size = Vector2(marker_size, marker_size)
	marker.color = color
	map_panel.add_child(marker)
	object_markers[obj] = marker
	update_marker(obj, marker)

func update_marker(obj: Node2D, marker: ColorRect) -> void:
	if not is_instance_valid(obj) or not player:
		return
	
	# Calculate relative position to player
	var relative_pos = obj.global_position - player.global_position
	
	# Scale to map size
	var map_pos = relative_pos * zoom_level
	
	# Center on map and offset from center
	var marker_pos = (map_size / 2) + map_pos - (marker.size / 2)
	
	# Check if within map bounds
	if marker_pos.x < 0 or marker_pos.x > map_size.x or marker_pos.y < 0 or marker_pos.y > map_size.y:
		marker.visible = false
	else:
		marker.visible = true
		marker.position = marker_pos

func set_zoom(new_zoom: float) -> void:
	zoom_level = clamp(new_zoom, 0.05, 0.5)

func toggle_minimap() -> void:
	visible = !visible
