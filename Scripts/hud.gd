extends CanvasLayer

var inventory_label: Label  # Reference to the Label node

func _ready() -> void:
	# Get the Label node from the scene (adjust path to your specific setup)
	inventory_label = $HBoxContainer/WoodCount
	update_inventory_display()  # Set the initial inventory count

	# Connect the inventory_updated signal from the Inventory singleton (using Callable)
	Inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))

# Updates the label to display the inventory contents
func update_inventory_display() -> void:
	var inventory_text = ""
	# Loop through the inventory items and build the display string
	for item_name in Inventory.inventory.keys():
		var item_count = Inventory.inventory[item_name]
		inventory_text += "%s: %d\n" % [item_name, item_count]
	
	# Set the text on the Label
	inventory_label.text = inventory_text

# Signal handler for when the inventory is updated
func _on_inventory_updated() -> void:
	# Call update_inventory_display to refresh the displayed inventory
	update_inventory_display()
