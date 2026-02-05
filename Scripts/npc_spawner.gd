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
# Track which biome has an NPC
var biome_npc_map: Dictionary = {}
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
	# Only try to spawn if there are biomes without an NPC
	var biome_manager = get_tree().get_first_node_in_group("BiomeManager")
	if not biome_manager:
		return


	# Get all biome types from biome_manager safely
	var all_biomes = []
	if "BiomeType" in biome_manager:
		var bt = biome_manager.BiomeType
		for k in bt:
			all_biomes.append(bt[k])
	elif biome_npc_map.size() > 0:
		all_biomes = biome_npc_map.keys()

	var uncovered_biomes = []
	for b in all_biomes:
		if not biome_npc_map.has(b):
			uncovered_biomes.append(b)

	# If all biomes have an NPC, do not attempt to spawn
	if uncovered_biomes.is_empty():
		return

	# Otherwise, try to spawn up to the number of uncovered biomes
	var attempts = min(uncovered_biomes.size(), max_npcs - spawned_npcs.size())
	for i in range(attempts):
		spawn_npc()

func spawn_npc() -> void:
	if not player_ref or not npc_scene:
		return

	var biome_manager = get_tree().get_first_node_in_group("BiomeManager")
	if not biome_manager:
		print("No BiomeManager found for NPC spawning!")
		return

	var max_attempts = 10
	var attempt = 0
	var found = false
	var spawn_pos = Vector2.ZERO
	var biome_type = null

	while attempt < max_attempts and not found:
		spawn_pos = get_random_spawn_position()
		biome_type = biome_manager.get_biome_at_position(spawn_pos)
		# Only spawn if this biome doesn't have an NPC yet
		if not biome_npc_map.has(biome_type):
			# Check distance to all existing NPCs
			var too_close = false
			for npc in spawned_npcs:
				if npc.global_position.distance_to(spawn_pos) < 200:
					too_close = true
					break
			if not too_close:
				found = true
		attempt += 1

	if not found:
		print("Could not find valid biome/position for NPC after ", max_attempts, " attempts.")
		return

	# Instance NPC
	var npc = npc_scene.instantiate()
	var npc_type_data = npc_types[randi() % npc_types.size()]
	npc.npc_name = npc_type_data["name"]
	npc.shop_items = npc_type_data["items"]
	npc.global_position = spawn_pos
	get_parent().add_child(npc)
	spawned_npcs.append(npc)
	biome_npc_map[biome_type] = npc
	print("Spawned NPC: ", npc.npc_name, " at position ", spawn_pos, " in biome ", biome_type)

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
	biome_npc_map.clear()
