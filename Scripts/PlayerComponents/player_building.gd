extends Node
class_name PlayerBuilding

# Component handles all building/placement functionality

# References
var player: CharacterBody2D
var anim_sprite: AnimatedSprite2D

# Placement state
var placement_mode: bool = false
var placement_preview: Node2D = null
var current_placeable_item: String = ""
var build_mode_label: Label = null

# Placement settings
@export var grid_size: int = 16
@export var placement_radius: float = 100.0
@export var placement_cooldown_time: float = 0.2
var placement_cooldown: float = 0.0

# Placeable scenes registry
var placeable_scenes: Dictionary = {
	"saw_mill": preload("res://Scenes/saw_mill_machine.tscn"),
	"wall": preload("res://Scenes/wall.tscn"),
	"fence": null
}

func initialize(p_player: CharacterBody2D, p_anim_sprite: AnimatedSprite2D) -> void:
	"""Initialize component with references"""
	player = p_player
	anim_sprite = p_anim_sprite

func process(delta: float) -> void:
	"""Update placement cooldown"""
	if placement_cooldown > 0:
		placement_cooldown -= delta

func toggle_placement_mode() -> void:
	"""Toggle build mode on/off"""
	placement_mode = !placement_mode
	
	if placement_mode:
		_enter_build_mode()
	else:
		_exit_build_mode()

func handle_placement_input() -> void:
	"""Handle placement mode input and preview updates"""
	if not placement_mode:
		return
	
	_update_selected_item()
	_update_preview_position()
	
	# Left click to place
	if current_placeable_item != "" and Input.is_action_pressed("attack1") and placement_cooldown <= 0:
		place_object()
	
	# Right click to cancel
	if Input.is_action_just_pressed("attack2"):
		_exit_build_mode()

func place_object() -> void:
	"""Place the current placeable object at preview position"""
	if not placement_preview:
		return
	
	# Check if within range
	var distance_from_player = player.global_position.distance_to(placement_preview.global_position)
	if distance_from_player > placement_radius:
		print("Too far away to place! Get closer.")
		return
	
	# Check if position is valid
	if not _is_position_valid(placement_preview.global_position):
		print("Cannot place here - position occupied!")
		return
	
	# Remove item from inventory
	if Inventory.remove_item(current_placeable_item, 1):
		# Create actual object
		if placeable_scenes.has(current_placeable_item) and placeable_scenes[current_placeable_item] != null:
			var placed_object = placeable_scenes[current_placeable_item].instantiate()
			player.get_parent().add_child(placed_object)
			placed_object.global_position = placement_preview.global_position
			
			_enable_object_collisions(placed_object)
			
			if placed_object.has_method("place_machine"):
				placed_object.place_machine()
			
			# Track stat
			var stats = player.get_node_or_null("/root/GameStats")
			if stats:
				stats.record_item_placed(current_placeable_item)
			
			print(current_placeable_item.capitalize(), " placed!")
			placement_cooldown = placement_cooldown_time
	else:
		print("No more ", current_placeable_item, " in inventory!")
		_exit_build_mode()

func try_pickup_nearest_object() -> void:
	"""Find and pickup the closest placeable object within interaction range"""
	var pickup_range = 60.0
	var closest_object = null
	var closest_distance = pickup_range
	
	var placed_objects = player.get_tree().get_nodes_in_group("PlacedObjects")
	
	# Use lambda for filtering and sorting
	var valid_objects = placed_objects.filter(func(obj): 
		return obj.has_method("pickup_machine") and obj.is_placed
	)
	
	# Find closest using lambda
	for obj in valid_objects:
		var distance = player.global_position.distance_to(obj.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_object = obj
	
	if closest_object:
		closest_object.pickup_machine()
		# Track stat
		var stats = player.get_node_or_null("/root/GameStats")
		if stats:
			stats.record_item_picked_up()
	else:
		print("No placeable objects nearby to pick up")

# Private helper methods

func _enter_build_mode() -> void:
	"""Enter placement mode and create preview"""
	var selected_item = _get_selected_item_name()
	
	# Check if selected item is placeable
	if placeable_scenes.has(selected_item) and placeable_scenes[selected_item] != null and Inventory.get_item_count(selected_item) > 0:
		current_placeable_item = selected_item
	else:
		# Try to find first available placeable item
		current_placeable_item = _find_first_available_placeable()
	
	_create_placement_preview()
	anim_sprite.modulate = Color(0.7, 1.0, 0.7)  # Green tint
	_create_build_mode_label()
	
	print("Build mode activated")

func _exit_build_mode() -> void:
	"""Exit placement mode and cleanup"""
	placement_mode = false
	
	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null
	
	anim_sprite.modulate = Color(1, 1, 1)
	_remove_build_mode_label()
	
	# Use VFX component to show exit message
	var vfx = player.get_node_or_null("PlayerVFX")
	if vfx:
		vfx.show_requirement_text("Exited Build Mode", player.global_position)

func _create_placement_preview() -> void:
	"""Create or recreate the placement preview"""
	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null
	
	if current_placeable_item != "" and placeable_scenes.has(current_placeable_item) and placeable_scenes[current_placeable_item] != null:
		placement_preview = placeable_scenes[current_placeable_item].instantiate()
		player.get_parent().add_child(placement_preview)
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.7)
		_disable_preview_collisions(placement_preview)

func _update_selected_item() -> void:
	"""Check if selected item changed and update preview"""
	var selected_item = _get_selected_item_name()
	
	if selected_item != current_placeable_item:
		if placeable_scenes.has(selected_item) and placeable_scenes[selected_item] != null:
			if Inventory.get_item_count(selected_item) > 0:
				current_placeable_item = selected_item
				_create_placement_preview()
				print("Switched to placing: ", current_placeable_item)
			else:
				_clear_preview()
		else:
			_clear_preview()

func _update_preview_position() -> void:
	"""Update preview position and color based on validity"""
	if not placement_preview:
		return
	
	var mouse_pos = player.get_global_mouse_position()
	var snapped_pos = _snap_to_grid(mouse_pos)
	placement_preview.global_position = snapped_pos
	
	var distance_from_player = player.global_position.distance_to(snapped_pos)
	var within_range = distance_from_player <= placement_radius
	
	# Color preview based on validity using lambda for readability
	var get_preview_color = func():
		if not within_range:
			return Color(1, 1, 0.5, 0.7)  # Yellow = out of range
		elif _is_position_valid(snapped_pos):
			return Color(0.5, 1, 0.5, 0.7)  # Green = valid
		else:
			return Color(1, 0.5, 0.5, 0.7)  # Red = invalid
	
	placement_preview.modulate = get_preview_color.call()

func _snap_to_grid(pos: Vector2) -> Vector2:
	"""Snap position to grid"""
	return Vector2(
		floor(pos.x / grid_size) * grid_size + grid_size / 2.0,
		floor(pos.y / grid_size) * grid_size + grid_size / 2.0
	)

func _is_position_valid(pos: Vector2) -> bool:
	"""Check if position is valid for placement"""
	# Too close to player
	if player.global_position.distance_to(pos) < grid_size * 1.5:
		return false
	
	# Define check positions for larger objects (2x2 grid)
	var check_positions = [
		pos,
		pos + Vector2(-grid_size / 2.0, -grid_size / 2.0),
		pos + Vector2(grid_size / 2.0, -grid_size / 2.0),
		pos + Vector2(-grid_size / 2.0, grid_size / 2.0),
		pos + Vector2(grid_size / 2.0, grid_size / 2.0)
	]
	
	var check_radius = grid_size * 0.7
	
	# Check each position
	for check_pos in check_positions:
		# Check placed objects using lambda
		var placed_objects = player.get_tree().get_nodes_in_group("PlacedObjects").filter(
			func(obj): return obj != placement_preview and obj.is_placed if obj.has_method("place_machine") else true
		)
		
		for obj in placed_objects:
			if obj.global_position.distance_to(check_pos) < check_radius:
				return false
		
		# Check trees
		var trees = player.get_tree().get_nodes_in_group("Trees")
		if trees.any(func(tree): return tree.global_position.distance_to(check_pos) < grid_size * 0.8):
			return false
		
		# Check enemies
		var enemies = player.get_tree().get_nodes_in_group("Enemies")
		if enemies.any(func(enemy): return enemy.global_position.distance_to(check_pos) < grid_size * 0.8):
			return false
		
		# Physics query as additional check
		if not _check_physics_at_position(check_pos):
			return false
	
	return true

func _check_physics_at_position(pos: Vector2) -> bool:
	"""Check if position is free using physics query"""
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query, 32)
	
	for result in results:
		var body = result["collider"]
		if body == player:
			continue
		if placement_preview and (body == placement_preview or body.get_parent() == placement_preview):
			continue
		
		# Check if it's a placed object or tree
		var parent = body.get_parent()
		if (parent and (parent.is_in_group("PlacedObjects") or parent.is_in_group("Trees"))) or \
		   body.is_in_group("PlacedObjects") or body.is_in_group("Trees"):
			return false
	
	return true

func _disable_preview_collisions(node: Node) -> void:
	"""Recursively disable collisions for preview"""
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", true)
	elif node is PhysicsBody2D:
		node.set_deferred("collision_layer", 0)
		node.set_deferred("collision_mask", 0)
	
	# Use lambda for children iteration
	node.get_children().map(func(child): _disable_preview_collisions(child))

func _enable_object_collisions(node: Node) -> void:
	"""Recursively enable collisions for placed object"""
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", false)
	elif node is PhysicsBody2D:
		node.set_deferred("collision_layer", 2)
		node.set_deferred("collision_mask", 3)
	
	node.get_children().map(func(child): _enable_object_collisions(child))

func _create_build_mode_label() -> void:
	"""Create BUILD MODE UI label"""
	build_mode_label = Label.new()
	build_mode_label.text = "BUILD MODE"
	build_mode_label.add_theme_font_size_override("font_size", 24)
	build_mode_label.modulate = Color(0.5, 1, 0.5)
	build_mode_label.position = Vector2(-50, -250)
	build_mode_label.z_index = 100
	player.add_child(build_mode_label)

func _remove_build_mode_label() -> void:
	"""Remove BUILD MODE UI label"""
	if build_mode_label:
		build_mode_label.queue_free()
		build_mode_label = null

func _clear_preview() -> void:
	"""Clear placement preview"""
	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null
	current_placeable_item = ""

func _get_selected_item_name() -> String:
	"""Get currently selected item from HUD"""
	var hud = player.get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("get_selected_item"):
		var item_data = hud.get_selected_item()
		return item_data["name"]
	return ""

func _find_first_available_placeable() -> String:
	"""Find first available placeable item in inventory"""
	for item_name in placeable_scenes.keys():
		if placeable_scenes[item_name] != null and Inventory.get_item_count(item_name) > 0:
			print("Auto-selected ", item_name, " for placement")
			return item_name
	print("Build mode: No placeable items available!")
	return ""
