extends CanvasLayer

## Card Library UI — displays all unique cards, discovered ones are revealed,
## undiscovered ones shown as silhouettes. Opened from the pause menu.

signal closed

const CARD_DATA_DIR: String = "res://Resources/CardData/"

var all_card_data: Array[CardData] = []

func _ready() -> void:
	visible = false
	_load_all_card_data()

func _load_all_card_data() -> void:
	"""Scan the CardData directory and load every .tres resource."""
	all_card_data.clear()
	var dir = DirAccess.open(CARD_DATA_DIR)
	if not dir:
		push_warning("[CardLibrary] Could not open: " + CARD_DATA_DIR)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(CARD_DATA_DIR.path_join(file_name))
			if res is CardData:
				all_card_data.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort alphabetically by card_name for consistent order
	all_card_data.sort_custom(func(a, b): return a.card_name < b.card_name)

func show_library() -> void:
	_refresh_grid()
	visible = true

func hide_library() -> void:
	visible = false

func _refresh_grid() -> void:
	"""Rebuild the card grid based on current discovery state."""
	var grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
	# Clear previous entries
	for child in grid.get_children():
		child.queue_free()

	var card_scene: PackedScene = SceneRegistry.get_scene("card")

	for data in all_card_data:
		var discovered: bool = Inventory.is_card_discovered(data.card_name)

		# Container for each card slot
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(80, 110)

		if discovered and card_scene:
			# Show the actual card
			var sub = SubViewportContainer.new()
			sub.custom_minimum_size = Vector2(80, 110)
			sub.stretch = true
			slot.add_child(sub)

			var vp = SubViewport.new()
			vp.size = Vector2i(80, 110)
			vp.transparent_bg = true
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			sub.add_child(vp)

			var card_inst = card_scene.instantiate()
			card_inst.position = Vector2(40, 55)  # Center in viewport
			# Disable pickup collision in library view
			var area = card_inst.get_node_or_null("Area2D")
			if area:
				area.queue_free()
			vp.add_child(card_inst)
			# Apply card data after adding to tree
			card_inst.set_card_data_resource(data)
		else:
			# Undiscovered — show silhouette placeholder
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			slot.add_child(vbox)

			var icon = Label.new()
			icon.text = "?"
			icon.add_theme_font_size_override("font_size", 28)
			icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
			icon.modulate = Color(0.4, 0.4, 0.4)
			vbox.add_child(icon)

			var name_label = Label.new()
			name_label.text = "???"
			name_label.add_theme_font_size_override("font_size", 8)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.modulate = Color(0.5, 0.5, 0.5)
			vbox.add_child(name_label)

		grid.add_child(slot)

	# Update counter
	var counter: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/CounterLabel
	var discovered_count: int = Inventory.get_discovered_card_names().size()
	counter.text = "%d / %d" % [discovered_count, all_card_data.size()]

func _on_close_pressed() -> void:
	hide_library()
	closed.emit()
