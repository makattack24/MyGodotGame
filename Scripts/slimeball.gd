extends Node2D

# Item pickup properties
@export var item_name: String = "slimeball"
@export var pickup_amount: int = 1

# Reference to child nodes
@onready var pickup_area: Area2D = $Area2D
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var sprite: Sprite2D = $Sprite2D

# Drop animation
var drop_velocity: Vector2 = Vector2.ZERO
var is_settling: bool = true
var settle_timer: float = 0.0

func _ready() -> void:
	# Connect the pickup area signal
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	
	# Disable pickup briefly so the slimeball can settle first
	if pickup_area:
		pickup_area.set_deferred("monitoring", false)
	
	# Start with a random drop velocity for a scatter effect
	drop_velocity = Vector2(randf_range(-40, 40), randf_range(-60, -20))
	settle_timer = 0.4

func _process(delta: float) -> void:
	if is_settling:
		# Apply gravity and friction to the drop
		drop_velocity.y += 200.0 * delta
		drop_velocity.x = lerp(drop_velocity.x, 0.0, 5.0 * delta)
		position += drop_velocity * delta
		
		settle_timer -= delta
		if settle_timer <= 0:
			is_settling = false
			drop_velocity = Vector2.ZERO
			# Enable pickup after settling
			if pickup_area:
				pickup_area.set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		pickup_item()

func pickup_item() -> void:
	# Show floating text
	Inventory.show_pickup_text(item_name, pickup_amount, global_position)
	
	# Add to inventory
	Inventory.add_item(item_name, pickup_amount)
	
	# Track stat
	if get_node_or_null("/root/GameStats"):
		GameStats.record_item_collected("slimeball")
	
	# Play pickup sound then remove
	if pickup_sound and pickup_sound.stream:
		sprite.visible = false
		pickup_area.set_deferred("monitoring", false)
		pickup_sound.play()
		await pickup_sound.finished
		queue_free()
	else:
		queue_free()
