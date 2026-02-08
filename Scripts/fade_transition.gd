
extends CanvasLayer

var target_scene: String = ""


func _ready():
	$ColorRect.color = Color(0, 0, 0, 0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out" and target_scene != "":
		get_tree().change_scene_to_file(target_scene)
		$AnimationPlayer.play("fade_in")
		target_scene = ""


func fade_to_scene(scene_path: String) -> void:
	target_scene = scene_path
	$AnimationPlayer.play("fade_out")

func fade_in():
	$ColorRect.color = Color(0, 0, 0, 1)
	$AnimationPlayer.play("fade_in", .25) #half speed

func fade_and_reload() -> void:
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().reload_current_scene()
	$AnimationPlayer.play("fade_in")