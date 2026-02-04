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

# ==============================
# TILE SOURCE CONFIGURATION
# ==============================
# Each biome can use a different Tile Source in your TileSet
# When you add a new Tile Source (e.g., desert tiles), update the source_id and ground_tiles below

# Biome definitions with properties
var biome_data: Dictionary = {
	BiomeType.STARTER: {
		"name": "Starter Plains",
		"source_id": 0,  # Tile Source ID in your TileSet (currently grass)
		"ground_tiles": [  # Atlas coordinates within that source
			Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
			Vector2i(10, 1), Vector2i(10, 2), Vector2i(11, 1), Vector2i(11, 2)
		],
		"objects": [
			{"scene": "res://Scenes/forest_tree.tscn", "spawn_chance": 0.3, "weight": 0.6},
			{"scene": "res://Scenes/bush.tscn", "spawn_chance": 0.25, "weight": 0.4}
		],
		"min_object_spacing": 40.0,
		"enemy_spawn_chance": 0.1,
		"enemies_per_camp": 2,
		"color_tint": Color(1.0, 1.0, 1.0, 1.0)
	},
	BiomeType.FOREST: {
		"name": "Forest",
		"source_id": 1,  # Using grass source for now
		"ground_tiles": [
			Vector2i(0, 8), 
			Vector2i(1, 8), 
			Vector2i(2, 8), 
			Vector2i(3, 8),
			Vector2i(4, 8), 
			Vector2i(5, 8), 
			Vector2i(0, 9), 
			Vector2i(1, 9),
			Vector2i(2, 9),
			Vector2i(3, 9),
			Vector2i(4, 9),
			Vector2i(5, 9),
		],
		"objects": [
			{"scene": "res://Scenes/forest_tree.tscn", "spawn_chance": 0.4, "weight": 0.7},
			{"scene": "res://Scenes/bush.tscn", "spawn_chance": 0.35, "weight": 0.3}
		],
		"min_object_spacing": 35.0,
		"enemy_spawn_chance": 0.3,
		"enemies_per_camp": 3,
		"color_tint": Color(0.9, 1.0, 0.9, 1.0)
	},
	BiomeType.DENSE_FOREST: {
		"name": "Dense Forest",
		"source_id": 7,  # Using grass source for now
		"ground_tiles": [
			Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8),
			Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9),
		],
		"objects": [
			{"scene": "res://Scenes/forest_tree.tscn", "spawn_chance": 0.45, "weight": 0.8},
			{"scene": "res://Scenes/bush.tscn", "spawn_chance": 0.3, "weight": 0.2}
		],
		"min_object_spacing": 30.0,
		"enemy_spawn_chance": 0.4,
		"enemies_per_camp": 4,
		"color_tint": Color(0.8, 1.0, 0.8, 1.0)
	},
	BiomeType.SWAMP: {
		"name": "Swamp",
		"source_id": 4,  # TODO: Change to 2 (or whatever) when you add swamp Tile Source
		"ground_tiles": [  # Atlas coordinates within that source
			Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
			Vector2i(10, 1), Vector2i(10, 2), Vector2i(11, 1), Vector2i(11, 2)
		],
		"objects": [
			{"scene": "res://Scenes/dead_tree.tscn", "spawn_chance": 0.25, "weight": 0.5},
			{"scene": "res://Scenes/bush.tscn", "spawn_chance": 0.2, "weight": 0.3},
			{"scene": "res://Scenes/rock.tscn", "spawn_chance": 0.18, "weight": 0.2}
		],
		"min_object_spacing": 45.0,
		"enemy_spawn_chance": 0.5,
		"enemies_per_camp": 4,
		"color_tint": Color(0.8, 0.9, 0.7, 1.0)
	},
	BiomeType.TAIGA: {
		"name": "Taiga",
		"source_id": 3,  # TODO: Change to 3 (or whatever) when you add taiga Tile Source
		"ground_tiles": [  # Atlas coordinates within that source
			Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
			Vector2i(10, 1), Vector2i(10, 2), Vector2i(11, 1), Vector2i(11, 2)
		],
		"objects": [
			{"scene": "res://Scenes/forest_tree.tscn", "spawn_chance": 0.3, "weight": 0.7},
			{"scene": "res://Scenes/rock.tscn", "spawn_chance": 0.25, "weight": 0.3}
		],
		"min_object_spacing": 45.0,
		"enemy_spawn_chance": 0.3,
		"enemies_per_camp": 3,
		"color_tint": Color(0.9, 0.95, 1.0, 1.0)
	},
	BiomeType.DESERT: {
		"name": "Desert",
		"source_id": 1,  # TODO: Change to 1 when you add desert Tile Source
		"ground_tiles": [
			Vector2i(0, 64), 
			Vector2i(1, 64), 
			Vector2i(2, 64), 
			Vector2i(3, 64),
			Vector2i(4, 64), 
			Vector2i(5, 64), 
			Vector2i(0, 65), 
			Vector2i(1, 65),
			Vector2i(2, 65),
			Vector2i(3, 65),
			Vector2i(4, 65),
			Vector2i(5, 65),

		],
		"objects": [
			{"scene": "res://Scenes/cactus.tscn", "spawn_chance": 0.25, "weight": 0.6},
			{"scene": "res://Scenes/rock.tscn", "spawn_chance": 0.2, "weight": 0.3},
			{"scene": "res://Scenes/dead_tree.tscn", "spawn_chance": 0.1, "weight": 0.1}
		],
		"min_object_spacing": 50.0,
		"enemy_spawn_chance": 0.4,
		"enemies_per_camp": 3,
		"color_tint": Color(1.0, 0.95, 0.8, 1.0)
	},
	BiomeType.TUNDRA: {
		"name": "Tundra",
		"source_id": 2,  # TODO: Change to 4 (or whatever) when you add tundra Tile Source
		"ground_tiles": [  # Atlas coordinates within that source
			Vector2i(8, 1), Vector2i(8, 2), Vector2i(9, 1), Vector2i(9, 2),
			Vector2i(10, 1), Vector2i(10, 2), Vector2i(11, 1), Vector2i(11, 2)
		],
		"objects": [
			{"scene": "res://Scenes/rock.tscn", "spawn_chance": 0.25, "weight": 0.7},
			{"scene": "res://Scenes/dead_tree.tscn", "spawn_chance": 0.15, "weight": 0.3}
		],
		"min_object_spacing": 60.0,
		"enemy_spawn_chance": 0.6,
		"enemies_per_camp": 5,
		"color_tint": Color(0.9, 0.9, 1.0, 1.0)
	},
	BiomeType.CAVE: {
		"name": "Cave Entrance",
		"source_id": 6,  # TODO: Change to 5 (or whatever) when you add cave Tile Source
		"ground_tiles": [  # TODO: Update with cave atlas coordinates
			Vector2i(5, 3), Vector2i(6, 1), Vector2i(6, 2), Vector2i(6, 3)
		],
		"objects": [
			{"scene": "res://Scenes/rock.tscn", "spawn_chance": 0.3, "weight": 1.0}
		],
		"min_object_spacing": 60.0,
		"enemy_spawn_chance": 0.7,
		"enemies_per_camp": 6,
		"color_tint": Color(0.7, 0.7, 0.8, 1.0)
	}
}

# ==============================
# BIOME DISTRIBUTION
# ==============================

# Distance-based biome rings (distance from spawn point)
var biome_rings: Array[Dictionary] = [
	{"min_distance": 0,    "max_distance": 500,  "biomes": [BiomeType.STARTER]},
	{"min_distance": 500,  "max_distance": 1000, "biomes": [BiomeType.FOREST, BiomeType.STARTER]},
	{"min_distance": 1000, "max_distance": 1800, "biomes": [BiomeType.FOREST, BiomeType.DENSE_FOREST]},
	{"min_distance": 1800, "max_distance": 2800, "biomes": [BiomeType.TAIGA, BiomeType.DESERT]},
	{"min_distance": 2800, "max_distance": 4000, "biomes": [BiomeType.SWAMP, BiomeType.TUNDRA]},
	{"min_distance": 4000, "max_distance": 99999, "biomes": [BiomeType.CAVE, BiomeType.TUNDRA]}
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
	biome_noise.frequency = 0.0008  # VERY low frequency for large biome regions
	biome_noise.fractal_octaves = 2  # Fewer octaves = smoother, larger areas
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Variation noise for mixing biomes
	variation_noise.seed = 7331
	variation_noise.frequency = 0.002

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

func get_source_id_for_position(world_pos: Vector2) -> int:
	"""Get the Tile Source ID for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("source_id", 0)

func get_objects_for_position(world_pos: Vector2) -> Array:
	"""Get object spawn data for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("objects", [])

func get_min_object_spacing_for_position(world_pos: Vector2) -> float:
	"""Get minimum object spacing for a position"""
	var biome_type = get_biome_at_position(world_pos)
	var data = get_biome_data_for_type(biome_type)
	return data.get("min_object_spacing", 50.0)

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
