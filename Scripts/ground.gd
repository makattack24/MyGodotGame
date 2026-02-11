extends TileMapLayer

# ==============================
# CONFIGURATION
# ==============================

@export var tile_radius: int = 45          # Radius of tiles around player to generate
@export var debug_tile_radius: int = 80    # Larger radius used during debug fly camera
@export var cleanup_radius: int = 60       # Tiles beyond this distance get cleaned up
@export var world_seed: int = 1337         # Deterministic seed for noise-based generation
@export var variation_strength: float = 0.8  # How much variation (0.0 = uniform, 1.0 = max variety)
@export var cluster_size: float = 3.0       # Size of tile clusters (lower = smaller patches)

# Default source ID and tiles (fallback if biome manager not available)
const DEFAULT_SOURCE_ID: int = 0
const GROUND_TILES: Array[Vector2i] = [
	Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
	Vector2i(10, 1), Vector2i(10, 2), Vector2i(10, 3), Vector2i(10, 4),
	Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4)
]

# Reference to BiomeManager
var biome_manager: Node = null

# ==============================
# INTERNAL STATE VARIABLES
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()        # Primary noise for tile selection
var cluster_noise: FastNoiseLite = FastNoiseLite.new() # Secondary noise for clustering
var detail_noise: FastNoiseLite = FastNoiseLite.new()  # Detail noise for micro-variation
var generated_tiles: Dictionary = {}                   # Keeps track of which tiles have already been generated
var biome_cache: Dictionary = {}                       # Cache biome IDs to avoid expensive lookups

# ==============================
# GODOT LIFECYCLE
# ==============================

func _ready() -> void:
	# Initialize noise generators for multi-layered variation
	
	# Primary noise - creates the base tile distribution
	noise.seed = world_seed
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Cluster noise - creates patches/clusters of similar tiles (Don't Starve style!)
	cluster_noise.seed = world_seed + 1000
	cluster_noise.frequency = 0.02 / cluster_size  # Lower frequency = bigger patches
	cluster_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cluster_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	
	# Detail noise - adds fine-grained variation within clusters
	detail_noise.seed = world_seed + 2000
	detail_noise.frequency = 0.15
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

# ==============================
# GENERATION (MAIN ENTRY POINT)
# ==============================

func generate_around(world_pos: Vector2, use_debug_radius: bool = false) -> void:
	# Main generation loop to handle terrain around player
	var radius: int = debug_tile_radius if use_debug_radius else tile_radius
	var center_tile: Vector2i = local_to_map(world_pos)

	for x in range(center_tile.x - radius, center_tile.x + radius):
		for y in range(center_tile.y - radius, center_tile.y + radius):
			var tile_pos: Vector2i = Vector2i(x, y)

			# Skip tiles that have already been generated
			if generated_tiles.has(tile_pos):
				continue

			# Place ground tile
			_place_ground_tile(tile_pos)

			# Mark tile as generated
			generated_tiles[tile_pos] = true

# ==============================
# TILE PLACEMENT LOGIC
# ==============================

func _place_ground_tile(pos: Vector2i) -> void:
	# Pick atlas coordinate and source ID based on biome
	var world_pos = map_to_local(pos)
	var atlas_coord: Vector2i
	var source_id: int = DEFAULT_SOURCE_ID
	
	# Get biome manager if not already cached
	if not biome_manager:
		biome_manager = get_parent().get_node_or_null("BiomeManager")
	
	# Get biome-specific tiles and source ID
	if biome_manager:
		source_id = biome_manager.get_source_id_for_position(world_pos)
		var biome_tiles = biome_manager.get_ground_tiles_for_position(world_pos)
		if not biome_tiles.is_empty():
			atlas_coord = _choose_tile_from_array(pos, biome_tiles)
		else:
			atlas_coord = _choose_tile_from_array(pos, GROUND_TILES)
	else:
		atlas_coord = _choose_tile_from_array(pos, GROUND_TILES)
	
	# Add rotation/flipping for even more variety (Don't Starve style!)
	var flip_h = _should_flip_horizontal(pos)
	var flip_v = _should_flip_vertical(pos)
	var transpose = _should_transpose(pos)
	
	set_cell(
		pos,          # Vector2i tile coordinates
		source_id,    # Source ID from biome (can be different per biome!)
		atlas_coord,  # Atlas coordinates within that source
		TileSetAtlasSource.TRANSFORM_FLIP_H if flip_h else (
			TileSetAtlasSource.TRANSFORM_FLIP_V if flip_v else (
				TileSetAtlasSource.TRANSFORM_TRANSPOSE if transpose else 0
			)
		)
	)

# ==============================
# TILE SELECTION LOGIC
# ==============================

func _choose_tile(pos: Vector2i) -> Vector2i:
	# Get world position for this tile
	var world_pos = map_to_local(pos)
	
	# Get biome manager if not already cached
	if not biome_manager:
		biome_manager = get_parent().get_node_or_null("BiomeManager")
	
	# Get tiles from biome manager
	var available_tiles: Array = GROUND_TILES
	if biome_manager:
		var biome_tiles = biome_manager.get_ground_tiles_for_position(world_pos)
		if not biome_tiles.is_empty():
			available_tiles = biome_tiles
	
	return _choose_tile_from_array(pos, available_tiles)

func _choose_tile_from_array(pos: Vector2i, tiles: Array) -> Vector2i:
	# Multi-layered noise approach for Don't Starve-style variation
	
	# Layer 1: Cluster noise - creates patches of similar tiles
	var cluster_value: float = (cluster_noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	
	# Layer 2: Detail noise - adds variation within clusters
	var detail_value: float = (detail_noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	
	# Layer 3: Primary noise - base randomization
	var primary_value: float = (noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	
	# Combine layers with weights
	# Cluster noise dominates (creates patches), detail adds fine variation
	var combined: float = cluster_value * 0.6 + detail_value * 0.25 + primary_value * 0.15
	
	# Apply variation strength
	combined = lerp(0.5, combined, variation_strength)
	
	# Map to tile index with some bias toward middle tiles for natural look
	var tile_count = tiles.size()
	var index: int
	
	if tile_count > 4:
		# For larger tile sets, create a weighted distribution
		# This makes certain tiles appear more frequently (like in Don't Starve)
		var weighted_value = pow(combined, 1.5)  # Power curve for more common "base" tiles
		index = int(floor(weighted_value * tile_count))
	else:
		# For smaller sets, use linear distribution
		index = int(floor(combined * tile_count))
	
	index = clamp(index, 0, tile_count - 1)
	return tiles[index]

# ==============================
# VARIATION HELPERS
# ==============================

func _should_flip_horizontal(pos: Vector2i) -> bool:
	# Use a different noise offset for flip decisions
	var flip_noise = noise.get_noise_2d(pos.x + 5000, pos.y)
	return flip_noise > 0.3

func _should_flip_vertical(pos: Vector2i) -> bool:
	# Use a different noise offset for flip decisions
	var flip_noise = noise.get_noise_2d(pos.x, pos.y + 5000)
	return flip_noise > 0.3

func _should_transpose(pos: Vector2i) -> bool:
	# Use a different noise offset for transpose decisions
	var transpose_noise = noise.get_noise_2d(pos.x + 10000, pos.y + 10000)
	return transpose_noise > 0.5

# ==============================
# CLEANUP (CALLED PERIODICALLY)
# ==============================

func cleanup_distant_tiles(world_pos: Vector2) -> void:
	"""Remove tiles and cached data far from the player to prevent unbounded growth"""
	var center_tile: Vector2i = local_to_map(world_pos)
	
	# Collect distant generated_tiles keys for removal
	var tiles_to_remove: Array = []
	for tile_pos in generated_tiles:
		if abs(tile_pos.x - center_tile.x) > cleanup_radius or abs(tile_pos.y - center_tile.y) > cleanup_radius:
			tiles_to_remove.append(tile_pos)
	
	# Erase cells and tracking data
	for tile_pos in tiles_to_remove:
		erase_cell(tile_pos)
		generated_tiles.erase(tile_pos)
	
	# Prune biome cache
	var cache_to_remove: Array = []
	for pos in biome_cache:
		if abs(pos.x - center_tile.x) > cleanup_radius or abs(pos.y - center_tile.y) > cleanup_radius:
			cache_to_remove.append(pos)
	for pos in cache_to_remove:
		biome_cache.erase(pos)

