extends Node2D

# Path to the enemy scene
@export var enemy_scene: PackedScene          # Scene used for enemy instantiation

# Spawn mode selection
@export_enum("Camps", "Continuous") var spawn_mode: int = 0  # 0 = Camps, 1 = Continuous

# Camp settings (used when spawn_mode = 0)
@export_group("Camp Settings")
@export var num_camps: int = 5                # Number of enemy camps to create
@export var enemies_per_camp: int = 3         # Enemies in each camp
@export var camp_spawn_radius: float = 800.0  # How far from player to spawn camps
@export var camp_enemy_spread: float = 80.0   # How spread out enemies are in a camp
@export var min_camp_distance: float = 300.0  # Minimum distance between camps

# Continuous spawn settings (used when spawn_mode = 1)
@export_group("Continuous Spawn Settings")
@export var spawn_interval: float = 2.0       # Time between enemy spawns
@export var spawn_radius: float = 300.0       # Distance from the player to spawn enemies

# Player node reference
@export var player: Node2D                    # Reference to the player node

# Reference to BiomeManager
var biome_manager: Node = null

# Store camp positions
var camp_positions: Array[Vector2] = []

# Internal timer for continuous spawning
var _spawn_timer: Timer

# Track player movement for dynamic camp spawning
var last_camp_spawn_position: Vector2 = Vector2.ZERO
@export var camp_respawn_distance: float = 400.0  # Distance player must travel before spawning new camps

func _ready() -> void:
	# Ensure there's a valid enemy scene and player reference
	assert(enemy_scene != null, "Enemy scene is not assigned!")
	assert(player != null, "Player reference is required!")
	
	# Choose spawning mode
	if spawn_mode == 0:  # Camp mode
		# Initialize last spawn position
		last_camp_spawn_position = player.global_position
		# Generate initial camp positions
		generate_camps()
		# Spawn enemies at each camp
		spawn_all_camps()
	else:  # Continuous mode
		# Initialize the spawn timer
		_spawn_timer = Timer.new()
		_spawn_timer.wait_time = spawn_interval
		_spawn_timer.one_shot = false
		_spawn_timer.connect("timeout", Callable(self, "_spawn_enemy_continuous"))
		add_child(_spawn_timer)
		# Start the spawn timer
		_spawn_timer.start()

func _process(_delta: float) -> void:
	# In camp mode, check if player has moved far enough to spawn new camps
	if spawn_mode == 0 and player:
		var distance_traveled = player.global_position.distance_to(last_camp_spawn_position)
		if distance_traveled > camp_respawn_distance:
			# Update spawn position
			last_camp_spawn_position = player.global_position
			# Generate and spawn new camps around new position
			generate_camps()
			spawn_all_camps()

func generate_camps() -> void:
	"""Generate random camp positions spread around the map"""
	camp_positions.clear()
	
	for i in range(num_camps):
		var attempts = 0
		var valid_position = false
		var camp_pos = Vector2.ZERO
		
		# Try to find a valid position that's not too close to other camps
		while not valid_position and attempts < 50:
			var angle = randf_range(0, 2 * PI)
			var distance = randf_range(camp_spawn_radius * 0.5, camp_spawn_radius)
			camp_pos = player.global_position + Vector2(distance * cos(angle), distance * sin(angle))
			
			# Check if this position is far enough from existing camps
			valid_position = true
			for existing_camp in camp_positions:
				if camp_pos.distance_to(existing_camp) < min_camp_distance:
					valid_position = false
					break
			
			attempts += 1
		
		if valid_position:
			camp_positions.append(camp_pos)
			print("Camp ", i + 1, " spawned at: ", camp_pos)

func spawn_all_camps() -> void:
	"""Spawn enemies at all camp locations"""
	for camp_pos in camp_positions:
		spawn_camp_at(camp_pos)

func spawn_camp_at(camp_center: Vector2) -> void:
	"""Spawn a group of enemies at a specific camp location"""
	# Get biome manager if not already cached
	if not biome_manager:
		biome_manager = get_parent().get_node_or_null("BiomeManager")
	
	# Get biome-specific enemy count
	var enemy_count = enemies_per_camp
	if biome_manager:
		enemy_count = biome_manager.get_enemies_per_camp_for_position(camp_center)
	
	for i in range(enemy_count):
		# Randomize position within the camp area
		var offset = Vector2(
			randf_range(-camp_enemy_spread, camp_enemy_spread),
			randf_range(-camp_enemy_spread, camp_enemy_spread)
		)
		var spawn_pos = camp_center + offset
		
		# Instance the enemy
		var enemy_instance: Node2D = enemy_scene.instantiate()
		enemy_instance.position = spawn_pos
		
		# Set camp center as the enemy's home position
		if enemy_instance.has_method("set_camp_position"):
			enemy_instance.call("set_camp_position", camp_center)
		
		# Set player reference
		if enemy_instance.has_method("set_player_reference"):
			enemy_instance.call("set_player_reference", player)
		
		# Add to scene (deferred to avoid parent busy error)
		get_parent().add_child.call_deferred(enemy_instance)

func _spawn_enemy_continuous() -> void:
	"""Continuous spawning mode - spawns enemies around player periodically"""
	if player == null:
		return  # Ensure player exists before spawning

	# Generate a random angle for the enemy spawn location
	var angle: float = randf_range(0, 2 * PI)

	# Calculate enemy position based on angle and spawn radius
	var spawn_position: Vector2 = player.global_position + Vector2(spawn_radius * cos(angle), spawn_radius * sin(angle))

	# Instance the enemy scene and set its position
	var enemy_instance: Node2D = enemy_scene.instantiate()
	enemy_instance.position = spawn_position

	# Set player reference
	if enemy_instance.has_method("set_player_reference"):
		enemy_instance.call("set_player_reference", player)

	# Add the enemy instance to the scene (deferred to avoid parent busy error)
	get_parent().add_child.call_deferred(enemy_instance)
