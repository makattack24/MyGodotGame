extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var item_count: Label = $MarginContainer/VBoxContainer/Label

var item_name: String = ""
var item_texture: Texture2D = null
var count: int = 0
var is_selected: bool = false

func set_item(p_item_name: String, p_count: int, p_texture: Texture2D = null) -> void:
	item_name = p_item_name
	count = p_count
	item_texture = p_texture
	
	if p_texture:
		item_icon.texture = p_texture
		item_icon.visible = true
	else:
		item_icon.visible = false
	
	if count > 0:
		item_count.text = str(count)
		item_count.visible = true
	else:
		item_count.text = ""
		item_count.visible = false

func clear_slot() -> void:
	item_name = ""
	count = 0
	item_texture = null
	item_icon.texture = null
	item_icon.visible = false
	item_count.visible = false

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		# Highlight selected slot with brighter color and subtle outline effect
		self.modulate = Color(1.3, 1.3, 1.3)  # Brighter
		# Add a subtle border effect by adjusting the panel style
		self.self_modulate = Color(1.2, 1.2, 0.8)  # Yellow tint
	else:
		# Normal appearance
		self.modulate = Color(1, 1, 1)
		self.self_modulate = Color(1, 1, 1)