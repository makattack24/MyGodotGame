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
	
	# Check spacing
	if not _can_spawn_object_here(world_pos, min_spacing):
		return
	
	# Choose which object to spawn using weighted random selection
	var chosen_object = _choose_object_to_spawn(object_list, tile_pos)
	if not chosen_object:
		return
	
	# Load and instantiate the scene
	var scene_path: String = chosen_object.get("scene", "")
	if scene_path.is_empty():
		return
	
	var object_scene: PackedScene = _load_scene(scene_path)
	if not object_scene:
		return
	
	var object_instance: Node2D = object_scene.instantiate()
	object_instance.position = world_pos
	
	# Add to the world
	get_parent().add_child(object_instance)
	object_instance.add_to_group("EnvironmentObjects")
	print("ObjectSpawner: Spawned ", scene_path, " at ", world_pos)
	
	# Track the object
	spawned_object_nodes.append(object_instance)

func _choose_object_to_spawn(object_list: Array, tile_pos: Vector2i) -> Dictionary:
	"""Choose which object to spawn based on spawn chances and weights"""
	# Use noise to determine if we should spawn anything
	var spawn_noise: float = (noise.get_noise_2d(tile_pos.x + 100, tile_pos.y + 100) + 1.0) * 0.5
	
	# Check each object type to see if it should spawn
	for obj_data in object_list:
		var spawn_chance: float = obj_data.get("spawn_chance", 0.0)
		if spawn_noise < spawn_chance:
			# This object passes the spawn chance check
			# Now use weighted random to select between multiple objects
			var total_weight: float = 0.0
			var valid_objects: Array = []
			
			# Collect all objects that would spawn at this noise value
			for obj in object_list:
				if spawn_noise < obj.get("spawn_chance", 0.0):
					valid_objects.append(obj)
					total_weight += obj.get("weight", 1.0)
			
			if valid_objects.is_empty():
				return {}
			
			# Weighted random selection
			var random_value: float = randf() * total_weight
			var current_weight: float = 0.0
			
			for obj in valid_objects:
				current_weight += obj.get("weight", 1.0)
				if random_value <= current_weight:
					return obj
			
			return valid_objects[0]  # Fallback
	
	return {}  # Nothing spawns

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
