extends Node

# GameStats Autoload - Tracks all player statistics across the game session

# Play time
var play_time_seconds: float = 0.0

# Combat stats
var enemies_killed: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0
var deaths: int = 0

# Resource stats
var trees_chopped: int = 0
var rocks_mined: int = 0
var bushes_destroyed: int = 0
var items_collected: int = 0
var coins_collected: int = 0
var hearts_collected: int = 0

# Building stats
var items_placed: int = 0
var walls_placed: int = 0
var items_picked_up: int = 0

# Distance
var distance_traveled: float = 0.0
var _last_player_position: Vector2 = Vector2.ZERO
var _tracking_distance: bool = false

func _process(delta: float) -> void:
	# Always count play time (even when paused is handled by process_mode)
	play_time_seconds += delta
	
	# Track distance traveled
	_track_distance()

func _track_distance() -> void:
	var player = _get_player()
	if player == null:
		_tracking_distance = false
		return
	
	if not _tracking_distance:
		_last_player_position = player.global_position
		_tracking_distance = true
		return
	
	var current_pos = player.global_position
	distance_traveled += _last_player_position.distance_to(current_pos)
	_last_player_position = current_pos

func _get_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		return players[0]
	return null

# --- Stat recording helpers ---

func record_enemy_killed() -> void:
	enemies_killed += 1

func record_damage_dealt(amount: int) -> void:
	damage_dealt += amount

func record_damage_taken(amount: int) -> void:
	damage_taken += amount

func record_player_death() -> void:
	deaths += 1

func record_tree_chopped() -> void:
	trees_chopped += 1

func record_rock_mined() -> void:
	rocks_mined += 1

func record_bush_destroyed() -> void:
	bushes_destroyed += 1

func record_item_collected(item_name: String) -> void:
	items_collected += 1
	match item_name:
		"coin":
			coins_collected += 1
		"heart":
			hearts_collected += 1

func record_item_placed(item_name: String) -> void:
	items_placed += 1
	if item_name == "wall":
		walls_placed += 1

func record_item_picked_up() -> void:
	items_picked_up += 1

# --- Formatted getters ---

func get_play_time_formatted() -> String:
	var total_seconds = int(play_time_seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	if hours > 0:
		return "%dh %02dm %02ds" % [hours, minutes, seconds]
	else:
		return "%dm %02ds" % [minutes, seconds]

func get_distance_formatted() -> String:
	if distance_traveled >= 1000.0:
		return "%.1fk units" % (distance_traveled / 1000.0)
	return "%d units" % int(distance_traveled)

# --- Save / Load ---

func save() -> Dictionary:
	return {
		"play_time_seconds": play_time_seconds,
		"enemies_killed": enemies_killed,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"deaths": deaths,
		"trees_chopped": trees_chopped,
		"rocks_mined": rocks_mined,
		"bushes_destroyed": bushes_destroyed,
		"items_collected": items_collected,
		"coins_collected": coins_collected,
		"hearts_collected": hearts_collected,
		"items_placed": items_placed,
		"walls_placed": walls_placed,
		"items_picked_up": items_picked_up,
		"distance_traveled": distance_traveled,
	}

func load_data(data: Dictionary) -> void:
	play_time_seconds = data.get("play_time_seconds", 0.0)
	enemies_killed = data.get("enemies_killed", 0)
	damage_dealt = data.get("damage_dealt", 0)
	damage_taken = data.get("damage_taken", 0)
	deaths = data.get("deaths", 0)
	trees_chopped = data.get("trees_chopped", 0)
	rocks_mined = data.get("rocks_mined", 0)
	bushes_destroyed = data.get("bushes_destroyed", 0)
	items_collected = data.get("items_collected", 0)
	coins_collected = data.get("coins_collected", 0)
	hearts_collected = data.get("hearts_collected", 0)
	items_placed = data.get("items_placed", 0)
	walls_placed = data.get("walls_placed", 0)
	items_picked_up = data.get("items_picked_up", 0)
	distance_traveled = data.get("distance_traveled", 0.0)

func reset() -> void:
	play_time_seconds = 0.0
	enemies_killed = 0
	damage_dealt = 0
	damage_taken = 0
	deaths = 0
	trees_chopped = 0
	rocks_mined = 0
	bushes_destroyed = 0
	items_collected = 0
	coins_collected = 0
	hearts_collected = 0
	items_placed = 0
	walls_placed = 0
	items_picked_up = 0
	distance_traveled = 0.0
	_tracking_distance = false
