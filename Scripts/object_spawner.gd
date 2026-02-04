extends Node2D

# ==============================
# CONFIGURATION
# ==============================

@export var world_seed: int = 1337         # Same seed as ground for consistency
@export var spawn_radius: int = 45         # How far around player to spawn objects

# Reference to the ground TileMapLayer
@export var ground_layer: TileMapLayer

# Reference to BiomeManager
var biome_manager: Node = null

# ==============================
# INTERNAL STATE
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()
var spawned_objects: Dictionary = {}  # Track which tiles have objects spawned
var spawned_object_nodes: Array[Node2D] = []  # References to spawned object nodes
var loaded_scenes: Dictionary = {}  # Cache for loaded scenes

# ==============================
# INITIALIZATION
# ==============================

func _ready() -> void:
	# Initialize noise with same seed as ground
	noise.seed = world_seed
	noise.frequency = 0.05
	
	if not ground_layer:
		push_error("ObjectSpawner: ground_layer reference is required!")

# ==============================
# SPAWNING (MAIN ENTRY POINT)
# ==============================

func spawn_objects_around(world_pos: Vector2) -> void:
	if not ground_layer:
		return
	
	# Get biome manager if not already cached (lazy loading)
	if not biome_manager:
		biome_manager = get_parent().get_node_or_null("BiomeManager")
		if biome_manager:
			print("ObjectSpawner: BiomeManager found!")
		else:
			return  # BiomeManager not ready yet, skip this frame
	
	var center_tile: Vector2i = ground_layer.local_to_map(world_pos)
	
	for x in range(center_tile.x - spawn_radius, center_tile.x + spawn_radius):
		for y in range(center_tile.y - spawn_radius, center_tile.y + spawn_radius):
			var tile_pos: Vector2i = Vector2i(x, y)
			
			# Skip if we already spawned something here
			if spawned_objects.has(tile_pos):
				continue
			
			# Check if ground tile exists at this position
			if ground_layer.get_cell_source_id(tile_pos) == -1:
				continue  # No ground tile here, skip
			
			# Try spawning objects for this biome
			_try_spawn_object(tile_pos)
			
			# Mark as processed
			spawned_objects[tile_pos] = true

# ==============================
# OBJECT SPAWNING
# ==============================

func _try_spawn_object(tile_pos: Vector2i) -> void:
	if not biome_manager:
		print("ObjectSpawner: No biome_manager!")
		return
	
	# Get world position
	var world_pos: Vector2 = ground_layer.map_to_local(tile_pos)
	
	# Get objects that can spawn in this biome
	var object_list: Array = biome_manager.get_objects_for_position(world_pos)
	if object_list.is_empty():
		return
	
	# Get minimum spacing
	var min_spacing: float = biome_manager.get_min_object_spacing_for_position(world_pos)
	
	# Choose which object to spawn using weighted random selection
	var chosen_object = _choose_object_to_spawn(object_list, tile_pos)
	if not chosen_object:
		return
	
	# Check if this is a bush and should spawn in clusters
	var scene_path: String = chosen_object.get("scene", "")
	var is_bush: bool = scene_path.contains("bush.tscn")
	
	# Use bush spacing if it's a bush, otherwise use normal spacing
	var spacing_to_use: float = min_spacing
	if is_bush:
		var biome_data = biome_manager.get_biome_data_for_type(biome_manager.get_biome_at_position(world_pos))
		spacing_to_use = biome_data.get("bush_spacing", min_spacing)
	
	# Check spacing
	if not _can_spawn_object_here(world_pos, spacing_to_use):
		return
	
	# Spawn the main object
	_spawn_single_object(chosen_object, world_pos)
	
	# If it's a bush with cluster_size, spawn additional bushes nearby
	if is_bush and chosen_object.has("cluster_size"):
		var cluster_size: int = chosen_object.get("cluster_size", 1)
		_spawn_bush_cluster(chosen_object, world_pos, cluster_size - 1, spacing_to_use)

func _spawn_single_object(object_data: Dictionary, world_pos: Vector2) -> Node2D:
	"""Spawn a single object at the given position"""
	var scene_path: String = object_data.get("scene", "")
	if scene_path.is_empty():
		return null
	
	var object_scene: PackedScene = _load_scene(scene_path)
	if not object_scene:
		return null
	
	var object_instance: Node2D = object_scene.instantiate()
	object_instance.position = world_pos
	
	# Add to the world
	get_parent().add_child(object_instance)
	object_instance.add_to_group("EnvironmentObjects")
	
	# Track the object
	spawned_object_nodes.append(object_instance)
	
	return object_instance

func _spawn_bush_cluster(object_data: Dictionary, center_pos: Vector2, additional_count: int, spacing: float) -> void:
	"""Spawn additional bushes around a center position to create a cluster"""
	var radius_min: float = spacing * 0.8
	var radius_max: float = spacing * 1.5
	
	for i in range(additional_count):
		var attempts: int = 0
		var max_attempts: int = 10
		var spawned: bool = false
		
		while attempts < max_attempts and not spawned:
			# Random angle and radius
			var angle: float = randf() * TAU
			var radius: float = randf_range(radius_min, radius_max)
			
			# Calculate position
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
			var spawn_pos: Vector2 = center_pos + offset
			
			# Check if we can spawn here (with reduced spacing for bushes in cluster)
			if _can_spawn_object_here(spawn_pos, spacing * 0.7):
				_spawn_single_object(object_data, spawn_pos)
				spawned = true
			
			attempts += 1

func _choose_object_to_spawn(object_list: Array, tile_pos: Vector2i) -> Dictionary:
	"""Choose which object to spawn based on spawn chances and weights"""
	# Use noise to determine base spawn probability
	var spawn_noise: float = (noise.get_noise_2d(tile_pos.x + 100, tile_pos.y + 100) + 1.0) * 0.5
	
	# Check each object independently with its own spawn chance
	var valid_objects: Array = []
	var total_weight: float = 0.0
	
	for obj_data in object_list:
		var spawn_chance: float = obj_data.get("spawn_chance", 0.0)
		
		# Check if this specific object should be considered for spawning
		if spawn_noise < spawn_chance:
			valid_objects.append(obj_data)
			total_weight += obj_data.get("weight", 1.0)
	
	# If no objects passed the spawn check, return nothing
	if valid_objects.is_empty():
		return {}
	
	# Weighted random selection from valid objects
	var random_value: float = randf() * total_weight
	var current_weight: float = 0.0
	
	for obj in valid_objects:
		current_weight += obj.get("weight", 1.0)
		if random_value <= current_weight:
			return obj
	
	return valid_objects[0]  # Fallback

func _can_spawn_object_here(world_pos: Vector2, min_spacing: float) -> bool:
	"""Check if we can spawn an object at this position"""
	# Clean up invalid references
	spawned_object_nodes = spawned_object_nodes.filter(is_instance_valid)
	
	# Check spacing from other objects
	for obj in spawned_object_nodes:
		if world_pos.distance_to(obj.position) < min_spacing:
			return false
	
	return true

func _load_scene(scene_path: String) -> PackedScene:
	"""Load a scene from path, with caching"""
	if loaded_scenes.has(scene_path):
		return loaded_scenes[scene_path]
	
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		loaded_scenes[scene_path] = scene
		return scene
	else:
		push_error("ObjectSpawner: Scene not found: " + scene_path)
		return null
