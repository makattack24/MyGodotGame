extends Node2D

# NPC spawning settings
@export var npc_scene: PackedScene = preload("res://Scenes/npc.tscn")
@export var max_npcs: int = 3
@export var spawn_radius_min: float = 200.0
@export var spawn_radius_max: float = 400.0
@export var spawn_check_interval: float = 5.0

# NPC types with different items and names
var npc_types = [
	{
		"name": "Merchant Tom",
		"items": {
			"wood": 5,
			"axe": 50,
			"saw_mill": 100
		}
	},
	{
		"name": "Trader Sarah",
		"items": {
			"wood": 3,
			"coin": 1,
			"axe": 45
		}
	},
	{
		"name": "Vendor Mike",
		"items": {
			"saw_mill": 120,
			"wood": 7,
			"axe": 60
		}
	}
]

# Tracking
var spawned_npcs: Array = []
var spawn_timer: float = 0.0
var player_ref: Node2D = null

func _ready() -> void:
	# Find player
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Initial spawn
	spawn_initial_npcs()

func _process(delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
		return
	
	# Clean up dead NPCs from array
	spawned_npcs = spawned_npcs.filter(func(npc): return is_instance_valid(npc))
	
	# Check if we need to spawn more NPCs
	spawn_timer += delta
	if spawn_timer >= spawn_check_interval:
		spawn_timer = 0.0
		check_and_spawn_npcs()

func spawn_initial_npcs() -> void:
	# Wait a frame for player to be ready
	await get_tree().process_frame
	
	if not player_ref:
		return
	
	# Spawn initial NPCs
	for i in range(max_npcs):
		spawn_npc()

func check_and_spawn_npcs() -> void:
	# Spawn NPCs if we're below the maximum
	while spawned_npcs.size() < max_npcs:
		spawn_npc()

func spawn_npc() -> void:
	if not player_ref or not npc_scene:
		return
	
	# Get random spawn position around player
	var spawn_pos = get_random_spawn_position()
	
	# Instance NPC
	var npc = npc_scene.instantiate()
	
	# Set random NPC type
	var npc_type = npc_types[randi() % npc_types.size()]
	npc.npc_name = npc_type["name"]
	npc.shop_items = npc_type["items"]
	
	# Set position
	npc.global_position = spawn_pos
	
	# Add to scene
	get_parent().add_child(npc)
	
	# Track spawned NPC
	spawned_npcs.append(npc)
	
	print("Spawned NPC: ", npc.npc_name, " at position ", spawn_pos)

func get_random_spawn_position() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	
	# Generate random position in a ring around the player
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return player_ref.global_position + offset

func despawn_all_npcs() -> void:
	for npc in spawned_npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	spawned_npcs.clear()
