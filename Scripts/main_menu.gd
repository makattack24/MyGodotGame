extends CanvasLayer

var next_scene = null

func _ready() -> void:
	FadeTransition.fade_in()
	FadeTransition.connect("fade_out_finished", Callable(self, "_on_fade_out_finished"), CONNECT_DEFERRED)



func _on_start_pressed() -> void:
	next_scene = "res://Scenes/Main.tscn"
	FadeTransition.fade_out()


func _on_options_pressed() -> void:
	next_scene = "res://Scenes/OptionsMenu.tscn"
	FadeTransition.fade_out()


func _on_quit_pressed() -> void:
	get_tree().quit()



func _on_fade_out_finished():
	if next_scene != null:
		FadeTransition.disconnect("fade_out_finished", Callable(self, "_on_fade_out_finished"))
		get_tree().change_scene_to_file(next_scene)
		next_scene = null
