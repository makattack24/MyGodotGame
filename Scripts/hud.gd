extends CanvasLayer

var inventory_label: Label
@onready var inventory_bar: HBoxContainer = $InventoryBar if has_node("InventoryBar") else null
@onready var health_bar: ProgressBar = $HealthBarContainer/HealthBar if has_node("HealthBarContainer/HealthBar") else null
@onready var health_label: Label = $HealthBarContainer/HealthLabel if has_node("HealthBarContainer/HealthLabel") else null

# Preload the inventory slot scene
var inventory_slot_scene = preload("res://Scenes/inventory_slot.tscn")

# Maximum number of inventory slots
@export var max_inventory_slots: int = 10

# Selected slot index
var selected_slot_index: int = 0

func _ready() -> void:
	inventory_label = $HBoxContainer/WoodCount
	
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
		
	var slot_index = 0
	var slots = inventory_bar.get_children()
	
	# Update slots with items
	for item_name in Inventory.inventory.keys():
		var count = Inventory.inventory[item_name]
		if count > 0 and slot_index < slots.size():
			var texture = Inventory.get_item_texture(item_name)
			slots[slot_index].set_item(item_name, count, texture)
			slot_index += 1
	
	# Clear remaining slots
	while slot_index < slots.size():
		slots[slot_index].clear_slot()
		slot_index += 1

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
