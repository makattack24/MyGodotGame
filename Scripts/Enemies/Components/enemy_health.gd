extends Node
class_name EnemyHealth

## Component handles enemy health, damage, and death

signal health_changed(current_hp, max_hp)
signal died

var enemy: CharacterBody2D
var sprite: Node2D
var data: EnemyData

var current_health: int
var knockback_timer: float = 0.0

# VFX references
var hit_effect: CPUParticles2D
var death_effect: CPUParticles2D
var hit_sound: AudioStreamPlayer2D
var death_sound: AudioStreamPlayer2D

func initialize(p_enemy: CharacterBody2D, p_sprite: Node2D, p_data: EnemyData) -> void:
	enemy = p_enemy
	sprite = p_sprite
	data = p_data
	current_health = data.max_health
	
	# Get effect nodes
	hit_effect = enemy.get_node_or_null("HitEffect")
	death_effect = enemy.get_node_or_null("DeathEffect")
	hit_sound = enemy.get_node_or_null("HitSound")
	death_sound = enemy.get_node_or_null("DeathSound")

func process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta

func take_damage(damage: int, knockback_direction: Vector2) -> void:
	current_health -= damage
	emit_signal("health_changed", current_health, data.max_health)
	
	# Apply knockback
	enemy.velocity = knockback_direction.normalized() * data.knockback_strength
	knockback_timer = 0.4
	
	# Visual feedback using lambda
	_show_damage_effect()
	_show_damage_text(damage)
	_play_hit_feedback()
	
	if current_health <= 0:
		die()

func die() -> void:
	emit_signal("died")
	
	# Drop loot
	_drop_coins()
	_drop_heart()
	
	# Handle death effects
	_reparent_effect(death_effect, func(effect): effect.emitting = true)
	_reparent_sound(hit_sound)
	_reparent_sound(death_sound, true)
	
	# Remove enemy
	enemy.queue_free()

func is_in_knockback() -> bool:
	return knockback_timer > 0

# Private methods

func _show_damage_effect() -> void:
	if not sprite:
		return
	
	var original_scale = sprite.scale
	sprite.scale = original_scale * Vector2(0.8, 1.2)
	
	var tween = enemy.create_tween()
	tween.tween_property(sprite, "scale", original_scale, 0.15)

func _show_damage_text(damage: int) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree:
		return
	
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.modulate = data.hit_color
	damage_label.z_index = 100
	damage_label.position = enemy.global_position + Vector2(-15, -40)
	
	tree.root.add_child(damage_label)
	
	var tween = damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): damage_label.queue_free())

func _play_hit_feedback() -> void:
	if hit_sound:
		hit_sound.play()
	if hit_effect:
		hit_effect.restart()
		hit_effect.emitting = true

func _drop_coins() -> void:
	if randf() > data.coin_drop_chance:
		return
	
	var coin_scene = load("res://Scenes/coin_item.tscn")
	var num_coins = randi_range(data.min_coins, data.max_coins)
	
	for i in range(num_coins):
		var coin = coin_scene.instantiate()
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		coin.global_position = enemy.global_position + offset
		enemy.get_parent().add_child.call_deferred(coin)

func _drop_heart() -> void:
	if randf() > data.heart_drop_chance:
		return
	
	var heart_scene = load("res://Scenes/heart_item.tscn")
	var heart = heart_scene.instantiate()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	heart.global_position = enemy.global_position + offset
	enemy.get_parent().add_child.call_deferred(heart)

func _reparent_effect(effect: CPUParticles2D, callback: Callable = Callable()) -> void:
	if not effect or not is_instance_valid(effect) or effect.get_parent() != enemy:
		return
	
	var scene_root = enemy.get_tree().root
	var effect_position = effect.global_position
	
	enemy.remove_child(effect)
	scene_root.add_child(effect)
	effect.global_position = effect_position
	
	if callback.is_valid():
		callback.call(effect)
	
	var cleanup_time = effect.lifetime + 0.5
	enemy.get_tree().create_timer(cleanup_time).timeout.connect(
		func(): if is_instance_valid(effect): effect.queue_free()
	)

func _reparent_sound(sound: AudioStreamPlayer2D, play: bool = false) -> void:
	if not sound or sound.get_parent() != enemy:
		return
	
	var scene_root = enemy.get_tree().root
	enemy.remove_child(sound)
	scene_root.add_child(sound)
	sound.global_position = enemy.global_position
	
	if play and sound.stream:
		sound.play()
	
	sound.finished.connect(func(): sound.queue_free())
