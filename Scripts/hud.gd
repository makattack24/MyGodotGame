extends CanvasLayer

var inventory_label: Label
@onready var inventory_bar: HBoxContainer = $InventoryBar if has_node("InventoryBar") else null
@onready var health_bar: ProgressBar = $HealthBarContainer/HealthBar if has_node("HealthBarContainer/HealthBar") else null
@onready var health_label: Label = $HealthBarContainer/HealthLabel if has_node("HealthBarContainer/HealthLabel") else null
@onready var notification_label: Label = null
@onready var controls_panel: VBoxContainer = null

# Preload the inventory slot scene
var inventory_slot_scene = preload("res://Scenes/inventory_slot.tscn")

# Maximum number of inventory slots
@export var max_inventory_slots: int = 10

# Selected slot index
var selected_slot_index: int = 0

func _ready() -> void:
	inventory_label = $HBoxContainer/WoodCount
	
	# Setup notification label
	setup_notification_label()
	
	# Setup controls panel
	setup_controls_panel()
	
	# Create inventory slots (only if InventoryBar exists)
	if inventory_bar:
		create_inventory_slots()
		update_selected_slot()
	
	# Update display after slots are created
	update_inventory_display()
	
	# Connect the inventory_updated signal
	Inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	
	# Connect to player's health signal
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))
		# Initialize health display
		if health_bar and health_label:
			health_bar.max_value = player.max_health
			health_bar.value = player.current_health
			health_label.text = "%d / %d" % [player.current_health, player.max_health]
	else:
		print("Warning: Player not found for health bar connection")

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

func _on_inventory_updated() -> void:
	update_inventory_display()

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	print("Health changed: ", current_hp, " / ", max_hp)  # Debug
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	else:
		print("Warning: health_bar is null")
	
	if health_label:
		health_label.text = "%d / %d" % [current_hp, max_hp]
	else:
		print("Warning: health_label is null")

func _input(event: InputEvent) -> void:
	if not inventory_bar:
		return
	
	# Handle scroll wheel input
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
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Scroll down - move to next slot
			selected_slot_index += 1
			if selected_slot_index >= slots.size():
				selected_slot_index = 0
			update_selected_slot()

func update_selected_slot() -> void:
	if not inventory_bar:
		return
	
	var slots = inventory_bar.get_children()
	for i in range(slots.size()):
		if i == selected_slot_index:
			slots[i].set_selected(true)
		else:
			slots[i].set_selected(false)

func get_selected_item() -> Dictionary:
	"""Returns the currently selected item {name: String, count: int}"""
	if not inventory_bar:
		return {"name": "", "count": 0}
	
	var slots = inventory_bar.get_children()
	if selected_slot_index >= 0 and selected_slot_index < slots.size():
		var slot = slots[selected_slot_index]
		return {"name": slot.item_name, "count": slot.count}
	
	return {"name": "", "count": 0}

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
	controls_panel.offset_left = -195
	controls_panel.offset_right = -5
	controls_panel.offset_top = -220
	controls_panel.offset_bottom = -10
	
	add_child(controls_panel)
	
	# Add title
	var title = Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(1, 1, 0.5)
	controls_panel.add_child(title)
	
	# Add separator
	var separator = Label.new()
	separator.text = "─────────────"
	separator.modulate = Color(0.5, 0.5, 0.5)
	controls_panel.add_child(separator)
	
	# Add control hints
	add_control_hint("WASD - Move")
	add_control_hint("Mouse Wheel - Select Item")
	add_control_hint("B - Toggle Build Mode")
	add_control_hint("E - Pickup Placed Items")
	add_control_hint("Left Click - Attack/Place")
	add_control_hint("Right Click - Cancel Build")
	add_control_hint("Enter - Interact")

func add_control_hint(text: String) -> void:
	if not controls_panel:
		return
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(0.9, 0.9, 0.9)
	controls_panel.add_child(label)
