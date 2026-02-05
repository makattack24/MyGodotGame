extends BaseEnemy
class_name BatEnemy

## Bat enemy - uses chase movement (example of different enemy type)

func setup_components() -> void:
	# Create health component
	health = EnemyHealth.new()
	health.name = "EnemyHealth"
	add_child(health)
	
	var sprite = get_node_or_null("Sprite2D")
	health.initialize(self, sprite, enemy_data)
	
	# Create chase movement component (different from slime!)
	movement = ChaseMovement.new()
	movement.name = "ChaseMovement"
	add_child(movement)
	movement.initialize(self, enemy_data)
	
	# Bats fly, no shadow needed
	# create_shadow()  # Commented out for flying enemies
