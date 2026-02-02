extends Control

# Minimap settings
@export var map_size: Vector2 = Vector2(150, 150)
@export var background_color: Color = Color(0, 0, 0, 0.7)
@export var border_color: Color = Color(0.3, 0.3, 0.3, 1)
@export var player_color: Color = Color.GREEN
@export var npc_color: Color = Color.BLUE
@export var enemy_color: Color = Color.RED
@export var zoom_scale: float = 20.0  # Pixels per world unit

# References
var player: Node2D = null

# UI Elements
@onready var background: ColorRect = $Background
@onready var border: Panel = $Border
@onready var player_marker: ColorRect = $PlayerMarker

# Object markers
var npc_markers: Array = []
var enemy_markers: Array = []

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("Player")
	
	# Setup background
	if background:
		background.color = background_color
	
	# Setup player marker
	if player_marker:
		player_marker.size = Vector2(6, 6)
		player_marker.color = player_color
		# Center the player marker
		player_marker.position = (map_size / 2) - (player_marker.size / 2)
	
	# Position minimap in top-right corner using anchors
	update_minimap_position()
	
	# Make sure it's visible
	visible = true
	modulate = Color(1, 1, 1, 1)
	
	print("Minimap initialized with size: ", size)
	
	# Connect to viewport resize
	get_viewport().size_changed.connect(update_minimap_position)

func _input(event: InputEvent) -> void:
	# Toggle minimap with M key
	if event is InputEventKey and event.keycode == KEY_M and event.pressed and not event.echo:
		toggle_minimap()

func update_minimap_position() -> void:
	# Use anchors for top-right positioning
	anchor_left = 1.0  # Right side
	anchor_top = 0.0   # Top
	anchor_right = 1.0
	anchor_bottom = 0.0
	
	# Offset from the anchors
	offset_left = -map_size.x - 20  # 20 pixels from right edge
	offset_top = 20                  # 20 pixels from top
	offset_right = -20
	offset_bottom = map_size.y + 20
	
	print("Minimap anchored to top-right")

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		return
	
	# Update markers for NPCs and enemies
	update_object_markers()

func update_object_markers() -> void:
	# Clear old markers
	for marker in npc_markers + enemy_markers:
		marker.queue_free()
	npc_markers.clear()
	enemy_markers.clear()
	
	if not player:
		return
	
	# Get NPCs
	var npcs = get_tree().get_nodes_in_group("NPC")
	for npc in npcs:
		if is_instance_valid(npc):
			var marker = create_object_marker(npc, npc_color, 4)
			if marker:
				npc_markers.append(marker)
	
	# Get enemies
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var marker = create_object_marker(enemy, enemy_color, 4)
			if marker:
				enemy_markers.append(marker)

func create_object_marker(obj: Node2D, color: Color, marker_size: float) -> ColorRect:
	if not is_instance_valid(obj) or not player:
		return null
	
	# Calculate relative position to player
	var relative_pos = obj.global_position - player.global_position
	
	# Scale to map size
	var map_pos = relative_pos / zoom_scale
	
	# Center on map
	var marker_pos = (map_size / 2) + map_pos
	
	# Check if within map bounds
	if marker_pos.x < 0 or marker_pos.x > map_size.x or marker_pos.y < 0 or marker_pos.y > map_size.y:
		return null
	
	# Create marker
	var marker = ColorRect.new()
	marker.size = Vector2(marker_size, marker_size)
	marker.color = color
	marker.position = marker_pos - (marker.size / 2)
	add_child(marker)
	
	return marker

func toggle_minimap() -> void:
	visible = !visible

func set_zoom(new_zoom: float) -> void:
	zoom_scale = clamp(new_zoom, 5.0, 50.0)
