extends CharacterBody2D
class_name BaseEnemy

## Base enemy class - all enemies extend this
## Uses component architecture for flexibility

@export var enemy_data: EnemyData

var player: Node2D
var camp_position: Vector2

# Components
var health: EnemyHealth
var movement: EnemyMovement

# Attack state
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("Enemies")
	
	if not enemy_data:
		push_error("Enemy has no EnemyData assigned!")
		return
	
	setup_components()
	setup_player_reference()
	
	if camp_position == Vector2.ZERO:
		camp_position = global_position

func _process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if health:
		health.process(delta)
	if movement:
		movement.process(delta)

func _physics_process(delta: float) -> void:
	# Skip movement if in knockback
	if health and health.is_in_knockback():
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return
	
	if movement:
		movement.physics_process(delta)
	
	move_and_slide()
	check_player_collision()

func setup_components() -> void:
	# Override in derived classes to add specific components
	pass

func setup_player_reference() -> void:
	"""Find player in scene"""
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		if movement:
			movement.set_player(player)

func set_camp_position(pos: Vector2) -> void:
	camp_position = pos
	if movement:
		movement.camp_position = pos

func on_hit(damage: int, knockback_direction: Vector2) -> void:
	"""Called when enemy is hit by player attack"""
	if health:
		health.take_damage(damage, knockback_direction)
		
		# Reset movement state if needed
		if movement and movement.has_method("reset_to_resting"):
			movement.reset_to_resting()

func check_player_collision() -> void:
	"""Check if enemy collided with player"""
	if attack_cooldown > 0:
		return
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("Player"):
			attack_player(collider)
			break

func attack_player(player_node: Node) -> void:
	"""Attack the player"""
	if player_node.has_method("take_damage"):
		player_node.call("take_damage", enemy_data.attack_damage)
	
	# Apply knockback to enemy (bounce back)
	var knockback_dir = (global_position - player_node.global_position).normalized()
	velocity = knockback_dir * 150.0
	
	if health:
		health.knockback_timer = 0.3
	
	attack_cooldown = enemy_data.attack_cooldown
	
	# Reset movement state
	if movement and movement.has_method("reset_to_resting"):
		movement.reset_to_resting()

func create_shadow() -> Polygon2D:
	"""Create shadow sprite - call from derived classes"""
	var shadow = Polygon2D.new()
	shadow.name = "Shadow"
	
	var points = PackedVector2Array()
	var num_points = 16
	
	for i in range(num_points):
		var angle = (float(i) / num_points) * TAU
		points.append(Vector2(cos(angle) * 10, sin(angle) * 5))
	
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.5)
	shadow.position = Vector2(0, 6)
	
	var sprite = get_node_or_null("Sprite2D")
	add_child(shadow)
	if sprite:
		move_child(shadow, 0)
	
	return shadow

# Public interface for external scripts

func _on_hit(damage: int, knockback_direction: Vector2) -> void:
	"""Legacy interface for existing code"""
	on_hit(damage, knockback_direction)
