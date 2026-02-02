extends CharacterBody2D

# NPC Properties
@export var npc_name: String = "Merchant"
@export var move_speed: float = 30.0
@export var wander_radius: float = 100.0
@export var idle_time: float = 3.0

# Shop items - format: {"item_name": price_in_coins}
@export var shop_items: Dictionary = {
	"wood": 5,
	"axe": 50,
	"saw_mill": 100
}

# State machine
enum State { IDLE, WANDERING }
var current_state: State = State.IDLE

# Movement
var spawn_position: Vector2
var target_position: Vector2
var idle_timer: float = 0.0

# Interaction
var player_in_range: bool = false
var nearby_player: Node2D = null

# UI References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_label: Label = $InteractionLabel

# Facing direction
var facing_direction: String = "down"

func _ready() -> void:
	# Save spawn position for wandering
	spawn_position = global_position
	target_position = spawn_position
	
	# Connect interaction area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	# Hide interaction label initially
	if interaction_label:
		interaction_label.visible = false
	
	# Start in idle state
	current_state = State.IDLE
	idle_timer = idle_time
	
	# Play idle animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle_down"):
		animated_sprite.play("idle_down")

func _process(delta: float) -> void:
	# Show/hide interaction prompt
	if interaction_label:
		interaction_label.visible = player_in_range
		if player_in_range:
			interaction_label.text = "Press E to talk"
	
	# Handle state machine
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.WANDERING:
			handle_wandering_state(delta)
	
	# Check for player interaction
	if player_in_range and Input.is_action_just_pressed("pickup"):
		open_shop()

func handle_idle_state(delta: float) -> void:
	velocity = Vector2.ZERO
	idle_timer -= delta
	
	if idle_timer <= 0:
		# Switch to wandering
		current_state = State.WANDERING
		pick_random_target()
	
	# Play idle animation
	update_animation("idle")

func handle_wandering_state(_delta: float) -> void:
	# Move towards target
	var direction = (target_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Update facing direction
	if abs(direction.x) > abs(direction.y):
		facing_direction = "right" if direction.x > 0 else "left"
	else:
		facing_direction = "down" if direction.y > 0 else "up"
	
	move_and_slide()
	
	# Check if reached target
	if global_position.distance_to(target_position) < 5.0:
		current_state = State.IDLE
		idle_timer = idle_time
		velocity = Vector2.ZERO
	
	# Play walking animation
	update_animation("run")

func pick_random_target() -> void:
	# Pick a random position within wander radius
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	target_position = spawn_position + random_offset

func update_animation(action: String) -> void:
	if not animated_sprite:
		return
	
	var anim_name = action + "_" + facing_direction
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		nearby_player = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		nearby_player = null

func open_shop() -> void:
	# Find or create shop UI
	var shop_ui = get_tree().root.find_child("ShopUI", true, false)
	
	if not shop_ui:
		# Load and instance shop UI
		var shop_scene = load("res://Scenes/shop_ui.tscn")
		if shop_scene:
			shop_ui = shop_scene.instantiate()
			get_tree().root.add_child(shop_ui)
	
	if shop_ui and shop_ui.has_method("open_shop"):
		shop_ui.open_shop(npc_name, shop_items)
		print("Opening shop: ", npc_name)

func get_shop_items() -> Dictionary:
	return shop_items
