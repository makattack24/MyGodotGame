extends Node
class_name EnemyMovement

## Base class for enemy movement AI - extend for different behaviors

var enemy: CharacterBody2D
var data: EnemyData
var player: Node2D

var camp_position: Vector2 = Vector2.ZERO
var is_aggro: bool = false
var separation_distance: float = 20.0

func initialize(p_enemy: CharacterBody2D, p_data: EnemyData) -> void:
	enemy = p_enemy
	data = p_data
	camp_position = enemy.global_position

func set_player(p_player: Node2D) -> void:
	player = p_player

func process(_delta: float) -> void:
	_update_aggro_state()

func physics_process(_delta: float) -> void:
	# Override in derived classes
	pass

func get_direction_to_player() -> Vector2:
	if not player:
		return Vector2.ZERO
	return (player.global_position - enemy.global_position).normalized()

func get_direction_to_camp() -> Vector2:
	return (camp_position - enemy.global_position).normalized()

func get_distance_to_player() -> float:
	if not player:
		return INF
	return enemy.global_position.distance_to(player.global_position)

func get_distance_to_camp() -> float:
	return enemy.global_position.distance_to(camp_position)

func apply_separation(desired_direction: Vector2) -> Vector2:
	"""Avoid crowding with other enemies using lambda for cleaner logic"""
	var separation = Vector2.ZERO
	var nearby_count = 0
	
	var enemies = enemy.get_tree().get_nodes_in_group("Enemies").filter(
		func(e): return e != enemy and is_instance_valid(e)
	)
	
	for other_enemy in enemies:
		var distance = enemy.global_position.distance_to(other_enemy.global_position)
		if distance < separation_distance and distance > 0:
			var away = (enemy.global_position - other_enemy.global_position).normalized()
			var strength = (separation_distance - distance) / separation_distance
			separation += away * strength
			nearby_count += 1
	
	if nearby_count > 0:
		separation = separation.normalized()
		var separation_weight = min(nearby_count * 0.4, 0.8)
		return (desired_direction * (1.0 - separation_weight) + separation * separation_weight).normalized()
	
	return desired_direction

func _update_aggro_state() -> void:
	if not player:
		return
	
	var distance_to_player = get_distance_to_player()
	var distance_to_camp = get_distance_to_camp()
	
	# Determine aggro state using lambda for clarity
	var should_aggro = func() -> bool:
		if distance_to_player <= data.aggro_range:
			return true
		if distance_to_camp > data.return_home_range:
			return false
		if distance_to_player > data.aggro_range * 1.5:
			return false
		return is_aggro  # Maintain current state
	
	is_aggro = should_aggro.call()
