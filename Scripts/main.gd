extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var player: Node2D = $Player
@onready var object_spawner: Node2D = $ObjectSpawner
@onready var save_manager: Node = $SaveManager

func _ready() -> void:
	# Try to load saved game on start
	if save_manager and save_manager.has_save():
		print("Save file found. Press L to load or continue with new game.")

func _process(_delta: float) -> void:
	ground.generate_around(player.global_position)
	object_spawner.spawn_objects_around(player.global_position)

func _input(event: InputEvent) -> void:
	# Manual save with F5
	if event is InputEventKey and event.keycode == KEY_F5 and event.pressed:
		if save_manager:
			save_manager.save_game()
			var hud = get_node_or_null("HUD")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("GAME SAVED!", 2.0)
			print("Game manually saved!")
	
	# Load game with L key
	if event is InputEventKey and event.keycode == KEY_L and event.pressed:
		if save_manager:
			var success = save_manager.load_game()
			var hud = get_node_or_null("HUD")
			if hud and hud.has_method("show_notification"):
				if success:
					hud.show_notification("GAME LOADED!", 2.0)
				else:
					hud.show_notification("NO SAVE FILE FOUND", 2.0)
			print("Game loaded!")
