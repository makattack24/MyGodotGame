extends CanvasLayer

var stats_panel: CanvasLayer = null
var card_library: CanvasLayer = null

func _ready() -> void:
	visible = false
	get_tree().paused = false
	
	# Load and add stats panel as child
	var stats_scene = SceneRegistry.get_scene("stats_panel")
	stats_panel = stats_scene.instantiate()
	add_child(stats_panel)
	
	# Load and add card library as child
	var library_scene = SceneRegistry.get_scene("card_library")
	if library_scene:
		card_library = library_scene.instantiate()
		add_child(card_library)
	
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
	
	# Update screen shake toggle state
	var screen_shake_toggle = $VBoxContainer/ScreenShakeToggle
	if screen_shake_toggle:
		screen_shake_toggle.button_pressed = PlayerSettings.screen_shake_enabled

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_unpause()
		else:
			_pause()


func _pause() -> void:
	visible = true
	get_tree().paused = true
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.visible = false


func _unpause() -> void:
	visible = false
	get_tree().paused = false
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.visible = true


func _on_resume_pressed() -> void:
	_unpause()


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


func _on_screen_shake_toggle_toggled(toggled_on: bool) -> void:
	PlayerSettings.screen_shake_enabled = toggled_on


func _on_stats_pressed() -> void:
	if stats_panel:
		$VBoxContainer.visible = false
		stats_panel.show_stats()
		await stats_panel.closed
		$VBoxContainer.visible = true


func _on_card_library_pressed() -> void:
	if card_library:
		$VBoxContainer.visible = false
		card_library.show_library()
		await card_library.closed
		$VBoxContainer.visible = true
		$VBoxContainer.visible = true
