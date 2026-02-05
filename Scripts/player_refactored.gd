extends CharacterBody2D

# Refactored Player - Core logic only, delegates to components

# Signals
signal health_changed(current_hp, max_hp)

# Movement variables
@export var speed: float = 130.0
@export var max_health: int = 10
var current_health: int = 10
var damage_cooldown: float = 0.0
@export var damage_cooldown_time: float = 1.0
var is_dead: bool = false
var facing_direction: String = "down"

# Node references
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var death_sound: AudioStreamPlayer2D = null
@onready var damage_sound: AudioStreamPlayer2D = null

# Components
var combat: PlayerCombat
var building: PlayerBuilding
var vfx: PlayerVFX

func _ready() -> void:
	_setup_groups_and_layers()
	_initialize_components()
	_setup_audio()
	_initialize_health()
	_initialize_input()

func _process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta
	
	vfx.process(delta)
	building.process(delta)
	
	if is_dead:
		return
	
	handle_input()
	if not combat.is_attacking:
		move_and_animate()

func handle_input() -> void:
	if combat.is_attacking:
		return
	
	# Build mode toggle
	if Input.is_action_just_pressed("build_mode"):
		building.toggle_placement_mode()
	
	# Pickup objects
	if Input.is_action_just_pressed("pickup"):
		building.try_pickup_nearest_object()
	
	# Handle placement mode
	if building.placement_mode:
		building.handle_placement_input()
	
	# Movement input using lambda for cleaner code
	var get_input_vector = func() -> Vector2:
		var input_vec = Vector2.ZERO
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
			input_vec.x += 1
		if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
			input_vec.x -= 1
		if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
			input_vec.y += 1
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
			input_vec.y -= 1
		return input_vec.normalized()
	
	velocity = get_input_vector.call() * speed
	
	# Update facing direction using lambda
	var update_direction = func():
		if velocity.x > 0:
			facing_direction = "right"
		elif velocity.x < 0:
			facing_direction = "left"
		elif velocity.y > 0:
			facing_direction = "down"
		elif velocity.y < 0:
			facing_direction = "up"
	
	if velocity != Vector2.ZERO:
		update_direction.call()
	
	# Attack input (only when not in build mode)
	if not building.placement_mode:
		if Input.is_action_pressed("attack1"):
			combat.trigger_attack("attack1", facing_direction)
		elif Input.is_action_pressed("attack2"):
			combat.trigger_attack("attack2", facing_direction)

func move_and_animate() -> void:
	move_and_slide()
	
	# Use lambda for animation selection
	var get_anim_name = func() -> String:
		var prefix = "run_" if velocity != Vector2.ZERO else "idle_"
		return prefix + facing_direction
	
	anim_sprite.play(get_anim_name.call())

func take_damage(damage: int) -> void:
	if damage_cooldown > 0 or is_dead:
		return
	
	current_health -= damage
	damage_cooldown = damage_cooldown_time
	
	vfx.add_screen_shake(4.0)
	
	if damage_sound:
		damage_sound.play()
	
	emit_signal("health_changed", current_health, max_health)
	
	vfx.show_damage_text(damage, global_position)
	vfx.flash_screen_red()
	vfx.show_damage_effect(anim_sprite)
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	
	vfx.show_heal_effect(anim_sprite)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	vfx.add_screen_shake(10.0)
	vfx.create_death_flash()
	
	# Play death sound and wait using lambda
	var handle_death_sequence = func():
		if death_sound and death_sound.stream:
			death_sound.play()
			await death_sound.finished
		else:
			await get_tree().create_timer(0.5).timeout
		
		await get_tree().create_timer(3.0).timeout
		
		var game_over = get_tree().root.find_child("GameOver", true, false)
		if game_over and game_over.has_method("show_game_over"):
			game_over.call("show_game_over")
		else:
			await get_tree().create_timer(2.0).timeout
			get_tree().reload_current_scene()
	
	handle_death_sequence.call()

# Save/Load
func save() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_health": current_health,
		"max_health": max_health,
		"facing_direction": facing_direction
	}

func load_data(data: Dictionary) -> void:
	global_position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	current_health = data.get("current_health", max_health)
	max_health = data.get("max_health", 10)
	facing_direction = data.get("facing_direction", "down")
	emit_signal("health_changed", current_health, max_health)

# Private setup methods

func _setup_groups_and_layers() -> void:
	add_to_group("Player")
	add_to_group("persist")
	collision_layer = 1
	collision_mask = 3

func _initialize_components() -> void:
	# Create and initialize components
	combat = PlayerCombat.new()
	combat.name = "PlayerCombat"
	add_child(combat)
	combat.initialize(self, anim_sprite, attack_area)
	
	building = PlayerBuilding.new()
	building.name = "PlayerBuilding"
	add_child(building)
	building.initialize(self, anim_sprite)
	
	vfx = PlayerVFX.new()
	vfx.name = "PlayerVFX"
	add_child(vfx)
	vfx.initialize(self)
	
	# Create shadow using VFX component
	vfx.create_shadow(anim_sprite)

func _setup_audio() -> void:
	# Get audio nodes using lambda for cleaner optional chaining
	var get_node_safe = func(node_name: String) -> Node:
		return get_node(node_name) if has_node(node_name) else null
	
	death_sound = get_node_safe.call("DeathSound")
	damage_sound = get_node_safe.call("DamageSound")

func _initialize_health() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func _initialize_input() -> void:
	# Use array of input actions with lambda for cleaner setup
	var input_actions = [
		{"name": "move_up", "key": KEY_W},
		{"name": "move_down", "key": KEY_S},
		{"name": "move_left", "key": KEY_A},
		{"name": "move_right", "key": KEY_D},
		{"name": "build_mode", "key": KEY_B},
		{"name": "pickup", "key": KEY_E}
	]
	
	# Setup keyboard actions using lambda
	input_actions.map(func(action):
		if not InputMap.has_action(action["name"]):
			InputMap.add_action(action["name"])
			var event = InputEventKey.new()
			event.physical_keycode = action["key"]
			InputMap.action_add_event(action["name"], event)
	)
	
	# Setup mouse actions using lambda
	var mouse_actions = [
		{"name": "attack1", "button": MOUSE_BUTTON_LEFT},
		{"name": "attack2", "button": MOUSE_BUTTON_RIGHT}
	]
	
	mouse_actions.map(func(action):
		if not InputMap.has_action(action["name"]):
			InputMap.add_action(action["name"])
			var event = InputEventMouseButton.new()
			event.button_index = action["button"]
			InputMap.action_add_event(action["name"], event)
	)
