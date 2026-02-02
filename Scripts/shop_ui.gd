extends CanvasLayer

# UI References
@onready var panel: Panel = $Panel
@onready var shop_title: Label = $Panel/VBoxContainer/ShopTitle
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemsContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var coin_label: Label = $Panel/VBoxContainer/CoinLabel

# Shop data
var current_shop_name: String = ""
var current_shop_items: Dictionary = {}

func _ready() -> void:
	# Hide shop initially
	visible = false
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Pause game when shop is open
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Close shop with ESC key
	if visible and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()

func open_shop(shop_name: String, shop_items: Dictionary) -> void:
	current_shop_name = shop_name
	current_shop_items = shop_items
	
	# Update shop title
	if shop_title:
		shop_title.text = shop_name + "'s Shop"
	
	# Update coin display
	update_coin_display()
	
	# Clear previous items
	if items_container:
		for child in items_container.get_children():
			child.queue_free()
	
	# Create shop items
	create_shop_items()
	
	# Show and pause
	visible = true
	get_tree().paused = true

func close_shop() -> void:
	visible = false
	get_tree().paused = false

func create_shop_items() -> void:
	if not items_container:
		return
	
	# Create an item entry for each shop item
	for item_name in current_shop_items.keys():
		var price = current_shop_items[item_name]
		create_item_entry(item_name, price)

func create_item_entry(item_name: String, price: int) -> void:
	# Create horizontal container for this item
	var item_hbox = HBoxContainer.new()
	item_hbox.custom_minimum_size = Vector2(0, 40)
	
	# Item icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = Inventory.get_item_texture(item_name)
	if texture:
		icon.texture = texture
	item_hbox.add_child(icon)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item_name.capitalize()
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_hbox.add_child(name_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(spacer)
	
	# Price label
	var price_label = Label.new()
	price_label.text = str(price) + " coins"
	price_label.custom_minimum_size = Vector2(80, 0)
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_hbox.add_child(price_label)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(60, 0)
	buy_button.pressed.connect(_on_buy_button_pressed.bind(item_name, price, buy_button))
	item_hbox.add_child(buy_button)
	
	# Add to container
	items_container.add_child(item_hbox)

func _on_buy_button_pressed(item_name: String, price: int, button: Button) -> void:
	# Check if player has enough coins
	var coin_count = Inventory.get_item_count("coin")
	
	if coin_count >= price:
		# Remove coins
		Inventory.remove_item("coin", price)
		# Add purchased item
		Inventory.add_item(item_name, 1)
		
		# Update coin display
		update_coin_display()
		
		# Show feedback
		show_purchase_feedback(item_name, true, button)
		
		print("Purchased ", item_name, " for ", price, " coins")
	else:
		# Not enough coins
		show_purchase_feedback(item_name, false, button)
		print("Not enough coins! Need ", price, " but only have ", coin_count)

func update_coin_display() -> void:
	if coin_label:
		var coin_count = Inventory.get_item_count("coin")
		coin_label.text = "Your Coins: " + str(coin_count)

func show_purchase_feedback(item_name: String, success: bool, button: Button) -> void:
	# Visual feedback on the button
	var original_text = button.text
	var original_color = button.modulate
	
	if success:
		button.text = "Bought!"
		button.modulate = Color.GREEN
	else:
		button.text = "No Coins!"
		button.modulate = Color.RED
	
	button.disabled = true
	
	# Reset after delay
	await get_tree().create_timer(0.5).timeout
	button.text = original_text
	button.modulate = original_color
	button.disabled = false

func _on_close_button_pressed() -> void:
	close_shop()
