extends RefCounted
class_name ThemeHelpers

# Helper functions used across the chromatica addon

static func stylebox(bg: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func stylebox_with_elevation(bg: Color, radius: int, elevation: Dictionary) -> StyleBoxFlat:
	var sb = stylebox(bg, radius)
	
	# Apply elevation (shadow + tint)
	if elevation.shadow_size > 0:
		sb.shadow_size = elevation.shadow_size
		sb.shadow_offset = elevation.shadow_offset
		sb.shadow_color = Color(0, 0, 0, 0.3)  # 30% opacity for shadows

	# Tint — lighten background slightly based on elevation tint
	if elevation.tint > 0:
		sb.bg_color = bg.lightened(elevation.tint)
	
	return sb


static func contrast_text(bg: Color) -> Color:
	var l = luminance(bg)

	if l < 0.12:
		return Color.WHITE
	if l > 0.65:
		return Color.BLACK

	# Prefer white for UI elements when in mid-range luminance
	if l < 0.45:
		return Color.WHITE

	return Color.BLACK


static func luminance(color: Color) -> float:
	var r = _linear_rgb(color.r)
	var g = _linear_rgb(color.g)
	var b = _linear_rgb(color.b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b

static func _linear_rgb(channel: float) -> float:
	# Convert sRGB channel to linear RGB for accurate luminance calculation
	if channel <= 0.04045:
		return channel / 12.92
	else:
		return pow((channel + 0.055) / 1.055, 2.4)

static func apply_state_layer(bg: Color, overlay: Color, opacity: float) -> Color:
	# Material state layer: overlay the given color with specified opacity
	var result = bg.lerp(overlay, opacity)
	return result


static func create_checkbox_icon(color: Color, checked: bool) -> ImageTexture:
	# TODO: implement checkbox icon rendering
	# - Draw box outline and checkmark for `checked == true`
	# - Use `color` for filled state and appropriate contrast for mark
	# This placeholder returns a transparent 24x24 texture.
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)
