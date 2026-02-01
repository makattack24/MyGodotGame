extends CanvasLayer

func _ready() -> void:
	# Hide by default
	visible = false

func show_game_over() -> void:
	# Show the game over screen
	visible = true
	# Pause the game
	get_tree().paused = true

func _on_respawn_button_pressed() -> void:
	# Unpause the game
	get_tree().paused = false
	
	# Get the save manager from Main scene
	var save_manager = get_tree().root.find_child("SaveManager", true, false)
	if save_manager and save_manager.has_method("load_game"):
		# Load the saved game
		var loaded = save_manager.load_game()
		if loaded:
			# Get the player and reset death state
			var player = get_tree().root.find_child("Player", true, false)
			if player:
				player.is_dead = false
				player.current_health = player.max_health
				player.emit_signal("health_changed", player.current_health, player.max_health)
			
			# Hide the game over screen
			visible = false
			print("Respawned at last save point")
		else:
			print("No save file found, restarting scene instead")
			get_tree().reload_current_scene()
	else:
		# Fallback to restart if save manager not found
		print("SaveManager not found, restarting scene instead")
		get_tree().reload_current_scene()

func _on_restart_button_pressed() -> void:
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
