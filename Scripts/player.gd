extends CharacterBody2D

# Movement variables
@export var speed: float = 130.0  # Speed of the character

# Reference to the AnimatedSprite2D node
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Reference to the AttackArea node (hitbox for sword attacks)
@onready var attack_area: Area2D = $AttackArea

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

	# Play attacking animation
	anim_sprite.play(attack_type + "_" + facing_direction)

	# Update attack hitbox position
	update_attack_hitbox()

	# Enable attack collision detection
	attack_area.visible = true
	attack_area.monitoring = true

func _on_animation_finished() -> void:
	# Reset attack state after animation finishes
	is_attacking = false

	# Disable the attack hitbox after the animation completes
	attack_area.visible = false
	attack_area.monitoring = false

func update_attack_hitbox() -> void:
	# Ensure the attack area is positioned correctly based on the facing direction
	if attack_offsets.has(facing_direction):
		attack_area.position = attack_offsets[facing_direction]

func _on_attack_hit(body: Node) -> void:
	print("Attack hit body:", body.name)  # Output what `AttackArea` hits

	# Ensure we are referencing the root node if body is a child (e.g., ForestTreeBody)
	while body and not body.is_in_group("Trees") and body.get_parent() != null:
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
		# Call the tree's take_damage method
		print("Hit a tree!")  # <-- Add this line
		if body.has_method("take_damage"):
			body.call("take_damage", 1)  # Reduce the tree's health by 1
		else:
			print("Tree doesn't have take_damage method!")  # Debugging fallback
			# If no `take_damage` method, just destroy the tree
			body.queue_free()

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