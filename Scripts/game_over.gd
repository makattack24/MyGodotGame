extends CanvasLayer

func _ready() -> void:
	# Hide by default
	visible = false

func show_game_over() -> void:
	# Show the game over screen
	visible = true
	# Pause the game
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
