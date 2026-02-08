extends CanvasLayer

@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var start_btn: Button = $VBoxContainer/Start
@onready var options_btn: Button = $VBoxContainer/Options
@onready var quit_btn: Button = $VBoxContainer/Quit

var _title_orig_offset_top: float
var _title_orig_offset_bottom: float


func _ready():
	FadeTransition.fade_in()
	_title_orig_offset_top = title_container.offset_top
	_title_orig_offset_bottom = title_container.offset_bottom
	_play_entrance_animation()


func _play_entrance_animation() -> void:
	# --- initial hidden state ---
	dark_overlay.modulate.a = 0.0

	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.8, 0.8)
	title_label.pivot_offset = Vector2(title_label.size.x / 2.0, title_label.size.y / 2.0)

	subtitle_label.modulate.a = 0.0
	subtitle_label.scale = Vector2(0.85, 0.85)
	subtitle_label.pivot_offset = Vector2(subtitle_label.size.x / 2.0, subtitle_label.size.y / 2.0)

	title_container.offset_top = _title_orig_offset_top - 35
	title_container.offset_bottom = _title_orig_offset_bottom - 35

	start_btn.modulate.a = 0.0
	options_btn.modulate.a = 0.0
	quit_btn.modulate.a = 0.0

	# --- animate in ---
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Dark overlay fade
	tween.tween_property(dark_overlay, "modulate:a", 1.0, 1.0)

	# Title slide + fade + scale
	tween.parallel().tween_property(title_container, "offset_top", _title_orig_offset_top, 1.2).set_delay(0.15)
	tween.parallel().tween_property(title_container, "offset_bottom", _title_orig_offset_bottom, 1.2).set_delay(0.15)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 1.0).set_delay(0.2)
	tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 1.0).set_delay(0.2)

	# Subtitle appears shortly after
	tween.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 0.8).set_delay(0.55)
	tween.parallel().tween_property(subtitle_label, "scale", Vector2.ONE, 0.8).set_delay(0.55)

	# Buttons stagger in
	tween.parallel().tween_property(start_btn, "modulate:a", 1.0, 0.45).set_delay(1.0)
	tween.parallel().tween_property(options_btn, "modulate:a", 1.0, 0.45).set_delay(1.15)
	tween.parallel().tween_property(quit_btn, "modulate:a", 1.0, 0.45).set_delay(1.3)

	await tween.finished
	_start_float_animation()


func _start_float_animation() -> void:
	# Gentle floating motion on the title container
	var float_tween := create_tween().set_loops() \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	float_tween.tween_property(
		title_container, "offset_top", _title_orig_offset_top - 6, 2.4
	)
	float_tween.parallel().tween_property(
		title_container, "offset_bottom", _title_orig_offset_bottom - 6, 2.4
	)
	float_tween.tween_property(
		title_container, "offset_top", _title_orig_offset_top + 6, 2.4
	)
	float_tween.parallel().tween_property(
		title_container, "offset_bottom", _title_orig_offset_bottom + 6, 2.4
	)


func _on_start_pressed():
	print("Start Button Pressed")
	FadeTransition.fade_to_scene("res://Scenes/Main.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
