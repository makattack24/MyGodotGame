extends Node

# ==============================
# DEBUG MANAGER
# ==============================
# Toggle with F3. Provides fly camera, zoom, and debug overlay.
# Works alongside the normal player camera by swapping which Camera2D is current.

signal debug_mode_changed(enabled: bool)

var debug_enabled: bool = false

# Fly camera
var debug_camera: Camera2D = null
var fly_speed: float = 600.0
var fly_speed_fast: float = 1800.0  # Hold Shift to go fast
var zoom_level: float = 1.0
var zoom_min: float = 0.05  # Very zoomed out (see huge area)
var zoom_max: float = 4.0   # Very zoomed in
var zoom_step: float = 0.05 # Finer zoom steps for smoother control

# References
var player: Node2D = null
var player_camera: Camera2D = null
var main_node: Node2D = null
var ground: TileMapLayer = null
var object_spawner: Node2D = null
var day_night_cycle: Node = null

# Debug overlay (HUD)
var overlay: CanvasLayer = null
var info_label: Label = null
var options_panel: VBoxContainer = null

# Debug options
var show_collision_shapes: bool = false
var god_mode: bool = false
var freeze_enemies: bool = false
var show_biome_grid: bool = false
var time_scale: float = 1.0

# Overlay update throttle
var overlay_update_timer: float = 0.0
var overlay_update_interval: float = 0.25  # Update overlay 4x per second

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when paused
	_create_debug_camera()
	_create_overlay()

func setup(p_main: Node2D, p_player: Node2D, p_ground: TileMapLayer, p_object_spawner: Node2D) -> void:
	main_node = p_main
	player = p_player
	ground = p_ground
	object_spawner = p_object_spawner
	if player:
		player_camera = player.get_node_or_null("Camera2D")

# ==============================
# CAMERA CREATION
# ==============================

func _create_debug_camera() -> void:
	debug_camera = Camera2D.new()
	debug_camera.name = "DebugCamera"
	debug_camera.enabled = false
	debug_camera.zoom = Vector2(zoom_level, zoom_level)
	add_child(debug_camera)

# ==============================
# OVERLAY CREATION
# ==============================

func _create_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.name = "DebugOverlay"
	overlay.layer = 120  # On top of everything
	overlay.visible = false
	add_child(overlay)
	
	# Info label (top-left)
	info_label = Label.new()
	info_label.name = "DebugInfo"
	info_label.anchor_left = 0.0
	info_label.anchor_top = 0.0
	info_label.offset_left = 8
	info_label.offset_top = 8
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color(0, 1, 0))
	info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	info_label.add_theme_constant_override("shadow_offset_x", 1)
	info_label.add_theme_constant_override("shadow_offset_y", 1)
	overlay.add_child(info_label)
	
	# Options panel (top-right)
	_create_options_panel()

func _create_options_panel() -> void:
	var panel_bg = PanelContainer.new()
	panel_bg.anchor_left = 1.0
	panel_bg.anchor_right = 1.0
	panel_bg.anchor_top = 0.0
	panel_bg.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel_bg.offset_left = -220
	panel_bg.offset_right = -8
	panel_bg.offset_top = 8
	
	# Dark semi-transparent background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	panel_bg.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel_bg)
	
	options_panel = VBoxContainer.new()
	options_panel.add_theme_constant_override("separation", 2)
	panel_bg.add_child(options_panel)
	
	# Title
	var title = Label.new()
	title.text = "DEBUG OPTIONS"
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(1, 1, 0)
	options_panel.add_child(title)
	
	# Toggle buttons
	_add_toggle("God Mode (G)", "god_mode", false)
	_add_toggle("Freeze Enemies (F)", "freeze_enemies", false)
	_add_toggle("Collision Shapes (C)", "collision_shapes", false)
	_add_toggle("Biome Grid (V)", "biome_grid", false)
	
	# Speed controls label
	var speed_label = Label.new()
	speed_label.text = "Time: 1/2/3/4 = 0.25x-2x, 5 = 1x"
	speed_label.add_theme_font_size_override("font_size", 9)
	speed_label.modulate = Color(0.7, 0.7, 0.7)
	options_panel.add_child(speed_label)
	
	# Fly cam info
	var fly_label = Label.new()
	fly_label.text = "Fly: WASD + Scroll zoom\nShift = fast, T = teleport player"
	fly_label.add_theme_font_size_override("font_size", 9)
	fly_label.modulate = Color(0.7, 0.7, 0.7)
	options_panel.add_child(fly_label)
	
	# Time of day controls
	var time_label = Label.new()
	time_label.text = "Time: [ / ] nudge, presets:\n  N=midnight M=dawn ,=noon .=dusk"
	time_label.add_theme_font_size_override("font_size", 9)
	time_label.modulate = Color(0.7, 0.7, 0.7)
	options_panel.add_child(time_label)
	
	# Weather controls
	var weather_label = Label.new()
	weather_label.text = "Weather: 6=Clear 7=Rain 8=Storm\n  9=Snow 0=Fog -=Sand +=Cloudy\n  P = cycle next"
	weather_label.add_theme_font_size_override("font_size", 9)
	weather_label.modulate = Color(0.7, 0.7, 0.7)
	options_panel.add_child(weather_label)

func _add_toggle(text: String, key: String, default_val: bool) -> void:
	var cb = CheckBox.new()
	cb.text = text
	cb.button_pressed = default_val
	cb.add_theme_font_size_override("font_size", 10)
	cb.name = "toggle_" + key
	options_panel.add_child(cb)

# ==============================
# TOGGLE DEBUG MODE
# ==============================

func toggle_debug() -> void:
	debug_enabled = !debug_enabled
	overlay.visible = debug_enabled
	
	if debug_enabled:
		_enter_debug()
	else:
		_exit_debug()
	
	debug_mode_changed.emit(debug_enabled)

func _enter_debug() -> void:
	# Position debug camera at player or where player camera is
	if player:
		debug_camera.global_position = player.global_position
	
	# Reset zoom
	zoom_level = 1.0
	debug_camera.zoom = Vector2(zoom_level, zoom_level)
	
	# Make debug camera current
	debug_camera.enabled = true
	debug_camera.make_current()
	
	# Disable player camera
	if player_camera:
		player_camera.enabled = false
	
	print("[DEBUG] Debug mode ON - Fly camera active")

func _exit_debug() -> void:
	# Restore player camera
	if player_camera:
		player_camera.enabled = true
		player_camera.make_current()
	
	# Disable debug camera
	debug_camera.enabled = false
	
	# Reset debug options
	_set_freeze_enemies(false)
	_set_collision_shapes(false)
	Engine.time_scale = 1.0
	time_scale = 1.0
	
	print("[DEBUG] Debug mode OFF")

# ==============================
# INPUT HANDLING
# ==============================

func _input(event: InputEvent) -> void:
	# F3 toggles debug mode (always active)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_debug()
			get_viewport().set_input_as_handled()
			return
	
	if not debug_enabled:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				god_mode = !god_mode
				_update_toggle("toggle_god_mode", god_mode)
				_apply_god_mode()
				print("[DEBUG] God mode: ", god_mode)
			KEY_F:
				freeze_enemies = !freeze_enemies
				_update_toggle("toggle_freeze_enemies", freeze_enemies)
				_set_freeze_enemies(freeze_enemies)
				print("[DEBUG] Freeze enemies: ", freeze_enemies)
			KEY_C:
				show_collision_shapes = !show_collision_shapes
				_update_toggle("toggle_collision_shapes", show_collision_shapes)
				_set_collision_shapes(show_collision_shapes)
				print("[DEBUG] Collision shapes: ", show_collision_shapes)
			KEY_V:
				show_biome_grid = !show_biome_grid
				_update_toggle("toggle_biome_grid", show_biome_grid)
				print("[DEBUG] Biome grid: ", show_biome_grid)
			KEY_T:
				_teleport_player_to_camera()
			KEY_1:
				_set_time_scale(0.25)
			KEY_2:
				_set_time_scale(0.5)
			KEY_3:
				_set_time_scale(1.0)
			KEY_4:
				_set_time_scale(2.0)
			KEY_5:
				_set_time_scale(1.0)
			KEY_BRACKETLEFT:
				_nudge_time_of_day(-0.05)
			KEY_BRACKETRIGHT:
				_nudge_time_of_day(0.05)
			KEY_N:
				_set_time_of_day(0.0, "Midnight")
			KEY_M:
				_set_time_of_day(0.25, "Dawn")
			KEY_COMMA:
				_set_time_of_day(0.5, "Noon")
			KEY_PERIOD:
				_set_time_of_day(0.75, "Dusk")
			KEY_6:
				_set_weather_debug(0)  # Clear
			KEY_7:
				_set_weather_debug(2)  # Rain
			KEY_8:
				_set_weather_debug(4)  # Thunderstorm
			KEY_9:
				_set_weather_debug(5)  # Snow
			KEY_0:
				_set_weather_debug(6)  # Fog
			KEY_MINUS:
				_set_weather_debug(7)  # Sandstorm
			KEY_EQUAL:
				_set_weather_debug(1)  # Cloudy
			KEY_P:
				_cycle_weather_debug()
		get_viewport().set_input_as_handled()
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clampf(zoom_level + zoom_step, zoom_min, zoom_max)
			debug_camera.zoom = Vector2(zoom_level, zoom_level)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clampf(zoom_level - zoom_step, zoom_min, zoom_max)
			debug_camera.zoom = Vector2(zoom_level, zoom_level)
			get_viewport().set_input_as_handled()

# ==============================
# PROCESS (FLY CAMERA + OVERLAY)
# ==============================

func _process(delta: float) -> void:
	if not debug_enabled:
		return
	
	# Fly camera movement using raw Input (works regardless of action mappings)
	var move_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1
	
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		var speed = fly_speed_fast if Input.is_key_pressed(KEY_SHIFT) else fly_speed
		# Scale speed inversely with zoom so movement feels consistent
		var zoom_factor = 1.0 / maxf(zoom_level, 0.1)
		debug_camera.global_position += move_dir * speed * zoom_factor * delta
	
	# Throttle info overlay updates
	overlay_update_timer += delta
	if overlay_update_timer >= overlay_update_interval:
		overlay_update_timer = 0.0
		_update_info_label()

# ==============================
# INFO LABEL UPDATE
# ==============================

func _update_info_label() -> void:
	if not info_label:
		return
	
	var cam_pos = debug_camera.global_position
	var fps = Engine.get_frames_per_second()
	
	var text = "--- DEBUG MODE (F3 to close) ---\n"
	text += "FPS: %d\n" % fps
	text += "Cam: (%.0f, %.0f)\n" % [cam_pos.x, cam_pos.y]
	text += "Zoom: %.2fx\n" % zoom_level
	text += "Speed: %.2fx\n" % time_scale
	
	if player:
		text += "Player: (%.0f, %.0f)\n" % [player.global_position.x, player.global_position.y]
		var dist = cam_pos.distance_to(player.global_position)
		text += "Dist to player: %.0f\n" % dist
	
	# Node counts (cached from throttled update)
	text += "Enemies: %d\n" % get_tree().get_nodes_in_group("Enemies").size()
	text += "Objects: %d\n" % get_tree().get_nodes_in_group("EnvironmentObjects").size()
	text += "NPCs: %d\n" % get_tree().get_nodes_in_group("NPC").size()
	
	# Ground tile tracking
	if ground:
		text += "Gen tiles: %d\n" % ground.generated_tiles.size()
	
	if god_mode:
		text += "[GOD MODE]\n"
	if freeze_enemies:
		text += "[ENEMIES FROZEN]\n"
	
	# Time of day
	var dnc = _get_day_night_cycle()
	if dnc and "time_of_day" in dnc:
		var t = dnc.time_of_day
		var hours = int(t * 24.0) % 24
		var minutes = int(fmod(t * 24.0 * 60.0, 60.0))
		var period_name = _get_time_period_name(t)
		text += "Time: %02d:%02d (%s) [%.2f]\n" % [hours, minutes, period_name, t]
	
	# Weather
	var ws = _get_weather_system()
	if ws:
		text += "Weather: %s %s\n" % [ws.get_weather_icon(), ws.get_weather_name()]
		text += "Day: %s - Day %d\n" % [ws.get_day_name(), ws.get_day_count()]
	
	info_label.text = text

# ==============================
# DEBUG ACTIONS
# ==============================

func _update_toggle(node_name: String, value: bool) -> void:
	var cb = options_panel.get_node_or_null(node_name)
	if cb and cb is CheckBox:
		cb.button_pressed = value

func _teleport_player_to_camera() -> void:
	if player:
		player.global_position = debug_camera.global_position
		print("[DEBUG] Teleported player to (%.0f, %.0f)" % [debug_camera.global_position.x, debug_camera.global_position.y])

func _apply_god_mode() -> void:
	if not player:
		return
	if god_mode:
		if player.has_method("set_invincible"):
			player.set_invincible(true)
		elif "current_health" in player:
			player.current_health = player.max_health
			if player.has_signal("health_changed"):
				player.emit_signal("health_changed", player.current_health, player.max_health)
	else:
		if player.has_method("set_invincible"):
			player.set_invincible(false)

func _set_freeze_enemies(frozen: bool) -> void:
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if is_instance_valid(enemy):
			enemy.set_process(!frozen)
			enemy.set_physics_process(!frozen)

func _set_collision_shapes(visible_shapes: bool) -> void:
	get_tree().debug_collisions_hint = visible_shapes
	# Note: debug_collisions_hint only works if enabled in Project Settings at startup
	# or if the game was exported with debug on. This is a best-effort toggle.

func _set_time_scale(scale: float) -> void:
	time_scale = scale
	Engine.time_scale = scale
	print("[DEBUG] Time scale: ", scale)

func _get_day_night_cycle() -> Node:
	"""Lazily find the day/night cycle node via its group (created after setup)"""
	if day_night_cycle and is_instance_valid(day_night_cycle):
		return day_night_cycle
	var nodes = get_tree().get_nodes_in_group("DayNightCycle")
	if nodes.size() > 0:
		day_night_cycle = nodes[0]
	return day_night_cycle

func _set_time_of_day(value: float, label: String = "") -> void:
	var dnc = _get_day_night_cycle()
	if dnc and "time_of_day" in dnc:
		dnc.time_of_day = fmod(value, 1.0)
		if dnc.time_of_day < 0:
			dnc.time_of_day += 1.0
		var display = label if label != "" else "%.2f" % dnc.time_of_day
		print("[DEBUG] Time of day set to: %s (%.2f)" % [display, dnc.time_of_day])
	else:
		print("[DEBUG] Day/night cycle not found!")

func _nudge_time_of_day(amount: float) -> void:
	var dnc = _get_day_night_cycle()
	if dnc and "time_of_day" in dnc:
		var new_time = fmod(dnc.time_of_day + amount, 1.0)
		if new_time < 0:
			new_time += 1.0
		_set_time_of_day(new_time, _get_time_period_name(new_time))
	else:
		print("[DEBUG] Day/night cycle not found!")

func _get_time_period_name(t: float) -> String:
	if t < 0.2:
		return "Night"
	elif t < 0.3:
		return "Dawn"
	elif t < 0.35:
		return "Morning"
	elif t < 0.65:
		return "Day"
	elif t < 0.75:
		return "Dusk"
	else:
		return "Night"

# ==============================
# PUBLIC QUERY
# ==============================

func get_generation_position() -> Vector2:
	"""Returns the position to generate content around (debug cam or player)"""
	if debug_enabled:
		return debug_camera.global_position
	return Vector2.ZERO  # Caller should use player pos

# ==============================
# WEATHER DEBUG
# ==============================

var _weather_system_cache: Node = null

func _get_weather_system() -> Node:
	if _weather_system_cache and is_instance_valid(_weather_system_cache):
		return _weather_system_cache
	var nodes = get_tree().get_nodes_in_group("WeatherSystem")
	if nodes.size() > 0:
		_weather_system_cache = nodes[0]
	return _weather_system_cache

func _set_weather_debug(weather_enum: int) -> void:
	var ws = _get_weather_system()
	if ws and ws.has_method("set_weather"):
		ws.set_weather(weather_enum)
		print("[DEBUG] Weather set to: %s" % ws.get_weather_name())
	else:
		print("[DEBUG] Weather system not found!")

func _cycle_weather_debug() -> void:
	var ws = _get_weather_system()
	if ws:
		var next = (ws.current_weather + 1) % ws.Weather.size()
		ws.set_weather(next)
		print("[DEBUG] Weather cycled to: %s" % ws.get_weather_name())
	else:
		print("[DEBUG] Weather system not found!")
