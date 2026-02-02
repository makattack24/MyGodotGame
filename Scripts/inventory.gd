extends Node

signal inventory_updated  # Signal emitted when inventory is updated

var inventory: Dictionary = {
    "wood": 0,
    "coin": 0,
    "axe": 1,  # Start with 1 axe
    "saw_mill": 400  # Start with 1 saw mill for testing
}

# Item textures - add your item textures here
var item_textures: Dictionary = {
    "wood": preload("res://Assets/woodItem.png"),
    "coin": preload("res://Assets/coin.png"),
    "axe": preload("res://Assets/WoodAxe.png"),
    "saw_mill": preload("res://Assets/saw mill machine.png")
}

func _ready() -> void:
    # Add to persist group for saving/loading
    add_to_group("persist")

func add_item(item_name: String, amount: int = 1) -> void:
    if inventory.has(item_name):
        inventory[item_name] += amount
    else:
        inventory[item_name] = amount

    print("Added ", amount, " ", item_name, " to inventory. New count: ", inventory[item_name])
    emit_signal("inventory_updated")

func remove_item(item_name: String, amount: int = 1) -> bool:
    if inventory.has(item_name) and inventory[item_name] >= amount:
        inventory[item_name] -= amount
        emit_signal("inventory_updated")
        return true
    return false

func get_item_count(item_name: String) -> int:
    if inventory.has(item_name):
        return inventory[item_name]
    return 0

func get_item_texture(item_name: String) -> Texture2D:
    if item_textures.has(item_name):
        return item_textures[item_name]
    return null

func print_inventory() -> void:
    for item in inventory.keys():
        print(item, ": ", inventory[item])

# Save inventory data
func save() -> Dictionary:
    return {
        "inventory": inventory.duplicate()
    }

# Load inventory data
func load_data(data: Dictionary) -> void:
    if data.has("inventory"):
        inventory = data["inventory"].duplicate()
        emit_signal("inventory_updated")

func show_pickup_text(item_name: String, amount: int, position: Vector2) -> void:
    """Creates a floating text effect at the given position"""
    # Get the scene tree
    var tree = Engine.get_main_loop() as SceneTree
    if not tree:
        return
    
    # Create a label for the floating pickup text
    var pickup_label = Label.new()
    pickup_label.text = "+%d %s" % [amount, item_name]
    pickup_label.add_theme_font_size_override("font_size", 20)
    pickup_label.modulate = Color(1, 1, 0.5)  # Yellow color
    pickup_label.z_index = 100  # Draw on top
    
    # Position above the item
    pickup_label.position = position + Vector2(-20, -30)
    
    # Add to scene root
    tree.root.add_child(pickup_label)
    
    # Animate the label (float up and fade out)
    var tween = pickup_label.create_tween()
    tween.set_parallel(true)  # Run animations in parallel
    tween.tween_property(pickup_label, "position:y", pickup_label.position.y - 50, 1.0)
    tween.tween_property(pickup_label, "modulate:a", 0.0, 1.0)
    
    # Delete after animation
    tween.finished.connect(func(): pickup_label.queue_free())
