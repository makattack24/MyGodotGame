extends CanvasLayer

var inventory_label: Label
@onready var inventory_bar: HBoxContainer = null
@onready var health_bar: ProgressBar = $HealthBarContainer/HealthBar if has_node("HealthBarContainer/HealthBar") else null
@onready var notification_label: Label = null
@onready var controls_panel: VBoxContainer = null
@onready var minimap: Control = null
@onready var biome_label: Label = null
var equipped_icon: TextureRect = null
var equipped_name: Label = null

# Weather display
var weather_label: Label = null
var weather_icon_label: Label = null
var weather_container: HBoxContainer = null

# Preload scenes
var inventory_slot_scene = preload("res://Scenes/inventory_slot.tscn")
var minimap_scene = preload("res://Scenes/minimap.tscn")

# Maximum number of inventory slots
@export var max_inventory_slots: int = 10

# Selected slot index
var selected_slot_index: int = 0

func _ready() -> void:
	inventory_label = find_child("ItemCountList", true, false)
	inventory_bar = find_child("InventoryBar", true, false)
	# Setup notification label
	setup_notification_label()
	
	# Setup biome label
	setup_biome_label()
	
	# Setup controls panel
	setup_controls_panel()
	
	# Setup minimap
	setup_minimap()
	
	# Setup weather display
	setup_weather_display()
	
	# Assign equipped item display references after scene is fully instanced
	equipped_icon = find_child("ItemIcon", true, false)
	equipped_name = find_child("ItemName", true, false)
	
	# Create inventory slots (only if InventoryBar exists)
	if inventory_bar:
		create_inventory_slots()
		update_selected_slot()
	
	# Update display after slots are created
	update_inventory_display()
	
	# Connect the inventory_updated signal
	Inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	
	# Connect to player's health signal
	connect_player_health_signal()

func connect_player_health_signal() -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))
		# Initialize health display
		if health_bar:
			health_bar.max_value = player.max_health
			health_bar.value = player.current_health
	else:
		print("Warning: Player not found for health bar connection, will retry.")
		call_deferred("connect_player_health_signal")

func create_inventory_slots() -> void:
	if not inventory_bar:
		return
		
	# Clear existing slots
	for child in inventory_bar.get_children():
		child.queue_free()
	
	# Create new slots
	for i in range(max_inventory_slots):
		var slot = inventory_slot_scene.instantiate()
		inventory_bar.add_child(slot)
		slot.clear_slot()
		

func update_inventory_display() -> void:
	var inventory_text = ""
	for item_name in Inventory.inventory.keys():
		var item_count = Inventory.inventory[item_name]
		inventory_text += "%s: %d\n" % [item_name, item_count]
	
	inventory_label.text = inventory_text
	
	# Update inventory bar slots
	update_inventory_bar()


func update_inventory_bar() -> void:
	if not inventory_bar:
		return
		
	var slots = inventory_bar.get_children()
	
	# First, update existing slots with current counts
	for slot in slots:
		if slot.item_name != "":
			var count = Inventory.get_item_count(slot.item_name)
			if count > 0:
				# Update the count for existing items
				slot.set_item(slot.item_name, count, slot.item_texture)
			else:
				# Item count is 0, clear the slot
				slot.clear_slot()
	
	# Then, add new items to empty slots
	for item_name in Inventory.inventory.keys():
		var count = Inventory.inventory[item_name]
		if count <= 0:
			continue
			
		# Check if this item is already in a slot
		var item_found = false
		for slot in slots:
			if slot.item_name == item_name:
				item_found = true
				break
		
		# If not found, add to first empty slot
		if not item_found:
			for slot in slots:
				if slot.item_name == "":
					var texture = Inventory.get_item_texture(item_name)
					slot.set_item(item_name, count, texture)
					break
	
	# Update equipped item display
	update_equipped_display()

func _on_inventory_updated() -> void:
	update_inventory_display()

func _on_player_health_changed(current_hp: int, max_hp: int) -> void: 
	print("HUD received health_changed signal: ", current_hp, "/", max_hp)
	var bar = health_bar
	if bar == null:
		bar = find_child("HealthBar", true, false)
		if bar:
			print("HUD found health_bar node by name.")
		else:
			print("Warning: health_bar is still null after find_child.")
	if bar:
		print("HUD updating health_bar: value=", current_hp, " max_value=", max_hp)
		bar.max_value = max_hp
		bar.value = current_hp

func _input(event: InputEvent) -> void:
	if not inventory_bar:
		return
	
	# Don't handle scroll in debug mode (debug camera uses it for zoom)
	var debug_mgr = get_tree().root.find_child("DebugManager", true, false)
	if debug_mgr and debug_mgr.get("debug_enabled"):
		return
	
	# Don't handle scroll when stats panel is open
	if get_node_or_null("/root/GameStats"):
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		if pause_menu:
			var stats_panel = pause_menu.find_child("StatsPanel", true, false)
			if stats_panel and stats_panel.visible:
				return
	
	# Handle scroll wheel input for inventory selection
	# This works in all modes including build mode
	if event is InputEventMouseButton:
		var slots = inventory_bar.get_children()
		if slots.size() == 0:
			return
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# Scroll up - move to previous slot
			selected_slot_index -= 1
			if selected_slot_index < 0:
				selected_slot_index = slots.size() - 1
			update_selected_slot()
			# Accept the event to prevent other systems from processing it
			get_viewport().set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Scroll down - move to next slot
			selected_slot_index += 1
			if selected_slot_index >= slots.size():
				selected_slot_index = 0
			update_selected_slot()
			# Accept the event to prevent other systems from processing it
			get_viewport().set_input_as_handled()

func update_selected_slot() -> void:
	if not inventory_bar:
		return
	
	var slots = inventory_bar.get_children()
	for i in range(slots.size()):
		if i == selected_slot_index:
			slots[i].set_selected(true)
		else:
			slots[i].set_selected(false)
	
	# Update equipped item display
	update_equipped_display()

func get_selected_item() -> Dictionary:
	"""Returns the currently selected item {name: String, count: int}"""
	if not inventory_bar:
		return {"name": "", "count": 0}
	
	var slots = inventory_bar.get_children()
	if selected_slot_index >= 0 and selected_slot_index < slots.size():
		var slot = slots[selected_slot_index]
		return {"name": slot.item_name, "count": slot.count}
	
	return {"name": "", "count": 0}

func update_equipped_display() -> void:
	"""Update the equipped item display with currently selected item"""
	if not equipped_icon or not equipped_name:
		return
	
	var selected_item = get_selected_item()
	if selected_item["name"] != "" and selected_item["count"] > 0:
		# Show the equipped item
		var texture = Inventory.get_item_texture(selected_item["name"])
		equipped_icon.texture = texture
		equipped_name.text = selected_item["name"].capitalize()
	else:
		# No item equipped
		equipped_icon.texture = null
		equipped_name.text = "None"

func setup_weather_display() -> void:
	# Create a container for the weather info (below the biome label)
	weather_container = HBoxContainer.new()
	weather_container.name = "WeatherContainer"
	weather_container.anchor_left = 0.0
	weather_container.anchor_right = 0.0
	weather_container.anchor_top = 0.0
	weather_container.anchor_bottom = 0.0
	weather_container.offset_left = 10
	weather_container.offset_right = 250
	weather_container.offset_top = 32
	weather_container.offset_bottom = 56
	weather_container.add_theme_constant_override("separation", 4)
	add_child(weather_container)
	
	# Weather icon
	weather_icon_label = Label.new()
	weather_icon_label.name = "WeatherIcon"
	weather_icon_label.add_theme_font_size_override("font_size", 16)
	weather_icon_label.text = "☀"
	weather_container.add_child(weather_icon_label)
	
	# Weather name
	weather_label = Label.new()
	weather_label.name = "WeatherLabel"
	weather_label.add_theme_font_size_override("font_size", 14)
	weather_label.modulate = Color(0.85, 0.9, 1.0, 0.9)
	weather_label.text = "Clear"
	weather_container.add_child(weather_label)

func update_weather_display(weather_name: String, weather_icon: String) -> void:
	if weather_label:
		weather_label.text = weather_name
	if weather_icon_label:
		weather_icon_label.text = weather_icon

func setup_notification_label() -> void:
	# Create a notification label for save/load messages
	notification_label = Label.new()
	notification_label.name = "NotificationLabel"
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.modulate = Color(1, 1, 0, 0)  # Start invisible (yellow text)
	
	# Position in center of screen
	notification_label.anchor_left = 0.5
	notification_label.anchor_right = 0.5
	notification_label.anchor_top = 0.3
	notification_label.anchor_bottom = 0.3
	notification_label.offset_left = -150
	notification_label.offset_right = 150
	notification_label.offset_top = -30
	notification_label.offset_bottom = 30
	
	# Style the label
	notification_label.add_theme_font_size_override("font_size", 24)
	
	add_child(notification_label)

func setup_biome_label() -> void:
	# Create a label to display current biome
	biome_label = Label.new()
	biome_label.name = "BiomeLabel"
	biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	biome_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# Position in top-left corner
	biome_label.anchor_left = 0.0
	biome_label.anchor_right = 0.0
	biome_label.anchor_top = 0.0
	biome_label.anchor_bottom = 0.0
	biome_label.offset_left = 10
	biome_label.offset_right = 250
	biome_label.offset_top = 10
	biome_label.offset_bottom = 50
	
	# Style the label
	biome_label.add_theme_font_size_override("font_size", 18)
	biome_label.modulate = Color(0.8, 1.0, 0.8, 0.9)
	biome_label.text = "Biome: Starter Plains"
	
	add_child(biome_label)

func update_biome_display(biome_name: String) -> void:
	if biome_label:
		biome_label.text = "Biome: " + biome_name

func show_notification(message: String, duration: float = 2.0) -> void:
	if not notification_label:
		return
	
	notification_label.text = message
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	
	# Wait
	await get_tree().create_timer(duration).timeout
	
	# Fade out
	if notification_label:  # Check if still exists
		var fade_tween = create_tween()
		fade_tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)

func setup_controls_panel() -> void:
	# Create a panel to show controls
	controls_panel = VBoxContainer.new()
	controls_panel.name = "ControlsPanel"
	
	# Position in bottom-right corner
	controls_panel.anchor_left = 1.0
	controls_panel.anchor_right = 1.0
	controls_panel.anchor_top = 1.0
	controls_panel.anchor_bottom = 1.0
	controls_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	controls_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	controls_panel.offset_left = -160
	controls_panel.offset_right = -6
	controls_panel.offset_top = -6
	controls_panel.offset_bottom = -6
	controls_panel.set_custom_minimum_size(Vector2(150, 0))
	controls_panel.add_theme_constant_override("separation", 1)
	
	add_child(controls_panel)
	
	# Add title container with toggle button
	var title_container = HBoxContainer.new()
	controls_panel.add_child(title_container)
	
	# Add title
	var title = Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 11)
	title.modulate = Color(1, 1, 0.5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(title)
	
	# Add hide/show button
	var toggle_button = Button.new()
	toggle_button.text = "X"
	toggle_button.custom_minimum_size = Vector2(16, 16)
	toggle_button.add_theme_font_size_override("font_size", 9)
	toggle_button.pressed.connect(_on_toggle_controls)
	title_container.add_child(toggle_button)
	
	# Add control hints
	add_control_hint("WASD - Move")
	add_control_hint("Scroll - Select Item")
	add_control_hint("B - Build Mode")
	add_control_hint("E - Pickup")
	add_control_hint("LMB - Attack/Place")
	add_control_hint("RMB - Cancel")
	add_control_hint("Enter - Interact")

func add_control_hint(text: String) -> void:
	if not controls_panel:
		return
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.modulate = Color(0.8, 0.8, 0.8)
	controls_panel.add_child(label)

func _on_toggle_controls() -> void:
	# Toggle visibility of all controls panel children except the title
	if not controls_panel:
		return
	
	var children = controls_panel.get_children()
	var is_currently_visible = true
	
	# Check current state (skip first child which is the title container)
	if children.size() > 1:
		is_currently_visible = children[1].visible
	
	# Toggle all children except the title container
	for i in range(1, children.size()):
		children[i].visible = !is_currently_visible

func setup_minimap() -> void:
	# Create minimap instance
	if minimap_scene:
		minimap = minimap_scene.instantiate()
		if minimap:
			add_child(minimap)
			minimap.z_index = 100  # Make sure it's on top
			print("Minimap added to HUD successfully")
		else:
			print("ERROR: Failed to instantiate minimap!")
	else:
		print("ERROR: Minimap scene not loaded!")
