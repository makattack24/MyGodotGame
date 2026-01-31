extends TileMapLayer

# ==============================
# CONFIGURATION
# ==============================

@export var tile_radius: int = 45          # Radius of tiles around player to generate
@export var world_seed: int = 1337         # Deterministic seed for noise-based generation

# Atlas source ID for the tileset (make sure this matches your Tileset source ID in the editor)
const SOURCE_ID: int = 0

# Allowed ground tiles (atlas coordinates)
const GROUND_TILES: Array[Vector2i] = [
	Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
	Vector2i(10, 1), Vector2i(10, 2), Vector2i(10, 3), Vector2i(10, 4),
	Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4)
]

@export var tree_scene: PackedScene          # Reference to the tree's scene
@export var tree_spawn_chance: float = 0.5  # Probability of a tree spawning at a tile

# ==============================
# INTERNAL STATE VARIABLES
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()  # Noise generator for deterministic terrain and objects
var generated_tiles: Dictionary = {}           # Keeps track of which tiles have already been generated

# Stores the references to all spawned tree instances
var spawned_trees: Array[Node2D] = []

# ==============================
# GODOT LIFECYCLE
# ==============================

func _ready() -> void:
	# Initialize noise generator for deterministic variation
	noise.seed = world_seed
	noise.frequency = 0.05

# ==============================
# GENERATION (MAIN ENTRY POINT)
# ==============================

func generate_around(world_pos: Vector2) -> void:
	# Main generation loop to handle terrain and trees around player
	var center_tile: Vector2i = local_to_map(world_pos)

	for x in range(center_tile.x - tile_radius, center_tile.x + tile_radius):
		for y in range(center_tile.y - tile_radius, center_tile.y + tile_radius):
			var tile_pos: Vector2i = Vector2i(x, y)

			# Skip tiles that have already been generated
			if generated_tiles.has(tile_pos):
				continue

			_place_tile(tile_pos)
			_try_spawn_tree(tile_pos)  # Try spawning a tree at the tile

			# Mark tile as generated
			generated_tiles[tile_pos] = true

# ==============================
# TILE PLACEMENT LOGIC
# ==============================

func _place_tile(pos: Vector2i) -> void:
	# Pick atlas coordinate deterministically based on tile position
	var atlas_coord: Vector2i = _choose_tile(pos)
	set_cell(
		pos,          # Vector2i tile coordinates
		SOURCE_ID,    # Source ID of tileset
		atlas_coord   # Atlas coordinates for tile selection
	)

# ==============================
# TREE SPAWNING LOGIC
# ==============================

func _try_spawn_tree(tile_pos: Vector2i) -> void:
	# Adds a tree with random noise-based probability
	var n: float = (noise.get_noise_2d(tile_pos.x + 100, tile_pos.y + 100) + 1.0) * 0.5  # Adjusted noise range

	# Ensure the tile is appropriate for spawning a tree
	if n < tree_spawn_chance and _can_spawn_tree_here(tile_pos):
		var tree_instance: Node2D = tree_scene.instantiate()  # Instantiate Tree scene
		var world_pos: Vector2 = map_to_local(tile_pos)       # Convert tile position to world coordinates
		tree_instance.position = world_pos                   # Set tree position correctly
		get_parent().add_child(tree_instance)                # Add Tree to the game world

		# Add tree to the "Trees" group for global recognition
		tree_instance.add_to_group("Trees")                  # Ensure proper interaction via groups

		# Keep track of the tree for management later
		spawned_trees.append(tree_instance)
	else:
		pass  # Skip if tree spawn conditions not met

# ==============================
# TREE REMOVAL / MANAGEMENT
# ==============================

func _on_tree_removed(tree: Node2D) -> void:
	# Removes destroyed tree from tracking
	if tree in spawned_trees:
		spawned_trees.erase(tree)
		print("Tree removed from spawned list:", tree.name)

func _can_spawn_tree_here(tile_pos: Vector2i) -> bool:
	# Checks neighboring tiles to ensure tree spacing
	for offset_x in [-1, 0, 1]:
		for offset_y in [-1, 0, 1]:
			var neighbor_tile: Vector2i = tile_pos + Vector2i(offset_x, offset_y)

			# Validate each tree reference before using it
			spawned_trees = spawned_trees.filter(is_instance_valid)  # Cleanup invalid references
			for tree in spawned_trees:
				if map_to_local(neighbor_tile).distance_to(tree.position) < 50:  # Minimum distance of 50
					return false  # Too close to another tree
	return true

# ==============================
# TILE SELECTION LOGIC
# ==============================

func _choose_tile(pos: Vector2i) -> Vector2i:
	# Determines tile type using noise and tile position
	var n: float = (noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	var index: int = int(floor(n * GROUND_TILES.size()))
	index = clamp(index, 0, GROUND_TILES.size() - 1)
	return GROUND_TILES[index]

# ==============================
# REFERENCE CLEANUP
# ==============================

func _cleanup_invalid_references() -> void:
	# Removes any invalid tree references during gameplay
	for tree in spawned_trees:
		if not is_instance_valid(tree):
			spawned_trees.erase(tree)