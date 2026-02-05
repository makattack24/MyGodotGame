extends Node
class_name PlayerVFX

# Component handles all visual effects (screen shake, flashes, floating text)

# References
var player: CharacterBody2D
var camera: Camera2D
var damage_flash: ColorRect = null

# Screen shake settings
var shake_amount: float = 0.0
var shake_decay: float = 5.0

func initialize(p_player: CharacterBody2D) -> void:
	"""Initialize component with references"""
	player = p_player
	camera = player.get_viewport().get_camera_2d()
	_create_damage_flash()

func process(delta: float) -> void:
	"""Update screen shake effect"""
	if shake_amount > 0 and camera and PlayerSettings.screen_shake_enabled:
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = max(0, shake_amount - shake_decay * delta)
		if shake_amount == 0:
			camera.offset = Vector2.ZERO
	elif not PlayerSettings.screen_shake_enabled and camera:
		camera.offset = Vector2.ZERO

func add_screen_shake(amount: float) -> void:
	"""Add screen shake effect"""
	shake_amount = amount

func flash_screen_red() -> void:
	"""Flash the screen with a red overlay (damage)"""
	if not damage_flash:
		return
	
	var tween = player.create_tween()
	tween.tween_property(damage_flash, "color:a", 0.25, 0.05)
	tween.tween_property(damage_flash, "color:a", 0.0, 0.2)

func flash_screen_orange() -> void:
	"""Flash the screen with an orange overlay (warning/requirement)"""
	if not damage_flash:
		return
	
	var original_color = damage_flash.color
	damage_flash.color = Color(1.0, 0.5, 0.0, 0.0)
	
	var tween = player.create_tween()
	tween.tween_property(damage_flash, "color:a", 0.2, 0.08)
	tween.tween_property(damage_flash, "color:a", 0.0, 0.25)
	tween.finished.connect(func(): damage_flash.color = original_color)

func create_death_flash() -> ColorRect:
	"""Create dark red flash overlay for death (returns canvas layer)"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	player.get_tree().root.add_child(canvas_layer)
	
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(0.6, 0.0, 0.0, 0.0)
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(flash_overlay)
	
	# Animate using lambda callbacks
	var tween = player.create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.7, 0.15)
	tween.tween_property(flash_overlay, "color:a", 0.4, 0.3)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.6)
	
	# Schedule cleanup using lambda
	player.get_tree().create_timer(4.0).timeout.connect(func(): canvas_layer.queue_free())
	
	return flash_overlay

func show_damage_text(damage: int, position: Vector2) -> void:
	"""Creates a floating damage text effect"""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.modulate = Color(0.7, 0.15, 0.15)
	damage_label.z_index = 100
	damage_label.position = position + Vector2(-15, -40)
	
	tree.root.add_child(damage_label)
	
	# Animate using lambda cleanup
	var tween = damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): damage_label.queue_free())

func show_requirement_text(message: String, position: Vector2) -> void:
	"""Creates a floating requirement text effect (e.g., 'Need Axe!')"""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	var req_label = Label.new()
	req_label.text = message
	req_label.add_theme_font_size_override("font_size", 18)
	req_label.modulate = Color(1.0, 0.6, 0.1)
	req_label.z_index = 100
	req_label.position = position + Vector2(-30, -40)
	
	tree.root.add_child(req_label)
	
	# Animate using lambda cleanup
	var tween = req_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(req_label, "position:y", req_label.position.y - 60, 1.2)
	tween.tween_property(req_label, "modulate:a", 0.0, 1.2)
	tween.finished.connect(func(): req_label.queue_free())

func show_heal_effect(sprite: AnimatedSprite2D) -> void:
	"""Visual feedback for healing (green flash)"""
	sprite.modulate = Color(0.5, 2.0, 0.5)
	# Use lambda for cleanup after delay
	player.get_tree().create_timer(0.2).timeout.connect(
		func(): sprite.modulate = Color(1, 1, 1)
	)

func show_damage_effect(sprite: AnimatedSprite2D) -> void:
	"""Visual feedback for taking damage (white/red flashes)"""
	var flash_sequence = func():
		for i in range(3):
			sprite.modulate = Color(2.0, 2.0, 2.0)
			await player.get_tree().create_timer(0.08).timeout
			sprite.modulate = Color(1.5, 0.3, 0.3)
			await player.get_tree().create_timer(0.08).timeout
		sprite.modulate = Color(1, 1, 1)
	
	flash_sequence.call()

func create_shadow(sprite: AnimatedSprite2D) -> Polygon2D:
	"""Create a simple shadow sprite under the player"""
	var shadow = Polygon2D.new()
	shadow.name = "Shadow"
	
	# Create ellipse shape using lambda for point generation
	var num_points = 16
	var points = PackedVector2Array()
	
	# Generate shadow points
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		points.append(Vector2(cos(angle) * 10, sin(angle) * 5))
	
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.5)
	shadow.position = Vector2(0, 16)
	
	# Add to player and move to back
	player.add_child(shadow)
	if sprite:
		player.move_child(shadow, 0)
	
	return shadow

# Private methods

func _create_damage_flash() -> void:
	"""Create full-screen red flash overlay for damage feedback"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "DamageFlashLayer"
	player.add_child(canvas_layer)
	
	damage_flash = ColorRect.new()
	damage_flash.color = Color(1, 0, 0, 0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	canvas_layer.add_child(damage_flash)
