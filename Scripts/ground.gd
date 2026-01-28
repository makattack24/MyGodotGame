extends TileMapLayer

# ==============================
# CONFIG
# ==============================

@export var tile_radius: int = 45        # how many tiles around player to generate
@export var world_seed: int = 1337       # deterministic seed

const SOURCE_ID: int = 0                 # make sure this matches your atlas source ID

# ALL allowed tiles (atlas coordinates)
const GROUND_TILES: Array[Vector2i] = [
	Vector2i(8, 1),  Vector2i(8, 2),  Vector2i(9, 1),  Vector2i(9, 2),
	Vector2i(10, 1), Vector2i(10, 2), Vector2i(10, 3), Vector2i(10, 4),
	Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4)
]

@export var tree_scene: PackedScene  # Define the Tree scene as an export
@export var tree_spawn_chance: float = 0.5  # 10% chance of a tree spawning

# ==============================
# INTERNAL
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()
var generated: Dictionary = {}  # keeps track of which tiles have already been placed

# Store references to spawned trees to manage them later if needed
var spawned_trees: Array[Node2D] = []

# ==============================
# GODOT LIFECYCLE
# ==============================

func _ready() -> void:
	# Initialize noise for deterministic variation
	noise.seed = world_seed
	noise.frequency = 0.05

# ==============================
# GENERATION
# ==============================

func generate_around(world_pos: Vector2) -> void:
	var center_tile: Vector2i = local_to_map(world_pos)

	for x in range(center_tile.x - tile_radius, center_tile.x + tile_radius):
		for y in range(center_tile.y - tile_radius, center_tile.y + tile_radius):
			var tile_pos: Vector2i = Vector2i(x, y)

			# skip tiles already generated
			if generated.has(tile_pos):
				continue

			_place_tile(tile_pos)
			_try_spawn_tree(tile_pos)  # Try spawning a tree at this tile

			generated[tile_pos] = true

# ==============================
# TILE PLACEMENT
# ==============================

func _place_tile(pos: Vector2i) -> void:
	# pick atlas coordinate deterministically based on tile position
	var atlas_coord: Vector2i = _choose_tile(pos)
	set_cell(
		pos,          # Vector2i tile coords
		SOURCE_ID,    # tileset source ID
		atlas_coord   # atlas coordinates
	)

# ==============================
# TREE SPAWNING LOGIC
# ==============================

func _try_spawn_tree(tile_pos: Vector2i) -> void:
	# Random chance to spawn a tree
	var n: float = (noise.get_noise_2d(tile_pos.x + 100, tile_pos.y + 100) + 1.0) * 0.5  # offset noise
	
	# Add spacing logic: check neighboring tiles for existing trees
	if n < tree_spawn_chance and _can_spawn_tree_here(tile_pos):
		# print("Spawning tree at ", tile_pos)  # Debug spawn success
		var tree_instance: Node2D = tree_scene.instantiate()  # Instantiate a Tree scene
		var world_pos: Vector2 = map_to_local(tile_pos)       # Convert tile position to world coordinates
		tree_instance.position = world_pos                   # Set the Tree's position
		get_parent().add_child(tree_instance)                # Add Tree to the scene
		spawned_trees.append(tree_instance)                  # Keep track of spawned trees
	else:
		pass
		# print("Not spawning tree at ", tile_pos)  # Debug failure to spawn

func _on_tree_removed(tree: Node2D) -> void:
	# Remove a destroyed tree from the tracking array
	if tree in spawned_trees:
		spawned_trees.erase(tree)
		print("Tree removed from spawned_trees:", tree.name)

func _can_spawn_tree_here(tile_pos: Vector2i) -> bool:
	# Check neighboring tiles for trees to ensure spacing
	for offset in [-1, 0, 1]:
		for offset2 in [-1, 0, 1]:
			var neighbor_tile: Vector2i = tile_pos + Vector2i(offset, offset2)
			
			# Validate each tree reference before using it
			spawned_trees = spawned_trees.filter(is_instance_valid)  # Remove invalid references
			for tree in spawned_trees:
				if map_to_local(neighbor_tile).distance_to(tree.position) < 50:  # Adjust minimum distance here
					return false  # Too close to another tree
	return true

# Cleanup invalid references during gameplay
func _cleanup_invalid_references() -> void:
	for tree in spawned_trees:
		if not is_instance_valid(tree):
			spawned_trees.erase(tree)


# ==============================
# TILE SELECTION LOGIC
# ==============================

func _choose_tile(pos: Vector2i) -> Vector2i:
	# deterministic selection using noise + tile coordinates
	var n: float = (noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	var index: int = int(floor(n * GROUND_TILES.size()))
	index = clamp(index, 0, GROUND_TILES.size() - 1)
	return GROUND_TILES[index]




# ==============================
# OPTIONAL: weighted tiles
# ==============================

# Example:
# Uncomment and replace GROUND_TILES in _choose_tile() if you want A tiles more common:
# const WEIGHTED_TILES: Array[Vector2i] = [
# 	GROUND_TILES[0], GROUND_TILES[0], GROUND_TILES[0],  # A common
# 	GROUND_TILES[1], GROUND_TILES[1],                   # B less common
# 	GROUND_TILES[2],                                    # C rare
# 	# ...etc
# ]
# Then return: WEIGHTED_TILES[abs(hash(pos)) % WEIGHTED_TILES.size()]
