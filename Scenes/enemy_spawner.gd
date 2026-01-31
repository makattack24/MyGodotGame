extends Node2D

# Path to the enemy scene
@export var enemy_scene: PackedScene          # Scene used for enemy instantiation

# Spawn interval (in seconds)
@export var spawn_interval: float = 2.0       # Time between enemy spawns

# Define the spawn radius
@export var spawn_radius: float = 300.0       # Distance from the player to spawn enemies

# Player node reference
@export var player: Node2D                    # Reference to the player node

# Internal timer for spawning
var _spawn_timer: Timer

func _ready() -> void:
	# Ensure there's a valid enemy scene and player reference
	assert(enemy_scene != null, "Enemy scene is not assigned!")
	assert(player != null, "Player reference is required!")

	# Initialize the spawn timer
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.connect("timeout", Callable(self, "_spawn_enemy"))  # Call _spawn_enemy on timer timeout
	add_child(_spawn_timer)

	# Start the spawn timer
	_spawn_timer.start()

func _spawn_enemy() -> void:
	if player == null:
		return  # Ensure player exists before spawning

	# Generate a random angle for the enemy spawn location
	var angle: float = randf_range(0, 2 * PI)

	# Calculate enemy position based on angle and spawn radius
	var spawn_position: Vector2 = player.global_position + Vector2(spawn_radius * cos(angle), spawn_radius * sin(angle))

	# Instance the enemy scene and set its position
	var enemy_instance: Node2D = enemy_scene.instantiate()
	enemy_instance.position = spawn_position

	# If the enemy script requires a reference to the player, assign it
	if enemy_instance.has_method("set_player_reference"):
		enemy_instance.call("set_player_reference", player)

	# Add the enemy instance to the scene
	get_parent().add_child(enemy_instance)  # Add enemy directly to the parent, not the spawner
