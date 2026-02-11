extends Node

signal inventory_updated  # Signal emitted when inventory is updated

var inventory: Dictionary = {
    "wood": 0,
    "coin": 0,
    "axe": 1,  # Start with 1 axe
    "pickaxe": 1,  # Start with 1 pickaxe
    "rock": 0,
    "saw_mill": 400,  # Start with 1 saw mill for testing
    "wall": 40,
    "campfire": 10,
    "sleeping_bag": 5,
    "slimeball": 0
}

# Item textures - add your item textures here
# For sprite sheet items, use create_atlas_texture() in _ready
var item_textures: Dictionary = {
    "wood": preload("res://Assets/woodItem.png"),
    "coin": preload("res://Assets/coin.png"),
    "axe": preload("res://Assets/WoodAxe.png"),
    "pickaxe": preload("res://Assets/pickaxe.png"),
    "rock": preload("res://Assets/rock.png"),
    "saw_mill": preload("res://Assets/saw mill machine.png"),
    "campfire": preload("res://Assets/campfire.png"),
    "sleeping_bag": preload("res://Assets/sleepingbag.png"),
    "slimeball": preload("res://Assets/slimeball.png")
    # wall texture will be added from sprite sheet in _ready
}

# Helper function to create texture from sprite sheet region
func create_atlas_texture(sprite_sheet_path: String, region: Rect2) -> AtlasTexture:
    var atlas = AtlasTexture.new()
    atlas.atlas = load(sprite_sheet_path)
    atlas.region = region
    return atlas

func _ready() -> void:
    # Add to persist group for saving/loading
    add_to_group("persist")
    
    # Set up sprite sheet texture for wall (using the same region as wall.tscn)
    item_textures["wall"] = create_atlas_texture(
        "res://Assets/FreeDownloadedAssets/fantasy_ [version 2.0]/forest_/forest_ [fencesAndWalls].png",
        Rect2(19, 92, 10, 17)
    )

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
