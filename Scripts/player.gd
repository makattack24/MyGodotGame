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

# Reference to camera for screen shake
var camera: Camera2D = null

# Screen shake variables
var shake_amount: float = 0.0
var shake_decay: float = 5.0

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
	
	# Get camera reference from the scene tree
	camera = get_viewport().get_camera_2d()
	
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
	
	# Apply screen shake
	if shake_amount > 0 and camera:
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = max(0, shake_amount - shake_decay * _delta)
		if shake_amount == 0:
			camera.offset = Vector2.ZERO
	
	if is_dead:
		return  # Don't process input if dead
	
	handle_input()
	if not is_attacking:
		move_and_animate()

func handle_input() -> void:
	if is_attacking:
		return
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

	# Attack actions
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
	
	# Emit health changed signal
	emit_signal("health_changed", current_health, max_health)
	
	# Visual feedback - flash the sprite red
	if anim_sprite:
		anim_sprite.modulate = Color(1, 0.5, 0.5)  # Red tint
		await get_tree().create_timer(0.2).timeout
		anim_sprite.modulate = Color(1, 1, 1)  # Back to normal
	
	# Check if player died
	if current_health <= 0:
		die()

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

