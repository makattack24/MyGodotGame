extends CanvasLayer

signal fade_in_finished
signal fade_out_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.show()
	anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

func fade_in():
	color_rect.show()
	anim_player.play("FadeIn")

func fade_out():
	color_rect.show()
	anim_player.play("FadeOut")

func _on_animation_finished(anim_name):
	if anim_name == "FadeIn":
		color_rect.hide()
		emit_signal("fade_in_finished")
	elif anim_name == "FadeOut":
		emit_signal("fade_out_finished")
