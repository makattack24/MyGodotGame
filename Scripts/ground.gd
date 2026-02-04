extends TileMapLayer

# ==============================
# CONFIGURATION
# ==============================

@export var tile_radius: int = 45          # Radius of tiles around player to generate
@export var world_seed: int = 1337         # Deterministic seed for noise-based generation
@export var variation_strength: float = 0.8  # How much variation (0.0 = uniform, 1.0 = max variety)
@export var cluster_size: float = 3.0       # Size of tile clusters (lower = smaller patches)

# Chasm/Hole Configuration
@export_group("Chasms & Terrain Breaks")
@export var enable_chasms: bool = true      # Enable chasm generation
@export var chasm_spawn_chance: float = 0.3    # 0.0 to 1.0 - Chance of chasm spawning at border (higher = more chasms)
@export var chasm_width_scale: float = 2.0         # How wide/thick chasm formations are (higher = thicker)
@export var minimum_chasm_cluster_size: int = 5   # Minimum connected tiles to keep a chasm
@export var maximum_chasm_cluster_size: int = 60  # Maximum connected tiles allowed (prevents giant chasms)
@export var chasm_separation_distance: float = 0.0  # Minimum distance between separate chasm formations
@export var spawn_protection_radius: float = 50.0  # No chasms within this distance of player spawn
@export var spawn_at_biome_borders: bool = true  # Spawn chasms at biome transition areas (set true for borders only)
@export var border_check_distance: int = 4  # How far to check for biome borders (max width in tiles)
@export var enable_collision: bool = true   # Make chasms block player movement

# Default source ID and tiles (fallback if biome manager not available)
const DEFAULT_SOURCE_ID: int = 0
const GROUND_TILES: Array[Vector2i] = [
	Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
	Vector2i(10, 1), Vector2i(10, 2), Vector2i(10, 3), Vector2i(10, 4),
	Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 3), Vector2i(11, 4)
]

# Chasm/hole tiles (dark/void tiles from tileset)
const CHASM_TILES: Array[Vector2i] = [
	Vector2i(17, 2), Vector2i(19, 3)
]

# Reference to BiomeManager
var biome_manager: Node = null

# ==============================
# INTERNAL STATE VARIABLES
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()        # Primary noise for tile selection
var cluster_noise: FastNoiseLite = FastNoiseLite.new() # Secondary noise for clustering
var detail_noise: FastNoiseLite = FastNoiseLite.new()  # Detail noise for micro-variation
var chasm_noise: FastNoiseLite = FastNoiseLite.new()   # Noise for chasm/hole placement
var generated_tiles: Dictionary = {}                   # Keeps track of which tiles have already been generated
var pending_chasm_tiles: Dictionary = {}               # Temporary storage for chasm tiles before validation
var chasm_centers: Array = []                          # Track chasm center positions for spacing
var confirmed_chasm_tiles: Dictionary = {}             # Track all validated chasm tile positions
var chasm_blacklist: Dictionary = {}                   # Tiles that failed validation and should never be chasms
var player_spawn_position: Vector2 = Vector2.ZERO      # Track player spawn to avoid chasms near start
var spawn_position_set: bool = false                   # Flag to track if spawn position has been set
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
	
	# Chasm noise - creates brush-stroke formations along biome borders
	chasm_noise.seed = world_seed + 3000
	chasm_noise.frequency = 0.04 / chasm_width_scale  # Balanced frequency for medium-sized formations
	chasm_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	chasm_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	chasm_noise.fractal_octaves = 2  # Simple formations

# ==============================
# PUBLIC METHODS
# ==============================

func set_spawn_position(spawn_pos: Vector2) -> void:
	"""Set the player spawn position to avoid chasms near start"""
	player_spawn_position = spawn_pos
	spawn_position_set = true

# ==============================
# GENERATION (MAIN ENTRY POINT)
# ==============================

func generate_around(world_pos: Vector2) -> void:
	# Main generation loop to handle terrain around player
	
	# Auto-detect spawn position on first generation
	if not spawn_position_set and generated_tiles.is_empty():
		player_spawn_position = world_pos
		spawn_position_set = true
	
	var center_tile: Vector2i = local_to_map(world_pos)
	var new_tiles: Array = []

	# PASS 1: Generate all ground tiles and track new ones
	for x in range(center_tile.x - tile_radius, center_tile.x + tile_radius):
		for y in range(center_tile.y - tile_radius, center_tile.y + tile_radius):
			var tile_pos: Vector2i = Vector2i(x, y)

			# CRITICAL: Skip confirmed chasms first - never touch these
			if confirmed_chasm_tiles.has(tile_pos):
				continue
			
			# Skip tiles that have already been generated
			if generated_tiles.has(tile_pos):
				continue

			# Track as new tile
			new_tiles.append(tile_pos)
			
			# Check if should be chasm FIRST
			if enable_chasms and _should_be_chasm(tile_pos):
				_place_chasm(tile_pos)
				pending_chasm_tiles[tile_pos] = true
			else:
				# Place ground tile
				_place_ground_tile(tile_pos)

			# Mark tile as generated
			generated_tiles[tile_pos] = true
	
	# PASS 2: Validate chasms (only if we have new tiles)
	if enable_chasms and minimum_chasm_cluster_size > 1 and new_tiles.size() > 0:
		_validate_chasm_sizes()

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
# CHASM GENERATION
# ==============================

func _should_be_chasm(pos: Vector2i) -> bool:
	var world_pos = map_to_local(pos)
	
	# CRITICAL: Never spawn chasms on blacklisted tiles
	if chasm_blacklist.has(pos):
		return false
	
	# CRITICAL: Don't spawn chasms near player spawn point
	if spawn_position_set:
		var distance_to_spawn = world_pos.distance_to(player_spawn_position)
		if distance_to_spawn < spawn_protection_radius:
			return false
	
	# Check if we should only spawn at biome borders
	if spawn_at_biome_borders:
		if not _is_near_biome_border(pos):
			return false
	
	# Use Perlin noise for predictable formations
	var chasm_value = chasm_noise.get_noise_2d(pos.x, pos.y)
	
	# Perlin returns [-1, 1], normalize to [0, 1]
	var normalized = (chasm_value + 1.0) * 0.5
	
	# Use threshold - values above this become chasms
	return normalized > (1.0 - chasm_spawn_chance)

func _is_far_enough_from_other_chasms(pos: Vector2i) -> bool:
	# Only check distance to chasm centers for thick brush stroke effect
	var world_pos = map_to_local(pos)
	
	# Check against validated chasm centers only
	for center_pos in chasm_centers:
		var distance = world_pos.distance_to(center_pos)
		if distance < chasm_separation_distance:
			return false
	
	return true

func _is_near_biome_border(pos: Vector2i) -> bool:
	# Optimized border check - only samples key directions instead of all tiles
	if not biome_manager:
		return true  # If no biome manager, allow chasms anywhere
	
	var world_pos = map_to_local(pos)
	
	# Get cached biome or calculate and cache it
	var current_biome: int
	if biome_cache.has(pos):
		current_biome = biome_cache[pos]
	else:
		current_biome = biome_manager.get_source_id_for_position(world_pos)
		biome_cache[pos] = current_biome
	
	# Only check in the 4 cardinal directions at increasing distances
	# This is much faster than checking all tiles in a radius
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for dir in directions:
		for dist in range(1, border_check_distance + 1):
			var check_pos = pos + (dir * dist)
			var check_world_pos = map_to_local(check_pos)
			
			# Get cached biome or calculate
			var neighbor_biome: int
			if biome_cache.has(check_pos):
				neighbor_biome = biome_cache[check_pos]
			else:
				neighbor_biome = biome_manager.get_source_id_for_position(check_world_pos)
				biome_cache[check_pos] = neighbor_biome
			
			if neighbor_biome != current_biome:
				# Found a border within range
				return true
	
	return false

func _place_chasm(pos: Vector2i) -> void:
	# Place a chasm/hole tile with random variation
	# Use noise for deterministic tile selection
	var tile_noise = abs(noise.get_noise_2d(pos.x + 8888, pos.y + 8888))
	var tile_index = int(tile_noise * CHASM_TILES.size()) % CHASM_TILES.size()
	var chasm_tile = CHASM_TILES[tile_index]
	
	# Use noise for deterministic rotation
	var rotation_noise = abs(detail_noise.get_noise_2d(pos.x + 9999, pos.y + 9999))
	var tile_rotation = int(rotation_noise * 4.0) % 4
	var transform_flag = 0
	match tile_rotation:
		1: transform_flag = TileSetAtlasSource.TRANSFORM_FLIP_H
		2: transform_flag = TileSetAtlasSource.TRANSFORM_FLIP_V
		3: transform_flag = TileSetAtlasSource.TRANSFORM_TRANSPOSE
	
	set_cell(pos, DEFAULT_SOURCE_ID, chasm_tile, transform_flag)
	
	# Track this as a pending chasm tile for validation
	pending_chasm_tiles[pos] = true
	
	# Set collision if enabled to block player movement
	if enable_collision:
		var tile_data = get_cell_tile_data(pos)
		if tile_data:
			# Note: Collision layers should be configured in the TileSet editor
			# This just ensures the tile is placed - actual collision is TileSet-based
			pass

# ==============================
# CHASM VALIDATION
# ==============================

func _validate_chasm_sizes() -> void:
	# Find all chasm clusters and remove those below minimum size OR above maximum size
	var visited: Dictionary = {}
	var clusters_to_remove: Array = []
	var valid_clusters: Array = []
	
	for chasm_pos in pending_chasm_tiles.keys():
		if visited.has(chasm_pos):
			continue
		
		# Flood fill to find cluster size
		var cluster = _flood_fill_chasm(chasm_pos, visited)
		
		# If cluster is too small OR too large, mark for removal
		if cluster.size() < minimum_chasm_cluster_size or cluster.size() > maximum_chasm_cluster_size:
			clusters_to_remove.append(cluster)
		else:
			valid_clusters.append(cluster)
	
	# Remove small clusters and replace with ground tiles
	for cluster in clusters_to_remove:
		for pos in cluster:
			# Replace with proper ground tile
			_place_ground_tile(pos)
			pending_chasm_tiles.erase(pos)
			# CRITICAL: Mark as generated to prevent re-evaluation as chasm
			generated_tiles[pos] = true
			# CRITICAL: Add to blacklist so this position NEVER becomes a chasm
			chasm_blacklist[pos] = true
	
	# Register valid chasm centers for spacing
	for cluster in valid_clusters:
		if cluster.size() > 0:
			# Calculate center of cluster
			var center_sum = Vector2.ZERO
			for pos in cluster:
				center_sum += map_to_local(pos)
				# Add to confirmed chasms
				confirmed_chasm_tiles[pos] = true
				# CRITICAL: Mark as generated so they're never touched again
				generated_tiles[pos] = true
			var center = center_sum / cluster.size()
			chasm_centers.append(center)
	
	# Clear pending chasms
	pending_chasm_tiles.clear()

# ==============================
# PUBLIC QUERY METHODS
# ==============================

func is_position_in_chasm(world_pos: Vector2) -> bool:
	"""Check if a world position is inside a chasm"""
	var tile_pos = local_to_map(world_pos)
	# Check both confirmed chasms AND pending chasms (before validation)
	return confirmed_chasm_tiles.has(tile_pos) or pending_chasm_tiles.has(tile_pos)

func _flood_fill_chasm(start_pos: Vector2i, visited: Dictionary) -> Array:
	# Flood fill to find all connected chasm tiles
	var cluster: Array = []
	var queue: Array = [start_pos]
	
	while queue.size() > 0:
		var pos = queue.pop_front()
		
		if visited.has(pos):
			continue
		
		if not pending_chasm_tiles.has(pos):
			continue
		
		visited[pos] = true
		cluster.append(pos)
		
		# Check all 8 neighbors (including diagonals) for oval-shaped connectivity
		# Prioritize cardinal directions for better oval shapes
		queue.append(Vector2i(pos.x + 1, pos.y))
		queue.append(Vector2i(pos.x - 1, pos.y))
		queue.append(Vector2i(pos.x, pos.y + 1))
		queue.append(Vector2i(pos.x, pos.y - 1))
		queue.append(Vector2i(pos.x + 1, pos.y + 1))
		queue.append(Vector2i(pos.x - 1, pos.y - 1))
		queue.append(Vector2i(pos.x + 1, pos.y - 1))
		queue.append(Vector2i(pos.x - 1, pos.y + 1))
	
	return cluster

func _replace_chasm_with_ground(pos: Vector2i) -> void:
	# Replace chasm tile with appropriate ground tile
	var world_pos = map_to_local(pos)
	var atlas_coord: Vector2i
	var source_id: int = DEFAULT_SOURCE_ID
	
	# Get appropriate ground tile for this position
	if biome_manager:
		source_id = biome_manager.get_source_id_for_position(world_pos)
		var biome_tiles = biome_manager.get_ground_tiles_for_position(world_pos)
		if not biome_tiles.is_empty():
			atlas_coord = _choose_tile_from_array(pos, biome_tiles)
		else:
			atlas_coord = _choose_tile_from_array(pos, GROUND_TILES)
	else:
		atlas_coord = _choose_tile_from_array(pos, GROUND_TILES)
	
	# Replace with ground tile
	set_cell(pos, source_id, atlas_coord, 0)
	
	# CRITICAL: Mark as generated so it won't be touched again
	generated_tiles[pos] = true

