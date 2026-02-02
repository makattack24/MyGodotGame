extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var player: Node2D = $Player
@onready var object_spawner: Node2D = $ObjectSpawner
@onready var save_manager: Node = $SaveManager
@onready var biome_manager: Node = null
@onready var hud: CanvasLayer = null

var last_biome_check_position: Vector2 = Vector2.ZERO
var biome_check_distance: float = 50.0  # Check biome every 50 units of movement

func _ready() -> void:
	# Create and add BiomeManager
	biome_manager = load("res://Scripts/biome_manager.gd").new()
	biome_manager.name = "BiomeManager"
	add_child(biome_manager)
	
	# Set spawn point to player's initial position
	if player and biome_manager:
		biome_manager.set_spawn_point(player.global_position)
		last_biome_check_position = player.global_position
	
	# Get HUD reference
	hud = get_node_or_null("HUD")
	
	# Try to load saved game on start
	if save_manager and save_manager.has_save():
		print("Save file found. Press L to load or continue with new game.")

func _process(_delta: float) -> void:
	ground.generate_around(player.global_position)
	object_spawner.spawn_objects_around(player.global_position)
	
	# Update biome display when player moves significantly
	if player and biome_manager and hud:
		var distance_moved = player.global_position.distance_to(last_biome_check_position)
		if distance_moved > biome_check_distance:
			last_biome_check_position = player.global_position
			var current_biome = biome_manager.get_biome_name_for_position(player.global_position)
			if hud.has_method("update_biome_display"):
				hud.update_biome_display(current_biome)

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
