extends CharacterBody2D

# Signals
signal health_changed(current_hp, max_hp)

# Movement variables
@export var speed: float = 130.0  # Speed of the character
@export var max_health: int = 10  # Maximum health
var current_health: int = 10  # Current health
var damage_cooldown: float = 0.0  # Cooldown timer for taking damage
@export var damage_cooldown_time: float = 1.0  # Time between damage instances (in seconds)
var is_dead: bool = false  # Track if player is dead

# Reference to the AnimatedSprite2D node
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Reference to the AttackArea node (hitbox for sword attacks)
@onready var attack_area: Area2D = $AttackArea

# Reference to death sound (add an AudioStreamPlayer node in your scene named "DeathSound")
@onready var death_sound: AudioStreamPlayer2D = null  # Will be set in _ready if it exists

# Reference to damage sound
@onready var damage_sound: AudioStreamPlayer2D = null  # Will be set in _ready if it exists

# Reference to camera for screen shake
var camera: Camera2D = null

# Screen shake variables
var shake_amount: float = 0.0
var shake_decay: float = 5.0
var screen_shake_enabled: bool = true  # Can be toggled in settings

# Weapon sprite reference
@onready var weapon_sprite: Sprite2D = null  # Will be created dynamically

# Weapon texture
var axe_texture = preload("res://Assets/WoodAxe.png")

# Sword remover shader material
var sword_remover_material: ShaderMaterial = null

# Offset for the attack hitbox positions
@export var attack_offsets: Dictionary = {
	"up": Vector2(0, -16),
	"down": Vector2(0, 16),
	"left": Vector2(-16, 0),
	"right": Vector2(16, 0)
}

# Flag to check if an attack animation is playing
var is_attacking: bool = false

# Current facing direction, defaults to "down"
var facing_direction: String = "down"

# Shadow
var shadow: Polygon2D = null

# Damage flash overlay
var damage_flash: ColorRect = null

# Placement mode
var placement_mode: bool = false
var placement_preview: Node2D = null
var current_placeable_item: String = ""  # Currently selected placeable item
var placeable_scenes: Dictionary = {
	"saw_mill": preload("res://Scenes/saw_mill_machine.tscn"),
	"wall": preload("res://Scenes/wall.tscn"),
	"fence": null  # Will be set when you create fence.tscn
}
var grid_size: int = 16  # Grid size for snapping placed items
var placement_cooldown: float = 0.0  # Cooldown for continuous placement
var placement_cooldown_time: float = 0.2  # Time between placements
var build_mode_label: Label = null  # UI label for build mode indicator
var placement_radius: float = 100.0  # Maximum distance from player to place items

func _ready() -> void:
	# Add player to the Player group for item detection
	add_to_group("Player")
	# Add to persist group for saving/loading
	add_to_group("persist")
	
	# Initialize health
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	# Create weapon sprite
	weapon_sprite = Sprite2D.new()
	weapon_sprite.visible = false
	weapon_sprite.z_index = 10  # Display above character
	add_child(weapon_sprite)
	
	# Load sword remover shader
	var sword_shader = load("res://Shaders/sword_remover.gdshader")
	if sword_shader:
		sword_remover_material = ShaderMaterial.new()
		sword_remover_material.shader = sword_shader
	
	# Get death sound if it exists
	if has_node("DeathSound"):
		death_sound = $DeathSound
	
	# Get damage sound if it exists
	if has_node("DamageSound"):
		damage_sound = $DamageSound
	
	# Get camera reference from the scene tree
	camera = get_viewport().get_camera_2d()
	
	# Create shadow
	create_shadow()
	
	# Create damage flash overlay
	create_damage_flash()
	
	# Initialize input mappings
	initialize_input()

	# Connect animation finished signal to reset attack state
	anim_sprite.animation_finished.connect(_on_animation_finished)

	# Ensure the attack area is monitoring collisions
	if attack_area:
		attack_area.body_entered.connect(_on_attack_hit)
		attack_area.monitoring = false  # Disable initially
		attack_area.visible = false    # Disable visibility initially
	else:
		print("Error: AttackArea node not found!")

func _process(_delta: float) -> void:
	# Update damage cooldown
	if damage_cooldown > 0:
		damage_cooldown -= _delta
	
	# Update placement cooldown
	if placement_cooldown > 0:
		placement_cooldown -= _delta
	
	# Apply screen shake
	if shake_amount > 0 and camera and PlayerSettings.screen_shake_enabled:
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = max(0, shake_amount - shake_decay * _delta)
		if shake_amount == 0:
			camera.offset = Vector2.ZERO
	elif not PlayerSettings.screen_shake_enabled and camera:
		camera.offset = Vector2.ZERO  # Reset offset if shake is disabled
	
	if is_dead:
		return  # Don't process input if dead
	
	handle_input()
	if not is_attacking:
		move_and_animate()

func handle_input() -> void:
	if is_attacking:
		return
	
	# Check for placement mode toggle (B key)
	if Input.is_action_just_pressed("build_mode"):
		toggle_placement_mode()
	
	# Handle placement mode (but don't block movement)
	if placement_mode:
		handle_placement_mode()
	
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * speed
	
	# Update facing direction
	if velocity.x > 0:
		facing_direction = "right"
	elif velocity.x < 0:
		facing_direction = "left"
	elif velocity.y > 0:
		facing_direction = "down"
	elif velocity.y < 0:
		facing_direction = "up"

	# Attack actions (only if not in placement mode)
	if not placement_mode:
		if Input.is_action_pressed("attack1"):
			trigger_attack_animation("attack1")
		elif Input.is_action_pressed("attack2"):
			trigger_attack_animation("attack2")

func move_and_animate() -> void:
	# Move the player and animate based on velocity
	move_and_slide()
	if velocity != Vector2.ZERO:
		anim_sprite.play("run_" + facing_direction)
	else:
		anim_sprite.play("idle_" + facing_direction)

func trigger_attack_animation(attack_type: String) -> void:
	if is_attacking:
		return
	is_attacking = true

	# Get currently selected item from HUD
	var hud = get_tree().root.find_child("HUD", true, false)
	var selected_item = ""
	if hud and hud.has_method("get_selected_item"):
		var item_data = hud.get_selected_item()
		selected_item = item_data["name"]
	
	# Check if player is holding axe and show weapon sprite
	if selected_item == "axe":
		weapon_sprite.texture = axe_texture
		weapon_sprite.visible = true
		# Position weapon based on facing direction
		update_weapon_position()
		# Apply sword remover shader to hide the sword in attack animation
		if sword_remover_material:
			anim_sprite.material = sword_remover_material

	# Speed up attack animation
	anim_sprite.speed_scale = 2.0  # 2x speed (adjust this value: 1.5 = 50% faster, 2.0 = twice as fast)
	
	# Play attacking animation
	anim_sprite.play(attack_type + "_" + facing_direction)

	# Update attack hitbox position
	update_attack_hitbox()

	# Enable attack collision detection
	attack_area.visible = true
	attack_area.monitoring = true

func update_weapon_position() -> void:
	"""Position and rotate weapon sprite based on facing direction"""
	match facing_direction:
		"right":
			weapon_sprite.position = Vector2(20, 0)
			weapon_sprite.rotation_degrees = -45
			weapon_sprite.flip_h = false
		"left":
			weapon_sprite.position = Vector2(-20, 0)
			weapon_sprite.rotation_degrees = 45
			weapon_sprite.flip_h = true
		"down":
			weapon_sprite.position = Vector2(0, 20)
			weapon_sprite.rotation_degrees = 45
			weapon_sprite.flip_h = false
		"up":
			weapon_sprite.position = Vector2(0, -20)
			weapon_sprite.rotation_degrees = -135
			weapon_sprite.flip_h = false

func _on_animation_finished() -> void:
	# Reset attack state after animation finishes
	is_attacking = false
	
	# Reset animation speed back to normal
	anim_sprite.speed_scale = 1.0
	
	# Hide weapon sprite
	weapon_sprite.visible = false
	
	# Remove shader to restore normal appearance
	anim_sprite.material = null

	# Disable the attack hitbox after the animation completes
	attack_area.visible = false
	attack_area.monitoring = false

func update_attack_hitbox() -> void:
	# Ensure the attack area is positioned correctly based on the facing direction
	if attack_offsets.has(facing_direction):
		attack_area.position = attack_offsets[facing_direction]

func take_damage(damage: int) -> void:
	# Check if we're in cooldown or already dead
	if damage_cooldown > 0 or is_dead:
		return
	
	# Player takes damage
	current_health -= damage
	damage_cooldown = damage_cooldown_time  # Start cooldown
	print("Player hit! Health: ", current_health, "/", max_health)
	
	# Add screen shake on damage
	shake_amount = 4.0  # Moderate shake amount
	
	# Play damage sound
	if damage_sound:
		damage_sound.play()
	
	# Emit health changed signal
	emit_signal("health_changed", current_health, max_health)
	
	# Show damage indicator
	show_damage_text(damage)
	
	# Flash the screen red
	flash_screen_red()
	
	# Visual feedback - flash the sprite white then red multiple times
	if anim_sprite:
		for i in range(3):
			anim_sprite.modulate = Color(2.0, 2.0, 2.0)  # Bright white flash
			await get_tree().create_timer(0.08).timeout
			anim_sprite.modulate = Color(1.5, 0.3, 0.3)  # Red tint
			await get_tree().create_timer(0.08).timeout
		anim_sprite.modulate = Color(1, 1, 1)  # Back to normal
	
	# Check if player died
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	"""Heal the player by the specified amount"""
	# Don't heal if dead
	if is_dead:
		return
	
	# Add health but don't exceed max
	current_health = min(current_health + amount, max_health)
	print("Player healed! Health: ", current_health, "/", max_health)
	
	# Emit health changed signal
	emit_signal("health_changed", current_health, max_health)
	
	# Visual feedback - flash the sprite green
	if anim_sprite:
		anim_sprite.modulate = Color(0.5, 2.0, 0.5)  # Green flash
		await get_tree().create_timer(0.2).timeout
		anim_sprite.modulate = Color(1, 1, 1)  # Back to normal

func die() -> void:
	is_dead = true
	print("Player died! Game Over.")
	velocity = Vector2.ZERO
	
	# Trigger screen shake
	shake_amount = 10.0
	
	# Create dark red flash overlay using CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Draw on top of everything
	get_tree().root.add_child(canvas_layer)
	
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(0.6, 0.0, 0.0, 0.0)  # Dark red, initially transparent
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill entire screen
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	canvas_layer.add_child(flash_overlay)
	
	# Animate the flash
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.7, 0.15)  # Fade in to 70% opacity
	tween.tween_property(flash_overlay, "color:a", 0.4, 0.3)  # Fade to 40% opacity
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.6)  # Fade out slowly
	
	# Play death sound
	if death_sound and death_sound.stream:
		death_sound.play()
		# Wait for the sound to finish playing
		await death_sound.finished
	else:
		# Small delay if no sound is configured
		await get_tree().create_timer(0.5).timeout
	
	# Longer delay before showing game over menu (3 seconds)
	await get_tree().create_timer(3.0).timeout
	
	# Clean up the flash overlay and canvas layer
	if canvas_layer:
		canvas_layer.queue_free()
	
	# Find and show the game over screen
	var game_over = get_tree().root.find_child("GameOver", true, false)
	if game_over and game_over.has_method("show_game_over"):
		game_over.call("show_game_over")
	else:
		# Fallback: reload scene after 2 seconds if no game over screen exists
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

func _on_attack_hit(body: Node) -> void:
	print("Attack hit body:", body.name)  # Output what `AttackArea` hits

	# Ensure we are referencing the root node if body is a child (e.g., ForestTreeBody or enemy parts)
	while body and not body.is_in_group("Trees") and not body.is_in_group("Enemies") and body.get_parent() != null:
		body = body.get_parent()  # Walk up the node hierarchy
	print("Attack hit body:", body.name)  # Output what `AttackArea` hits

	# Check if the sword hit something and apply effects
	if not is_attacking:
		return

	if body.is_in_group("Enemies"):
		# Call the enemy's _on_hit method for damage and knockback
		if body.has_method("_on_hit"):
			var knockback_direction = (body.global_position - attack_area.global_position).normalized()
			body.call("_on_hit", 1, knockback_direction)

	elif body.is_in_group("Trees"):
		# Check if player has axe equipped
		var hud = get_tree().root.find_child("HUD", true, false)
		var has_axe_equipped = false
		
		if hud and hud.has_method("get_selected_item"):
			var item_data = hud.get_selected_item()
			has_axe_equipped = (item_data["name"] == "axe")
		
		# Only damage tree if axe is equipped
		if has_axe_equipped:
			print("Hit a tree with axe!")
			if body.has_method("take_damage"):
				body.call("take_damage", 1)  # Reduce the tree's health by 1
			else:
				print("Tree doesn't have take_damage method!")
				body.queue_free()
		else:
			print("Need an axe to chop trees! Select it from your inventory.")

func create_shadow() -> void:
	"""Create a simple shadow sprite under the player"""
	shadow = Polygon2D.new()
	shadow.name = "Shadow"
	
	# Create an ellipse shape for the shadow
	var points = PackedVector2Array()
	var num_points = 16
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		var x = cos(angle) * 10
		var y = sin(angle) * 5
		points.append(Vector2(x, y))
	
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.5)  # Semi-transparent black
	shadow.position = Vector2(0, 16)  # At the player's feet
	
	# Make sure shadow renders below sprite
	if anim_sprite:
		add_child(shadow)
		move_child(shadow, 0)  # Move to first position (renders first)
	else:
		add_child(shadow)

func create_damage_flash() -> void:
	"""Create a full-screen red flash overlay for damage feedback"""
	# Create a CanvasLayer to ensure it renders on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to render on top
	canvas_layer.name = "DamageFlashLayer"
	add_child(canvas_layer)
	
	# Create the ColorRect for the red flash
	damage_flash = ColorRect.new()
	damage_flash.color = Color(1, 0, 0, 0)  # Red with 0 alpha (invisible initially)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	
	# Make it cover the entire viewport
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	canvas_layer.add_child(damage_flash)

func flash_screen_red() -> void:
	"""Flash the screen with a light red overlay"""
	if damage_flash:
		# Quick fade in and out
		var tween = create_tween()
		tween.tween_property(damage_flash, "color:a", 0.25, 0.05)  # Fade in to 25% alpha
		tween.tween_property(damage_flash, "color:a", 0.0, 0.2)   # Fade out

func show_damage_text(damage: int) -> void:
	"""Creates a floating damage text effect"""
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	# Create a label for the floating damage text
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.modulate = Color(0.7, 0.15, 0.15)  # Darker red color
	damage_label.z_index = 100  # Draw on top
	
	# Position above the player
	damage_label.position = global_position + Vector2(-15, -40)
	
	# Add to scene root
	tree.root.add_child(damage_label)
	
	# Animate the label (float up and fade out)
	var tween = damage_label.create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	
	# Delete after animation
	tween.finished.connect(func(): damage_label.queue_free())

func initialize_input() -> void:
	# Adds WASD key mappings if they don't exist
	var input_map = InputMap
	if not input_map.has_action("move_up"):
		input_map.add_action("move_up")
		var event_up = InputEventKey.new()
		event_up.physical_keycode = KEY_W
		input_map.action_add_event("move_up", event_up)
	if not input_map.has_action("move_down"):
		input_map.add_action("move_down")
		var event_down = InputEventKey.new()
		event_down.physical_keycode = KEY_S
		input_map.action_add_event("move_down", event_down)
	if not input_map.has_action("move_left"):
		input_map.add_action("move_left")
		var event_left = InputEventKey.new()
		event_left.physical_keycode = KEY_A
		input_map.action_add_event("move_left", event_left)
	if not input_map.has_action("move_right"):
		input_map.add_action("move_right")
		var event_right = InputEventKey.new()
		event_right.physical_keycode = KEY_D
		input_map.action_add_event("move_right", event_right)

	# Add mouse button inputs for attacks
	if not input_map.has_action("attack1"):
		input_map.add_action("attack1")
		var event_attack1 = InputEventMouseButton.new()
		event_attack1.button_index = MOUSE_BUTTON_LEFT
		input_map.action_add_event("attack1", event_attack1)

	if not input_map.has_action("attack2"):
		input_map.add_action("attack2")
		var event_attack2 = InputEventMouseButton.new()
		event_attack2.button_index = MOUSE_BUTTON_RIGHT
		input_map.action_add_event("attack2", event_attack2)

	# Add B key for build mode
	if not input_map.has_action("build_mode"):
		input_map.add_action("build_mode")
		var event_build = InputEventKey.new()
		event_build.physical_keycode = KEY_B
		input_map.action_add_event("build_mode", event_build)
	
	# Add E key for pickup/interact
	if not input_map.has_action("pickup"):
		input_map.add_action("pickup")
		var event_pickup = InputEventKey.new()
		event_pickup.physical_keycode = KEY_E
		input_map.action_add_event("pickup", event_pickup)

# Save player data
func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_health": current_health,
		"max_health": max_health,
		"facing_direction": facing_direction
	}

# Load player data
func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	current_health = data.get("current_health", max_health)
	max_health = data.get("max_health", 10)
	facing_direction = data.get("facing_direction", "down")
	emit_signal("health_changed", current_health, max_health)

func toggle_placement_mode() -> void:
	# Get currently selected item
	var hud = get_tree().root.find_child("HUD", true, false)
	var selected_item = ""
	if hud and hud.has_method("get_selected_item"):
		var item_data = hud.get_selected_item()
		selected_item = item_data["name"]
	
	# Check if selected item is placeable
	if placeable_scenes.has(selected_item) and placeable_scenes[selected_item] != null:
		# Check if player has the item in inventory
		if Inventory.get_item_count(selected_item) > 0:
			current_placeable_item = selected_item
			placement_mode = !placement_mode
			if placement_mode:
				start_placement_mode()
			else:
				cancel_placement_mode()
		else:
			print("No ", selected_item, " in inventory!")
	else:
		print("Select a placeable item (saw_mill, wall, fence) from inventory first!")

func start_placement_mode() -> void:
	print("Placement mode activated - Move mouse to place, Hold Left Click to place continuously, Right Click to cancel")
	# Create preview from current placeable item
	if placeable_scenes.has(current_placeable_item) and placeable_scenes[current_placeable_item] != null:
		placement_preview = placeable_scenes[current_placeable_item].instantiate()
		get_parent().add_child(placement_preview)
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.7)  # Green tint
		
		# Disable collisions on the preview
		disable_preview_collisions(placement_preview)
	else:
		print("Error: No scene found for ", current_placeable_item)
		return
	
	# Add visual feedback to player
	anim_sprite.modulate = Color(0.7, 1.0, 0.7)  # Slight green tint
	
	# Create build mode UI label
	create_build_mode_label()

func cancel_placement_mode() -> void:
	placement_mode = false
	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null
	
	# Remove visual feedback from player
	anim_sprite.modulate = Color(1, 1, 1)  # Reset to normal
	
	# Remove build mode UI label
	remove_build_mode_label()
	
	print("Placement mode cancelled")

func handle_placement_mode() -> void:
	# Check if the selected item has changed while in build mode
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("get_selected_item"):
		var item_data = hud.get_selected_item()
		var selected_item = item_data["name"]
		
		# If selected item changed and is placeable, switch to it
		if selected_item != current_placeable_item:
			if placeable_scenes.has(selected_item) and placeable_scenes[selected_item] != null:
				# Check if player has the new item
				if Inventory.get_item_count(selected_item) > 0:
					# Switch to new placeable item
					current_placeable_item = selected_item
					# Recreate the preview with the new item
					if placement_preview:
						placement_preview.queue_free()
					placement_preview = placeable_scenes[current_placeable_item].instantiate()
					get_parent().add_child(placement_preview)
					placement_preview.modulate = Color(0.5, 1, 0.5, 0.7)
					disable_preview_collisions(placement_preview)
					print("Switched to placing: ", current_placeable_item)
	
	# Update preview position to mouse cursor with grid snapping
	if placement_preview:
		var mouse_pos = get_global_mouse_position()
		# Snap to grid
		var snapped_pos = Vector2(
			floor(mouse_pos.x / grid_size) * grid_size + grid_size / 2.0,
			floor(mouse_pos.y / grid_size) * grid_size + grid_size / 2.0
		)
		placement_preview.global_position = snapped_pos
		
		# Check if within placement radius
		var distance_from_player = global_position.distance_to(snapped_pos)
		var within_range = distance_from_player <= placement_radius
		
		# Check if position is valid (no other machines there and within range)
		if within_range and is_position_valid_for_placement(snapped_pos):
			placement_preview.modulate = Color(0.5, 1, 0.5, 0.7)  # Green = valid
		else:
			if not within_range:
				placement_preview.modulate = Color(1, 1, 0.5, 0.7)  # Yellow = out of range
			else:
				placement_preview.modulate = Color(1, 0.5, 0.5, 0.7)  # Red = invalid position
	
	# Left click to place (hold down to keep placing)
	if Input.is_action_pressed("attack1") and placement_cooldown <= 0:
		place_machine()
	
	# Right click to cancel
	if Input.is_action_just_pressed("attack2"):
		cancel_placement_mode()

func place_machine() -> void:
	if placement_preview:
		# Check if within range
		var distance_from_player = global_position.distance_to(placement_preview.global_position)
		if distance_from_player > placement_radius:
			print("Too far away to place! Get closer.")
			return
		
		# Check if position is valid
		if not is_position_valid_for_placement(placement_preview.global_position):
			print("Cannot place here - position occupied!")
			return
		
		# Remove item from inventory
		if Inventory.remove_item(current_placeable_item, 1):
			# Create actual object
			if placeable_scenes.has(current_placeable_item) and placeable_scenes[current_placeable_item] != null:
				var placed_object = placeable_scenes[current_placeable_item].instantiate()
				get_parent().add_child(placed_object)
				placed_object.global_position = placement_preview.global_position
				
				# Re-enable collisions for the placed object
				enable_object_collisions(placed_object)
				
				if placed_object.has_method("place_machine"):
					placed_object.place_machine()
				
				print(current_placeable_item.capitalize(), " placed!")
				
				# Set cooldown for continuous placement
				placement_cooldown = placement_cooldown_time
				
				# Stay in placement mode - don't exit or remove preview
		else:
			print("No more saw mills in inventory!")
			cancel_placement_mode()

func disable_preview_collisions(node: Node) -> void:
	# Recursively disable all collision shapes and physics bodies
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", true)
	elif node is PhysicsBody2D:
		node.set_deferred("collision_layer", 0)
		node.set_deferred("collision_mask", 0)
	
	for child in node.get_children():
		disable_preview_collisions(child)

func enable_object_collisions(node: Node) -> void:
	# Recursively re-enable all collision shapes and physics bodies
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", false)
	elif node is PhysicsBody2D:
		# Restore collision layers (layer 2 for placed objects, mask 3 to collide with layers 1 and 2)
		node.set_deferred("collision_layer", 2)
		node.set_deferred("collision_mask", 3)
	
	for child in node.get_children():
		enable_object_collisions(child)

func is_position_valid_for_placement(pos: Vector2) -> bool:
	# Check if too close to player
	if global_position.distance_to(pos) < grid_size * 1.5:
		return false  # Too close to player, would get stuck
	
	# For larger objects (like saw mill which is 32x32), check multiple positions
	# Define offsets for a 2x2 grid object (covers 32x32 pixels with 16 pixel grid)
	var check_positions = [
		pos,  # Center
		pos + Vector2(-grid_size / 2.0, -grid_size / 2.0),  # Top-left
		pos + Vector2(grid_size / 2.0, -grid_size / 2.0),   # Top-right
		pos + Vector2(-grid_size / 2.0, grid_size / 2.0),   # Bottom-left
		pos + Vector2(grid_size / 2.0, grid_size / 2.0)     # Bottom-right
	]
	
	# Check each position
	for check_pos in check_positions:
		# Check for overlapping placed objects using distance check
		var check_radius = grid_size * 0.7  # Check if another object is within same grid cell
		var placed_objects = get_tree().get_nodes_in_group("PlacedObjects")
		for obj in placed_objects:
			# Skip the preview itself
			if obj == placement_preview:
				continue
			# Only check placed objects (not previews)
			if obj.has_method("place_machine"):
				# It's a machine - check if it's actually placed
				if not obj.is_placed:
					continue
			# Check distance to this placed object
			if obj.global_position.distance_to(check_pos) < check_radius:
				return false
		
		# Check for trees
		var trees = get_tree().get_nodes_in_group("Trees")
		for tree in trees:
			if tree.global_position.distance_to(check_pos) < grid_size * 0.8:
				return false
		
		# Check for enemies
		var enemies = get_tree().get_nodes_in_group("Enemies")
		for enemy in enemies:
			if enemy.global_position.distance_to(check_pos) < grid_size * 0.8:
				return false
		
		# Use physics query as additional check for any static bodies
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = check_pos
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var results = space_state.intersect_point(query, 32)
		for result in results:
			var body = result["collider"]
			# Skip the player
			if body == self:
				continue
			# Skip if it's part of the preview (child StaticBody2D)
			if placement_preview and (body == placement_preview or body.get_parent() == placement_preview):
				continue
			# If we hit any other physics body, position is invalid
			if body is StaticBody2D or body is CharacterBody2D or body is RigidBody2D:
				# Check if it's a placed object by checking its parent
				var parent = body.get_parent()
				if parent and parent.is_in_group("PlacedObjects"):
					return false
				# Or if the body itself is a placed object (like Wall)
				if body.is_in_group("PlacedObjects"):
					return false
				# Check if it's a tree or its parent is a tree
				if parent and parent.is_in_group("Trees"):
					return false
				if body.is_in_group("Trees"):
					return false
	
	return true

func create_build_mode_label() -> void:
	# Create a label to show "BUILD MODE" on screen
	build_mode_label = Label.new()
	build_mode_label.text = "BUILD MODE"
	build_mode_label.add_theme_font_size_override("font_size", 24)
	build_mode_label.modulate = Color(0.5, 1, 0.5)  # Green color
	
	# Position at top center of screen
	build_mode_label.position = Vector2(-50, -250)  # Relative to player
	build_mode_label.z_index = 100
	
	add_child(build_mode_label)

func remove_build_mode_label() -> void:
	if build_mode_label:
		build_mode_label.queue_free()
		build_mode_label = null

