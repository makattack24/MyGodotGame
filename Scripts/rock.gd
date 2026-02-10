extends StaticBody2D

# Rock properties
@export var item_name: String = "stone"        # Item dropped when mined
@export var item_quantity: int = 2             # Quantity of items dropped
@export var health: int = 4                    # Number of hits to destroy the rock

# PackedScene reference for the dropped item spawn
@export var item_scene: PackedScene            # Scene used for item drops

# Cooldown for handling rapid hits
var hit_cooldown_timer: float = 0.0            # Tracks cooldown timing
@export var hit_cooldown: float = 0.2          # Seconds between hits

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
		var snd = hit_sound
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(snd) and snd.playing:
				snd.stop()
		)

	# Only process damage if cooldown timer is 0
	if health > 0 and hit_cooldown_timer <= 0.0:
		health -= damage
		print("Rock hit! Remaining health: ", health)

		# Trigger cooldown timer
		hit_cooldown_timer = hit_cooldown

		# Visual feedback of damage (e.g., shaking rock)
		apply_damage_feedback()

		# Destroy rock if health is 0 or below
		if health <= 0:
			destroy_rock()

# Remove rock and drop items when destroyed
func destroy_rock() -> void:
	print("Rock destroyed! Dropping items.")
	
	# Track stat
	if get_node_or_null("/root/GameStats"):
		GameStats.record_rock_mined()
	
	call_deferred("spawn_items")  # Defer spawning to avoid physics query conflicts
	
	var scene_root = get_tree().root
	
	# Reparent hit sound to continue playing independently
	if hit_sound and hit_sound.playing:
		var snd = hit_sound
		remove_child(snd)
		scene_root.add_child(snd)
		snd.global_position = global_position
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(snd):
				snd.stop()
				snd.queue_free()
		)
	
	# Reparent particles to continue playing independently
	if hit_effect and hit_effect.emitting:
		remove_child(hit_effect)
		scene_root.add_child(hit_effect)
		hit_effect.global_position = global_position
		# Clean up particles after they finish
		get_tree().create_timer(hit_effect.lifetime).timeout.connect(func(): hit_effect.queue_free())
	
	# Remove the rock immediately - effects continue independently
	queue_free()

# Spawn items near the rock
func spawn_items() -> void:
	if item_scene:  # Ensure item_scene is properly assigned
		for i in range(item_quantity):
			var item_instance = item_scene.instantiate()  # Create item instance
			item_instance.position = position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))  # Random nearby position
			get_parent().call_deferred("add_child", item_instance)  # Defer adding to avoid physics conflicts
	else:
		print("Warning: item_scene is not assigned!")

# Feedback for being hit: Apply slight shake to the rock
func apply_damage_feedback() -> void:
	var tween = create_tween()
	# Tween X-axis shake
	tween.tween_property(self, "position:x", position.x + randf_range(-4.0, 4.0), 0.1)
	# Tween Y-axis shake
	tween.tween_property(self, "position:y", position.y + randf_range(-4.0, 4.0), 0.1)

# Track cooldown timer logic
func _process(_delta: float) -> void:
	if hit_cooldown_timer > 0.0:
		hit_cooldown_timer -= _delta

# Initialize the rock (add it to global "Rocks" group)
func _ready() -> void:
	add_to_group("Rocks")
	print("Rock added to Rocks group!")
