extends EnemyMovement
class_name ChaseMovement

## Simple chase movement - walks toward player

@export var walk_speed_multiplier: float = 1.0

var sprite: Node2D

func initialize(p_enemy: CharacterBody2D, p_data: EnemyData) -> void:
	super.initialize(p_enemy, p_data)
	sprite = enemy.get_node_or_null("Sprite2D")

func physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO
	
	if is_aggro and player:
		direction = get_direction_to_player()
	else:
		var distance_to_camp = get_distance_to_camp()
		if distance_to_camp > 10.0:
			direction = get_direction_to_camp()
		else:
			# Idle at camp
			direction = Vector2.ZERO
	
	# Apply separation
	if direction != Vector2.ZERO:
		direction = apply_separation(direction)
	
	# Set velocity
	enemy.velocity = direction * data.move_speed * walk_speed_multiplier
	
	# Flip sprite based on direction
	if sprite and direction.x != 0:
		sprite.flip_h = direction.x < 0
