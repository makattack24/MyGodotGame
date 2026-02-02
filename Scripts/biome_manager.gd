extends Node

# ==============================
# BIOME CONFIGURATION
# ==============================

# Define biome types with their properties
enum BiomeType {
	STARTER,    # Safe starting area
	FOREST,     # Light forest biome
	DENSE_FOREST, # Thicker forest
	SWAMP,      # Swamp biome
	TAIGA,      # Pine forest/snow transition
	DESERT,     # Sandy desert
	TUNDRA,     # Cold/snowy area
	CAVE        # Dark/rocky area
}

# Biome definitions with properties
var biome_data: Dictionary = {
	BiomeType.STARTER: {
		"name": "Starter Plains",
		"ground_tiles": [  # Grass tiles
			Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
			Vector2i(10, 1), Vector2i(10, 2), Vector2i(11, 1), Vector2i(11, 2)
		],
		"tree_spawn_chance": 0.3,
		"min_tree_spacing": 60.0,
		"enemy_spawn_chance": 0.1,
		"enemies_per_camp": 2,
		"color_tint": Color(1.0, 1.0, 1.0, 1.0)
	},
	BiomeType.FOREST: {
		"name": "Forest",
		"ground_tiles": [
			Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(10, 2),
			Vector2i(11, 1), Vector2i(11, 2)
		],
		"tree_spawn_chance": 0.6,
		"min_tree_spacing": 45.0,
		"enemy_spawn_chance": 0.3,
		"enemies_per_camp": 3,
		"color_tint": Color(0.9, 1.0, 0.9, 1.0)  # Slight green tint
	},
	BiomeType.DENSE_FOREST: {
		"name": "Dense Forest",
		"ground_tiles": [
			Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1)
		],
		"tree_spawn_chance": 0.8,
		"min_tree_spacing": 35.0,
		"enemy_spawn_chance": 0.4,
		"enemies_per_camp": 4,
		"color_tint": Color(0.8, 1.0, 0.8, 1.0)
	},
	BiomeType.SWAMP: {
		"name": "Swamp",
		"ground_tiles": [
			Vector2i(10, 3), Vector2i(10, 4), Vector2i(11, 3), Vector2i(11, 4)
		],
		"tree_spawn_chance": 0.4,
		"min_tree_spacing": 50.0,
		"enemy_spawn_chance": 0.5,
		"enemies_per_camp": 4,
		"color_tint": Color(0.8, 0.9, 0.7, 1.0)  # Murky green
	},
	BiomeType.TAIGA: {
		"name": "Taiga",
		"ground_tiles": [
			Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2)
		],
		"tree_spawn_chance": 0.5,
		"min_tree_spacing": 55.0,
		"enemy_spawn_chance": 0.3,
		"enemies_per_camp": 3,
		"color_tint": Color(0.9, 0.95, 1.0, 1.0)  # Cool tint
	},
	BiomeType.DESERT: {
		"name": "Desert",
		"ground_tiles": [
			Vector2i(10, 3), Vector2i(10, 4), Vector2i(11, 3), Vector2i(11, 4)
		],
		"tree_spawn_chance": 0.1,
		"min_tree_spacing": 80.0,
		"enemy_spawn_chance": 0.4,
		"enemies_per_camp": 3,
		"color_tint": Color(1.0, 0.95, 0.8, 1.0)  # Sandy yellow
	},
	BiomeType.TUNDRA: {
		"name": "Tundra",
		"ground_tiles": [
			Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2)
		],
		"tree_spawn_chance": 0.2,
		"min_tree_spacing": 70.0,
		"enemy_spawn_chance": 0.6,
		"enemies_per_camp": 5,
		"color_tint": Color(0.9, 0.9, 1.0, 1.0)  # Cold blue tint
	},
	BiomeType.CAVE: {
		"name": "Cave Entrance",
		"ground_tiles": [
			Vector2i(10, 4), Vector2i(11, 4)
		],
		"tree_spawn_chance": 0.05,
		"min_tree_spacing": 100.0,
		"enemy_spawn_chance": 0.7,
		"enemies_per_camp": 6,
		"color_tint": Color(0.7, 0.7, 0.8, 1.0)  # Dark tint
	}
}

# ==============================
# BIOME DISTRIBUTION
# ==============================

# Distance-based biome rings (distance from spawn point)
var biome_rings: Array[Dictionary] = [
	{"min_distance": 0,    "max_distance": 300,  "biomes": [BiomeType.STARTER]},
	{"min_distance": 300,  "max_distance": 600,  "biomes": [BiomeType.FOREST, BiomeType.STARTER]},
	{"min_distance": 600,  "max_distance": 1000, "biomes": [BiomeType.FOREST, BiomeType.DENSE_FOREST, BiomeType.TAIGA]},
	{"min_distance": 1000, "max_distance": 1500, "biomes": [BiomeType.DENSE_FOREST, BiomeType.SWAMP, BiomeType.TAIGA, BiomeType.DESERT]},
	{"min_distance": 1500, "max_distance": 2500, "biomes": [BiomeType.SWAMP, BiomeType.DESERT, BiomeType.TUNDRA, BiomeType.CAVE]},
	{"min_distance": 2500, "max_distance": 99999, "biomes": [BiomeType.CAVE, BiomeType.TUNDRA, BiomeType.DESERT]}
]

# ==============================
# NOISE GENERATORS
# ==============================

var biome_noise: FastNoiseLite = FastNoiseLite.new()
var variation_noise: FastNoiseLite = FastNoiseLite.new()
var spawn_point: Vector2 = Vector2.ZERO

# ==============================
# INITIALIZATION
# ==============================

func _ready() -> void:
	# Initialize biome noise for smooth transitions
	biome_noise.seed = 1337
	biome_noise.frequency = 0.01  # Very low frequency for large biome areas
	biome_noise.fractal_octaves = 3
	
	# Variation noise for mixing biomes
	variation_noise.seed = 7331
	variation_noise.frequency = 0.03

func set_spawn_point(pos: Vector2) -> void:
	spawn_point = pos

# ==============================
# BIOME DETERMINATION
# ==============================

func get_biome_at_position(world_pos: Vector2) -> BiomeType:
	"""Get the biome type for a given world position"""
	var distance_from_spawn = world_pos.distance_to(spawn_point)
	
	# Find which ring we're in
	var available_biomes: Array = []
	for ring in biome_rings:
		if distance_from_spawn >= ring.min_distance and distance_from_spawn < ring.max_distance:
			available_biomes = ring.biomes
			break
	
	# If no ring found (shouldn't happen), default to last ring
	if available_biomes.is_empty():
		available_biomes = biome_rings[-1].biomes
	
	# If only one biome in this ring, return it
	if available_biomes.size() == 1:
		return available_biomes[0]
	
	# Use noise to select between multiple biomes
	var noise_value = biome_noise.get_noise_2d(world_pos.x, world_pos.y)
	var normalized = (noise_value + 1.0) * 0.5  # Convert from [-1, 1] to [0, 1]
	
	var index = int(floor(normalized * available_biomes.size()))
	index = clamp(index, 0, available_biomes.size() - 1)
	
	return available_biomes[index]

func get_biome_data_for_type(biome_type: BiomeType) -> Dictionary:
	"""Get the configuration data for a specific biome type"""
	return biome_data.get(biome_type, biome_data[BiomeType.STARTER])

func get_ground_tiles_for_position(world_pos: Vector2) -> Array:
	"""Get the appropriate ground tiles for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("ground_tiles", [])

func get_tree_spawn_chance_for_position(world_pos: Vector2) -> float:
	"""Get tree spawn chance for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("tree_spawn_chance", 0.3)

func get_min_tree_spacing_for_position(world_pos: Vector2) -> float:
	"""Get minimum tree spacing for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("min_tree_spacing", 50.0)

func get_enemy_spawn_chance_for_position(world_pos: Vector2) -> float:
	"""Get enemy spawn chance for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("enemy_spawn_chance", 0.3)

func get_enemies_per_camp_for_position(world_pos: Vector2) -> int:
	"""Get enemies per camp for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("enemies_per_camp", 3)

func get_color_tint_for_position(world_pos: Vector2) -> Color:
	"""Get color tint for biome at position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("color_tint", Color.WHITE)

func get_biome_name_for_position(world_pos: Vector2) -> String:
	"""Get the name of the biome at a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("name", "Unknown")
