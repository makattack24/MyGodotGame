extends CanvasLayer

## Weather VFX Controller
## This node should be a child of the main scene, rendered as a CanvasLayer.
## It reads the WeatherSystem state each frame and drives particle/overlay effects.

# ─── Child nodes (created in code) ───
var rain_particles: GPUParticles2D = null
var heavy_rain_particles: GPUParticles2D = null
var snow_particles: GPUParticles2D = null
var fog_overlay: ColorRect = null
var sandstorm_overlay: ColorRect = null
var cloud_overlay: ColorRect = null
var lightning_flash: ColorRect = null
var wind_particles: GPUParticles2D = null

# ─── State ───
var weather_system: Node = null
var screen_size: Vector2 = Vector2(960, 540)

# Lightning
var lightning_timer: float = 0.0
var lightning_interval: float = 8.0
var is_flashing: bool = false

# Pre-built textures
var rain_texture: Texture2D = null
var snow_texture: Texture2D = null
var sand_texture: Texture2D = null

func _ready() -> void:
	layer = 90  # Above game, below HUD (HUD is layer 100-ish)
	name = "WeatherVFX"
	
	# Wait one frame so the tree is set up
	await get_tree().process_frame
	
	screen_size = get_viewport().get_visible_rect().size
	
	# Build textures first
	rain_texture = _make_raindrop_texture()
	snow_texture = _make_snowflake_texture()
	sand_texture = _make_sand_texture()
	
	_create_rain_particles()
	_create_heavy_rain_particles()
	_create_snow_particles()
	_create_fog_overlay()
	_create_sandstorm_overlay()
	_create_cloud_overlay()
	_create_lightning_flash()
	_create_wind_particles()
	
	# Start with everything off
	_hide_all()
	
	# Find weather system
	weather_system = get_tree().get_first_node_in_group("WeatherSystem")

func _process(delta: float) -> void:
	if not weather_system:
		weather_system = get_tree().get_first_node_in_group("WeatherSystem")
		if not weather_system:
			return
	
	var weather: int = weather_system.current_weather
	var intensity: float = weather_system.get_intensity()
	
	# Update each effect
	_update_rain(weather, intensity)
	_update_snow(weather, intensity)
	_update_fog(weather, intensity)
	_update_sandstorm(weather, intensity)
	_update_clouds(weather, intensity)
	_update_lightning(weather, intensity, delta)
	_update_wind(weather, intensity)

# ══════════════════════════════════════════════
#  RAIN
# ══════════════════════════════════════════════
func _create_rain_particles() -> void:
	rain_particles = GPUParticles2D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 300
	rain_particles.lifetime = 0.8
	rain_particles.emitting = false
	rain_particles.position = Vector2(screen_size.x / 2, -10)
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 5.0
	mat.initial_velocity_min = 400.0
	mat.initial_velocity_max = 500.0
	mat.gravity = Vector3(0, 200, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(screen_size.x / 2, 0, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(0.6, 0.7, 0.9, 0.5)
	
	rain_particles.process_material = mat
	rain_particles.texture = rain_texture
	rain_particles.visibility_rect = Rect2(-screen_size.x, -50, screen_size.x * 2, screen_size.y + 100)
	
	add_child(rain_particles)

func _create_heavy_rain_particles() -> void:
	heavy_rain_particles = GPUParticles2D.new()
	heavy_rain_particles.name = "HeavyRainParticles"
	heavy_rain_particles.amount = 600
	heavy_rain_particles.lifetime = 0.6
	heavy_rain_particles.emitting = false
	heavy_rain_particles.position = Vector2(screen_size.x / 2, -10)
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(-0.15, 1, 0)  # Slight wind angle
	mat.spread = 8.0
	mat.initial_velocity_min = 550.0
	mat.initial_velocity_max = 700.0
	mat.gravity = Vector3(0, 300, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(screen_size.x / 2, 0, 0)
	mat.scale_min = 0.8
	mat.scale_max = 2.0
	mat.color = Color(0.5, 0.6, 0.85, 0.6)
	
	heavy_rain_particles.process_material = mat
	heavy_rain_particles.texture = rain_texture
	heavy_rain_particles.visibility_rect = Rect2(-screen_size.x, -50, screen_size.x * 2, screen_size.y + 100)
	
	add_child(heavy_rain_particles)

func _update_rain(weather: int, intensity: float) -> void:
	var ws = weather_system
	var is_rain = weather == ws.Weather.RAIN
	var is_heavy = weather in [ws.Weather.HEAVY_RAIN, ws.Weather.THUNDERSTORM]
	
	rain_particles.emitting = is_rain
	heavy_rain_particles.emitting = is_heavy
	
	if is_rain and rain_particles.process_material:
		rain_particles.process_material.color.a = 0.5 * intensity
	if is_heavy and heavy_rain_particles.process_material:
		heavy_rain_particles.process_material.color.a = 0.6 * intensity

# ══════════════════════════════════════════════
#  SNOW
# ══════════════════════════════════════════════
func _create_snow_particles() -> void:
	snow_particles = GPUParticles2D.new()
	snow_particles.name = "SnowParticles"
	snow_particles.amount = 200
	snow_particles.lifetime = 3.0
	snow_particles.emitting = false
	snow_particles.position = Vector2(screen_size.x / 2, -10)
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.1, 1, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, 20, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(screen_size.x / 2, 0, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(0.95, 0.95, 1.0, 0.7)
	# Add turbulence for gentle drifting
	mat.turbulence_enabled = true
	mat.turbulence_noise_strength = 2.0
	mat.turbulence_noise_speed_random = 0.5
	mat.turbulence_noise_speed = Vector3(0.5, 0.2, 0)
	mat.turbulence_influence_min = 0.3
	mat.turbulence_influence_max = 0.6
	
	snow_particles.process_material = mat
	snow_particles.texture = snow_texture
	snow_particles.visibility_rect = Rect2(-screen_size.x, -50, screen_size.x * 2, screen_size.y + 100)
	
	add_child(snow_particles)

func _update_snow(weather: int, intensity: float) -> void:
	var ws = weather_system
	var is_snow = weather == ws.Weather.SNOW
	snow_particles.emitting = is_snow
	if is_snow and snow_particles.process_material:
		snow_particles.process_material.color.a = 0.7 * intensity

# ══════════════════════════════════════════════
#  FOG
# ══════════════════════════════════════════════
func _create_fog_overlay() -> void:
	fog_overlay = ColorRect.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.color = Color(0.8, 0.8, 0.85, 0.0)
	fog_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fog_overlay.anchor_right = 1.0
	fog_overlay.anchor_bottom = 1.0
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog_overlay)

func _update_fog(weather: int, intensity: float) -> void:
	var ws = weather_system
	if weather == ws.Weather.FOG:
		fog_overlay.color.a = lerp(fog_overlay.color.a, 0.4 * intensity, 0.02)
	else:
		fog_overlay.color.a = lerp(fog_overlay.color.a, 0.0, 0.05)

# ══════════════════════════════════════════════
#  SANDSTORM
# ══════════════════════════════════════════════
func _create_sandstorm_overlay() -> void:
	sandstorm_overlay = ColorRect.new()
	sandstorm_overlay.name = "SandstormOverlay"
	sandstorm_overlay.color = Color(0.8, 0.65, 0.3, 0.0)
	sandstorm_overlay.anchors_preset = Control.PRESET_FULL_RECT
	sandstorm_overlay.anchor_right = 1.0
	sandstorm_overlay.anchor_bottom = 1.0
	sandstorm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sandstorm_overlay)

func _create_wind_particles() -> void:
	wind_particles = GPUParticles2D.new()
	wind_particles.name = "WindParticles"
	wind_particles.amount = 150
	wind_particles.lifetime = 1.5
	wind_particles.emitting = false
	wind_particles.position = Vector2(-20, screen_size.y / 2)
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0.1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 300.0
	mat.initial_velocity_max = 500.0
	mat.gravity = Vector3(0, 0, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(0, screen_size.y / 2, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(0.85, 0.75, 0.45, 0.4)
	
	wind_particles.process_material = mat
	wind_particles.texture = sand_texture
	wind_particles.visibility_rect = Rect2(-50, -screen_size.y, screen_size.x + 100, screen_size.y * 2)
	
	add_child(wind_particles)

func _update_sandstorm(weather: int, intensity: float) -> void:
	var ws = weather_system
	if weather == ws.Weather.SANDSTORM:
		sandstorm_overlay.color.a = lerp(sandstorm_overlay.color.a, 0.35 * intensity, 0.02)
	else:
		sandstorm_overlay.color.a = lerp(sandstorm_overlay.color.a, 0.0, 0.05)

func _update_wind(weather: int, intensity: float) -> void:
	var ws = weather_system
	wind_particles.emitting = weather == ws.Weather.SANDSTORM
	if weather == ws.Weather.SANDSTORM and wind_particles.process_material:
		wind_particles.process_material.color.a = 0.4 * intensity

# ══════════════════════════════════════════════
#  CLOUDS (subtle darkening for cloudy weather)
# ══════════════════════════════════════════════
func _create_cloud_overlay() -> void:
	cloud_overlay = ColorRect.new()
	cloud_overlay.name = "CloudOverlay"
	cloud_overlay.color = Color(0.3, 0.3, 0.4, 0.0)
	cloud_overlay.anchors_preset = Control.PRESET_FULL_RECT
	cloud_overlay.anchor_right = 1.0
	cloud_overlay.anchor_bottom = 1.0
	cloud_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cloud_overlay)

func _update_clouds(weather: int, intensity: float) -> void:
	var ws = weather_system
	var target_alpha: float = 0.0
	match weather:
		ws.Weather.CLOUDY:
			target_alpha = 0.15 * intensity
		ws.Weather.RAIN:
			target_alpha = 0.1 * intensity
		ws.Weather.HEAVY_RAIN, ws.Weather.THUNDERSTORM:
			target_alpha = 0.25 * intensity
	cloud_overlay.color.a = lerp(cloud_overlay.color.a, target_alpha, 0.03)

# ══════════════════════════════════════════════
#  LIGHTNING
# ══════════════════════════════════════════════
func _create_lightning_flash() -> void:
	lightning_flash = ColorRect.new()
	lightning_flash.name = "LightningFlash"
	lightning_flash.color = Color(1, 1, 0.95, 0.0)
	lightning_flash.anchors_preset = Control.PRESET_FULL_RECT
	lightning_flash.anchor_right = 1.0
	lightning_flash.anchor_bottom = 1.0
	lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lightning_flash)

func _update_lightning(weather: int, _intensity: float, delta: float) -> void:
	var ws = weather_system
	if weather != ws.Weather.THUNDERSTORM:
		lightning_flash.color.a = lerp(lightning_flash.color.a, 0.0, 0.1)
		lightning_timer = 0.0
		return
	
	lightning_timer += delta
	# Random lightning strikes
	if not is_flashing and lightning_timer >= lightning_interval:
		lightning_timer = 0.0
		lightning_interval = randf_range(3.0, 12.0)
		_do_lightning_flash()
	
	# Fade out flash
	if is_flashing:
		lightning_flash.color.a = lerp(lightning_flash.color.a, 0.0, 0.15)
		if lightning_flash.color.a < 0.01:
			lightning_flash.color.a = 0.0
			is_flashing = false

func _do_lightning_flash() -> void:
	is_flashing = true
	lightning_flash.color.a = randf_range(0.5, 0.9)

# ─── Utility ───
func _hide_all() -> void:
	rain_particles.emitting = false
	heavy_rain_particles.emitting = false
	snow_particles.emitting = false
	wind_particles.emitting = false
	fog_overlay.color.a = 0.0
	sandstorm_overlay.color.a = 0.0
	cloud_overlay.color.a = 0.0
	lightning_flash.color.a = 0.0

# ─── Texture generators ───
func _make_raindrop_texture() -> ImageTexture:
	# Tall narrow streak (2x8 px)
	var img = Image.create(2, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		var a = 1.0 - float(y) / 8.0  # Fade from top to bottom
		for x in range(2):
			img.set_pixel(x, y, Color(0.7, 0.8, 1.0, a))
	return ImageTexture.create_from_image(img)

func _make_snowflake_texture() -> ImageTexture:
	# Soft round dot (6x6 px)
	var size_px := 6
	var img = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var center := Vector2(size_px / 2.0, size_px / 2.0)
	var radius := size_px / 2.0
	for y in range(size_px):
		for x in range(size_px):
			var dist = Vector2(x + 0.5, y + 0.5).distance_to(center)
			var a = clampf(1.0 - dist / radius, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

func _make_sand_texture() -> ImageTexture:
	# Small horizontal streak (4x2 px)
	var img = Image.create(4, 2, false, Image.FORMAT_RGBA8)
	for x in range(4):
		var a = 1.0 - abs(float(x) - 1.5) / 2.0
		for y in range(2):
			img.set_pixel(x, y, Color(0.9, 0.8, 0.5, a))
	return ImageTexture.create_from_image(img)
