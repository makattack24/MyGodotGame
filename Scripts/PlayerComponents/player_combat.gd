extends Node
class_name PlayerCombat

# Component handles all combat-related functionality

# References
var player: CharacterBody2D
var anim_sprite: AnimatedSprite2D
var attack_area: Area2D
var weapon_sprite: Sprite2D
var damage_sound: AudioStreamPlayer2D

# Weapon data
var axe_texture = preload("res://Assets/WoodAxe.png")
var pickaxe_texture = preload("res://Assets/pickaxe.png")
var sword_remover_material: ShaderMaterial = null

# Attack state
var is_attacking: bool = false
var attack_cooldown: float = 0.0
@export var attack_cooldown_time: float = 0.55
@export var attack_offsets: Dictionary = {
	"up": Vector2(0, -16),
	"down": Vector2(0, 16),
	"left": Vector2(-16, 0),
	"right": Vector2(16, 0)
}

func _ready() -> void:
	# Load sword remover shader
	var sword_shader = load("res://Shaders/sword_remover.gdshader")
	if sword_shader:
		sword_remover_material = ShaderMaterial.new()
		sword_remover_material.shader = sword_shader

func _process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

func initialize(p_player: CharacterBody2D, p_anim_sprite: AnimatedSprite2D, p_attack_area: Area2D) -> void:
	"""Initialize component with references to player nodes"""
	player = p_player
	anim_sprite = p_anim_sprite
	attack_area = p_attack_area
	
	# Create weapon sprite
	weapon_sprite = Sprite2D.new()
	weapon_sprite.visible = false
	weapon_sprite.z_index = 10
	player.add_child(weapon_sprite)
	
	# Get damage sound if it exists
	if player.has_node("DamageSound"):
		damage_sound = player.get_node("DamageSound")
	
	# Setup attack area
	if attack_area:
		attack_area.body_entered.connect(_on_attack_hit)
		attack_area.monitoring = false
		attack_area.visible = false
	
	# Connect animation finished signal using lambda
	anim_sprite.animation_finished.connect(func(): _on_animation_finished())

func trigger_attack(attack_type: String, facing_direction: String) -> void:
	"""Trigger an attack animation"""
	if is_attacking or attack_cooldown > 0:
		return
	is_attacking = true
	attack_cooldown = attack_cooldown_time

	# Get currently selected item from HUD
	var selected_item = _get_selected_item_name()
	
	# Check if player is holding axe or pickaxe and show weapon sprite
	if selected_item == "axe":
		weapon_sprite.texture = axe_texture
		weapon_sprite.visible = true
		update_weapon_position(facing_direction)
		if sword_remover_material:
			anim_sprite.material = sword_remover_material
	elif selected_item == "pickaxe":
		weapon_sprite.texture = pickaxe_texture
		weapon_sprite.visible = true
		update_weapon_position(facing_direction)
		if sword_remover_material:
			anim_sprite.material = sword_remover_material

	# Speed up attack animation
	anim_sprite.speed_scale = 2.0
	anim_sprite.play(attack_type + "_" + facing_direction)

	# Update attack hitbox position
	update_attack_hitbox(facing_direction)

	# Enable attack collision detection
	attack_area.visible = true
	attack_area.monitoring = true

func update_weapon_position(facing_direction: String) -> void:
	"""Position and rotate weapon sprite based on facing direction"""
	match facing_direction:
		"right":
			weapon_sprite.position = Vector2(20, 0)
			weapon_sprite.rotation_degrees = -45
			weapon_sprite.flip_h = false
		"left":
			weapon_sprite.position = Vector2(-20, 0)
			weapon_sprite.rotation_degrees = 45
			weapon_sprite.flip_h = true
		"down":
			weapon_sprite.position = Vector2(0, 20)
			weapon_sprite.rotation_degrees = 45
			weapon_sprite.flip_h = false
		"up":
			weapon_sprite.position = Vector2(0, -20)
			weapon_sprite.rotation_degrees = -135
			weapon_sprite.flip_h = false

func update_attack_hitbox(facing_direction: String) -> void:
	"""Update attack hitbox position based on facing direction"""
	if attack_offsets.has(facing_direction):
		attack_area.position = attack_offsets[facing_direction]

func _on_animation_finished() -> void:
	"""Reset attack state after animation finishes"""
	is_attacking = false
	anim_sprite.speed_scale = 1.0
	weapon_sprite.visible = false
	anim_sprite.material = null
	attack_area.visible = false
	attack_area.monitoring = false

func _on_attack_hit(body: Node) -> void:
	"""Handle collision when attack hits something"""
	# Walk up the node hierarchy to find the root entity
	while body and not body.is_in_group("Trees") and not body.is_in_group("Enemies") and not body.is_in_group("Rocks") and body.get_parent() != null:
		body = body.get_parent()

	if not is_attacking:
		return

	if body.is_in_group("Enemies"):
		_handle_enemy_hit(body)
	elif body.is_in_group("Trees"):
		_handle_tree_hit(body)
	elif body.is_in_group("Rocks"):
		_handle_rock_hit(body)
	elif body.is_in_group("Bushes"):
		_handle_bush_hit(body)

func _handle_enemy_hit(enemy: Node) -> void:
	"""Apply damage and knockback to enemy"""
	if enemy.has_method("_on_hit"):
		var knockback_direction = (enemy.global_position - attack_area.global_position).normalized()
		enemy.call("_on_hit", 1, knockback_direction)
		# Track stat
		var stats = player.get_node_or_null("/root/GameStats")
		if stats:
			stats.record_damage_dealt(1)

func _handle_tree_hit(tree: Node) -> void:
	"""Handle hitting a tree (requires axe)"""
	var has_axe_equipped = _get_selected_item_name() == "axe"
	
	if has_axe_equipped:
		if tree.has_method("take_damage"):
			tree.call("take_damage", 1)
		else:
			tree.queue_free()
	else:
		# Use player's VFX component to show requirement
		var vfx = player.get_node_or_null("PlayerVFX")
		if vfx:
			vfx.show_requirement_text("Need Axe!", tree.global_position)
			vfx.flash_screen_orange()

func _handle_rock_hit(rock: Node) -> void:
	"""Handle hitting a rock (requires pickaxe)"""
	var has_pickaxe_equipped = _get_selected_item_name() == "pickaxe"
	
	if has_pickaxe_equipped:
		if rock.has_method("take_damage"):
			rock.call("take_damage", 1)
		else:
			rock.queue_free()
	else:
		# Use player's VFX component to show requirement
		var vfx = player.get_node_or_null("PlayerVFX")
		if vfx:
			vfx.show_requirement_text("Need Pickaxe!", rock.global_position)
			vfx.flash_screen_orange()

func _handle_bush_hit(bush: Node) -> void:
	"""Destroy bush on hit"""
	if bush.has_method("destroy"):
		bush.call("destroy")

func _get_selected_item_name() -> String:
	"""Get currently selected item from HUD"""
	var hud = player.get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("get_selected_item"):
		var item_data = hud.get_selected_item()
		return item_data["name"]
	return ""
