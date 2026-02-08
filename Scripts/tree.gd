extends Node2D

# Tree properties
@export var item_name: String = "wood"         # Item dropped
@export var item_quantity: int = 1            # Quantity of items dropped
@export var health: int = 3                   # Number of hits to destroy the tree

# PackedScene reference for the dropped item spawn
@export var item_scene: PackedScene           # Scene used for item drops

# Cooldown for handling rapid hits
var hit_cooldown_timer: float = 0.0           # Tracks cooldown timing
@export var hit_cooldown: float = 0.2         # Seconds between hits

# Hit visual and audio feedback
@onready var hit_effect: CPUParticles2D = $HitEffect  # Particle effect
@onready var hit_sound: AudioStreamPlayer2D = $HitSound  # Sound effect

# Process being hit
func take_damage(damage: int) -> void:
	# Always play hit effect and sound for feedback
	if hit_effect:
		hit_effect.restart()
	if hit_sound:
		hit_sound.play()

	# Only process damage if cooldown timer is 0
	if health > 0 and hit_cooldown_timer <= 0.0:
		health -= damage
		print("Tree hit! Remaining health: ", health)

		# Trigger cooldown timer
		hit_cooldown_timer = hit_cooldown

		# Visual feedback of damage (e.g., shaking tree)
		apply_damage_feedback()

		# Destroy tree if health is 0 or below
		if health <= 0:
			destroy_tree()

# Remove tree and drop items when destroyed
func destroy_tree() -> void:
	print("Tree destroyed! Dropping items.")
	
	# Track stat
	if get_node_or_null("/root/GameStats"):
		GameStats.record_tree_chopped()
	
	call_deferred("spawn_items")  # Defer spawning to avoid physics query conflicts
	
	var scene_root = get_tree().root
	
	# Reparent hit sound to continue playing independently
	if hit_sound and hit_sound.playing:
		remove_child(hit_sound)
		scene_root.add_child(hit_sound)
		hit_sound.global_position = global_position
		hit_sound.finished.connect(func(): hit_sound.queue_free())
	
	# Reparent particles to continue playing independently
	if hit_effect and hit_effect.emitting:
		remove_child(hit_effect)
		scene_root.add_child(hit_effect)
		hit_effect.global_position = global_position
		# Clean up particles after they finish
		get_tree().create_timer(hit_effect.lifetime).timeout.connect(func(): hit_effect.queue_free())
	
	# Remove the tree immediately - effects continue independently
	queue_free()

# Spawn items near the tree
func spawn_items() -> void:
	if item_scene:  # Ensure item_scene is properly assigned
		for i in range(item_quantity):
			var item_instance = item_scene.instantiate()  # Create item instance
			item_instance.position = position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))  # Random nearby position
			get_parent().call_deferred("add_child", item_instance)  # Defer adding to avoid physics conflicts
	else:
		print("Warning: item_scene is not assigned!")

# Feedback for being hit: Apply slight shake to the tree
func apply_damage_feedback() -> void:
	var tween = create_tween()  # Create a tween using Godot 4.6 API
	# Tween X-axis shake
	tween.tween_property(self, "position:x", position.x + randf_range(-4.0, 4.0), 0.1)

	# Tween Y-axis shake
	tween.tween_property(self, "position:y", position.y + randf_range(-4.0, 4.0), 0.1)

# Track cooldown timer logic (_process)
func _process(_delta: float) -> void:  # Prefix delta with underscore since it is unused
	if hit_cooldown_timer > 0.0:
		hit_cooldown_timer -= _delta  # Reduce cooldown timer by delta

# Initialize the tree (add it to global "Trees" group)
func _ready() -> void:
	add_to_group("Trees")
	print("Tree added to Trees group!")  # Debugging output
