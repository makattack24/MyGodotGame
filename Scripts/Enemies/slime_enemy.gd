extends BaseEnemy
class_name SlimeEnemy

## Slime enemy - uses hopping movement

func setup_components() -> void:
	# Create health component
	health = EnemyHealth.new()
	health.name = "EnemyHealth"
	add_child(health)
	
	var sprite = get_node_or_null("Sprite2D")
	health.initialize(self, sprite, enemy_data)
	
	# Create slime hop movement component
	movement = SlimeHopMovement.new()
	movement.name = "SlimeHopMovement"
	add_child(movement)
	movement.initialize(self, enemy_data)
	
	# Create shadow
	create_shadow()
