extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var player: Node2D = $Player
@onready var object_spawner: Node2D = $ObjectSpawner
@onready var save_manager: Node = $SaveManager
@onready var biome_manager: Node = null
@onready var hud: CanvasLayer = null

# Debug manager
var debug_manager: Node = null

var last_biome_check_position: Vector2 = Vector2.ZERO
var biome_check_distance: float = 50.0  # Check biome every 50 units of movement

# Generation throttling - only regenerate when player moves at least 1 tile
var last_generation_position: Vector2 = Vector2(INF, INF)
var generation_threshold: float = 16.0  # Pixels before regenerating (~1 tile)

# Periodic cleanup of distant content
var cleanup_timer: float = 0.0
var cleanup_interval: float = 2.0  # Seconds between cleanup passes
var enemy_cleanup_distance: float = 2000.0  # Free enemies beyond this distance

# Day/Night Cycle
var day_night_cycle: Node = null

# Weather System
var weather_system: Node = null
var weather_vfx: CanvasLayer = null

func _ready() -> void:
	
	# Create and add BiomeManager
	biome_manager = load("res://Scripts/biome_manager.gd").new()
	biome_manager.name = "BiomeManager"
	add_child(biome_manager)
	biome_manager.add_to_group("BiomeManager")
	
	# Set spawn point to player's initial position
	if player and biome_manager:
		biome_manager.set_spawn_point(player.global_position)
		last_biome_check_position = player.global_position
	
	# Set spawn position in ground to prevent chasms near start
	if player and ground:
		ground.set_spawn_position(player.global_position)
	
	# Get HUD reference
	hud = get_node_or_null("HUD")
	
	# Setup debug manager
	debug_manager = load("res://Scripts/debug_manager.gd").new()
	debug_manager.name = "DebugManager"
	add_child(debug_manager)
	debug_manager.setup(self, player, ground, object_spawner)
	debug_manager.debug_mode_changed.connect(_on_debug_mode_changed)
	
	# Try to load saved game on start
	if save_manager and save_manager.has_save():
		print("Save file found. Press L to load or continue with new game.")

	# --- DAY/NIGHT CYCLE SETUP ---
	var overlay_rect = get_node_or_null("DayNightOverlay/DayNightOverlayRect")
	if overlay_rect:
		var DayNightCycle = load("res://Scripts/day_night_cycle.gd")
		day_night_cycle = DayNightCycle.new()
		add_child(day_night_cycle)
		day_night_cycle.overlay_path = overlay_rect.get_path()
		day_night_cycle.add_to_group("DayNightCycle")
	else:
		push_warning("DayNightOverlayRect node not found! Day/night cycle will not be visible.")
		
	# --- WEATHER SYSTEM SETUP ---
	var WeatherSystem = load("res://Scripts/weather_system.gd")
	weather_system = WeatherSystem.new()
	weather_system.name = "WeatherSystem"
	add_child(weather_system)
	
	# Connect weather change signal to HUD update
	weather_system.weather_changed.connect(_on_weather_changed)
	
	# --- WEATHER VFX SETUP ---
	var WeatherVFX = load("res://Scripts/weather_vfx.gd")
	weather_vfx = WeatherVFX.new()
	weather_vfx.name = "WeatherVFX"
	add_child(weather_vfx)
		

func _process(delta: float) -> void:
	# When debug fly camera is active, generate around that instead of player
	var gen_pos: Vector2
	if debug_manager and debug_manager.debug_enabled:
		gen_pos = debug_manager.debug_camera.global_position
	else:
		gen_pos = player.global_position
	
	# Only generate terrain/objects when generation position has moved enough
	# Use a larger threshold in debug mode since the camera moves much faster
	var threshold: float = generation_threshold
	if debug_manager and debug_manager.debug_enabled:
		threshold = generation_threshold * 3.0
	if gen_pos.distance_squared_to(last_generation_position) > threshold * threshold:
		last_generation_position = gen_pos
		var is_debug: bool = debug_manager and debug_manager.debug_enabled
		ground.generate_around(gen_pos, is_debug)
		# Skip object spawning in debug mode to avoid perf hit from instantiating scenes
		if not is_debug:
			object_spawner.spawn_objects_around(gen_pos)
	
	# Periodic cleanup of distant content to prevent unbounded growth
	# Skip cleanup in debug mode — we want tiles to persist as we fly
	var is_debug_active: bool = debug_manager and debug_manager.debug_enabled
	cleanup_timer += delta
	if cleanup_timer >= cleanup_interval and not is_debug_active:
		cleanup_timer = 0.0
		_cleanup_distant_content(gen_pos)
	
	# Update biome display when player moves significantly
	if player and biome_manager and hud:
		var distance_moved = player.global_position.distance_to(last_biome_check_position)
		if distance_moved > biome_check_distance:
			last_biome_check_position = player.global_position
			var current_biome = biome_manager.get_biome_name_for_position(player.global_position)
			if hud.has_method("update_biome_display"):
				hud.update_biome_display(current_biome)
			# Update weather system with current biome
			if weather_system and weather_system.has_method("set_biome"):
				weather_system.set_biome(current_biome)

func _cleanup_distant_content(center: Vector2) -> void:
	# Clean up ground tiles and cached data far from the player
	if ground and ground.has_method("cleanup_distant_tiles"):
		ground.cleanup_distant_tiles(center)
	
	# Clean up environment objects (trees, bushes, rocks) far from the player
	if object_spawner and object_spawner.has_method("cleanup_distant_objects"):
		object_spawner.cleanup_distant_objects(center)
	
	# Clean up enemies far from the player
	var max_dist_sq: float = enemy_cleanup_distance * enemy_cleanup_distance
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_squared_to(center) > max_dist_sq:
			enemy.queue_free()

func _input(event: InputEvent) -> void:
	# Manual save with F5
	if event is InputEventKey and event.keycode == KEY_F5 and event.pressed:
		if save_manager:
			save_manager.save_game()
			if hud and hud.has_method("show_notification"):
				hud.show_notification("GAME SAVED!", 2.0)
			print("Game manually saved!")
	
	# Load game with L key
	if event is InputEventKey and event.keycode == KEY_L and event.pressed:
		if save_manager:
			var success = save_manager.load_game()
			if hud and hud.has_method("show_notification"):
				if success:
					hud.show_notification("GAME LOADED!", 2.0)
				else:
					hud.show_notification("NO SAVE FILE FOUND", 2.0)
			print("Game loaded!")

func _on_debug_mode_changed(enabled: bool) -> void:
	# Disable/enable player processing during debug fly mode
	if player:
		player.set_process_input(!enabled)
		player.set_process_unhandled_input(!enabled)
		player.set_process(!enabled)
		player.set_physics_process(!enabled)
		if not enabled:
			# Stop player movement when exiting debug
			if "velocity" in player:
				player.velocity = Vector2.ZERO
	
	# Show notification
	if hud and hud.has_method("show_notification"):
		if enabled:
			hud.show_notification("DEBUG MODE ON (F3)", 1.5)
		else:
			hud.show_notification("DEBUG MODE OFF", 1.5)

func _on_weather_changed(_new_weather: String, _old_weather: String) -> void:
	if hud and hud.has_method("update_weather_display") and weather_system:
		hud.update_weather_display(weather_system.get_weather_name(), weather_system.get_weather_icon())