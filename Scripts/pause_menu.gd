extends CanvasLayer

func _ready() -> void:
	visible = false
	get_tree().paused = false
	
	# Update toggle state to match music state
	var music_toggle = $VBoxContainer/MusicToggle
	var volume_slider = $VBoxContainer/VolumeContainer/VolumeSlider
	var controls_toggle = $VBoxContainer/ControlsToggle
	
	if BgMusic and music_toggle:
		music_toggle.button_pressed = BgMusic.playing
	
	if BgMusic and volume_slider:
		volume_slider.value = BgMusic.volume_db
	
	# Update controls toggle state
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and controls_toggle:
		var controls_panel = hud.get_node_or_null("ControlsPanel")
		if controls_panel:
			controls_toggle.button_pressed = controls_panel.visible

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true


func _on_resume_pressed() -> void:
	visible = false
	get_tree().paused = false


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_music_toggle_toggled(toggled_on: bool) -> void:
	if BgMusic:
		if toggled_on:
			BgMusic.play()
		else:
			BgMusic.stop()


func _on_volume_slider_value_changed(value: float) -> void:
	if BgMusic:
		BgMusic.volume_db = value


func _on_controls_toggle_toggled(toggled_on: bool) -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		var controls_panel = hud.get_node_or_null("ControlsPanel")
		if controls_panel:
			controls_panel.visible = toggled_on
