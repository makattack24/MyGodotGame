extends Node2D

# ==============================
# CONFIGURATION
# ==============================

@export var world_seed: int = 1337         # Same seed as ground for consistency
@export var spawn_radius: int = 45         # How far around player to spawn objects

# Tree spawning configuration
@export var tree_scene: PackedScene
@export var tree_spawn_chance: float = 0.5
@export var min_tree_spacing: float = 50.0

# Reference to the ground TileMapLayer
@export var ground_layer: TileMapLayer

# ==============================
# INTERNAL STATE
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()
var spawned_objects: Dictionary = {}  # Track which tiles have objects spawned
var spawned_trees: Array[Node2D] = []  # References to spawned trees

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
			
			# Try spawning objects
			_try_spawn_tree(tile_pos)
			
			# Mark as processed
			spawned_objects[tile_pos] = true

# ==============================
# TREE SPAWNING
# ==============================

func _try_spawn_tree(tile_pos: Vector2i) -> void:
	if not tree_scene:
		return
	
	# Use noise to determine if tree should spawn
	var n: float = (noise.get_noise_2d(tile_pos.x + 100, tile_pos.y + 100) + 1.0) * 0.5
	
	if n < tree_spawn_chance and _can_spawn_tree_here(tile_pos):
		var tree_instance: Node2D = tree_scene.instantiate()
		var world_pos: Vector2 = ground_layer.map_to_local(tile_pos)
		tree_instance.position = world_pos
		
		# Add to the world (parent of this spawner)
		get_parent().add_child(tree_instance)
		tree_instance.add_to_group("Trees")
		
		# Track the tree
		spawned_trees.append(tree_instance)

func _can_spawn_tree_here(tile_pos: Vector2i) -> bool:
	# Clean up invalid references
	spawned_trees = spawned_trees.filter(is_instance_valid)
	
	# Check spacing from other trees
	var world_pos: Vector2 = ground_layer.map_to_local(tile_pos)
	for tree in spawned_trees:
		if world_pos.distance_to(tree.position) < min_tree_spacing:
			return false
	
	return true
