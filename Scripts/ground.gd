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

# ==============================
# INTERNAL STATE VARIABLES
# ==============================

var noise: FastNoiseLite = FastNoiseLite.new()  # Noise generator for deterministic terrain
var generated_tiles: Dictionary = {}           # Keeps track of which tiles have already been generated

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
	# Main generation loop to handle terrain around player
	var center_tile: Vector2i = local_to_map(world_pos)

	for x in range(center_tile.x - tile_radius, center_tile.x + tile_radius):
		for y in range(center_tile.y - tile_radius, center_tile.y + tile_radius):
			var tile_pos: Vector2i = Vector2i(x, y)

			# Skip tiles that have already been generated
			if generated_tiles.has(tile_pos):
				continue

			_place_tile(tile_pos)

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
# TILE SELECTION LOGIC
# ==============================

func _choose_tile(pos: Vector2i) -> Vector2i:
	# Determines tile type using noise and tile position
	var n: float = (noise.get_noise_2d(pos.x, pos.y) + 1.0) * 0.5
	var index: int = int(floor(n * GROUND_TILES.size()))
	index = clamp(index, 0, GROUND_TILES.size() - 1)
	return GROUND_TILES[index]

