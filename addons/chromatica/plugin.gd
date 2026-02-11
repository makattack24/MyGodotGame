@tool
extends EditorPlugin

const DOCK_SCENE := preload("res://addons/chromatica/scenes/theme_generator_dock.tscn")
var dock_instance: Control

func _enter_tree():
	dock_instance = DOCK_SCENE.instantiate()
	add_control_to_bottom_panel(dock_instance, "Theme Generator")

func _exit_tree():
	_cleanup()

func _disable_plugin():
	_cleanup()

func _cleanup():
	if is_instance_valid(dock_instance):
		remove_control_from_bottom_panel(dock_instance)
		dock_instance.queue_free()
		dock_instance = null
