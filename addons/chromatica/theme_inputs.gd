extends RefCounted
class_name ThemeInputs

# Input fields and checkboxes theme helpers

static func apply_inputs(theme: Theme, t: Dictionary) -> void:
	var padding_h = t.input.padding_horizontal
	var padding_v = (t.input.height - t.sizing.default.font_size) / 2 - 8
	
	# LineEdit - filled text field (Material style)
	var normal = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.extra_small)
	normal.set_border_width_all(0)
	normal.border_width_bottom = 1
	normal.border_color = t.color.on_surface_variant
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v

	var focus = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.extra_small)
	focus.set_border_width_all(0)
	focus.border_width_bottom = 2
	focus.border_color = t.color.primary
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v - 1  # compensate for border thickness

	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	# Use on_surface_container_highest for correct contrast with background
	theme.set_color("font_color", "LineEdit", t.color.on_surface_container_highest)
	theme.set_color("font_placeholder_color", "LineEdit", t.color.on_surface_variant)
	theme.set_color("caret_color", "LineEdit", t.color.primary)
	
	# Selection uses primary_container for better text visibility
	var selection_color = t.color.primary_container
	selection_color.a = 0.5
	theme.set_color("selection_color", "LineEdit", selection_color)
	
	# Outlined variant
	var outlined_normal = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.extra_small)
	outlined_normal.set_border_width_all(1)
	outlined_normal.border_color = t.color.outline
	outlined_normal.content_margin_left = padding_h
	outlined_normal.content_margin_right = padding_h
	outlined_normal.content_margin_top = padding_v
	outlined_normal.content_margin_bottom = padding_v
	
	var outlined_focus = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.extra_small)
	outlined_focus.set_border_width_all(2)
	outlined_focus.border_color = t.color.primary
	outlined_focus.content_margin_left = padding_h - 1
	outlined_focus.content_margin_right = padding_h - 1
	outlined_focus.content_margin_top = padding_v - 1
	outlined_focus.content_margin_bottom = padding_v - 1
	
	theme.set_stylebox("normal", "OutlinedLineEdit", outlined_normal)
	theme.set_stylebox("focus", "OutlinedLineEdit", outlined_focus)
	# Outlined uses on_surface because background is transparent
	theme.set_color("font_color", "OutlinedLineEdit", t.color.on_surface)
	theme.set_color("caret_color", "OutlinedLineEdit", t.color.primary)
	
	# Sizing variations
	# Compact LineEdit
	apply_lineedit_size(theme, "LineEditCompact", t, t.sizing.compact, selection_color)
	
	# Large (comfortable) LineEdit
	apply_lineedit_size(theme, "LineEditLarge", t, t.sizing.comfortable, selection_color)

	# CheckBox colors
	theme.set_color("font_color", "CheckBox", t.color.on_surface)
	theme.set_color("font_hover_color", "CheckBox", t.color.on_surface)

	# TODO: Provide checkbox icons
	# - Implement `ThemeHelpers.create_checkbox_icon` usage when ready
	# - Uncomment and set the icons below to enable themed checkbox graphics
	# theme.set_icon("checked", "CheckBox", ThemeHelpers.create_checkbox_icon(t.color.primary, true))
	# theme.set_icon("unchecked", "CheckBox", ThemeHelpers.create_checkbox_icon(t.color.on_surface_variant, false))


static func apply_lineedit_size(theme: Theme, type_name: String, t: Dictionary, sizing: Dictionary, selection_color: Color) -> void:
	var padding_h = sizing.input_padding_h
	var padding_v = (sizing.input_height - sizing.font_size) / 2 - 8
	
	var normal = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.extra_small)
	normal.set_border_width_all(0)
	normal.border_width_bottom = 1
	normal.border_color = t.color.on_surface_variant
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	var focus = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.extra_small)
	focus.set_border_width_all(0)
	focus.border_width_bottom = 2
	focus.border_color = t.color.primary
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v - 1
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("focus", type_name, focus)
	# Use on_surface_container_highest for correct contrast
	theme.set_color("font_color", type_name, t.color.on_surface_container_highest)
	theme.set_color("font_placeholder_color", type_name, t.color.on_surface_variant)
	theme.set_color("caret_color", type_name, t.color.primary)
	theme.set_color("selection_color", type_name, selection_color)


static func apply_text_edit(theme: Theme, t: Dictionary) -> void:
	# TextEdit - multiline text field
	var padding_h = t.input.padding_horizontal
	var padding_v = 12
	
	var normal = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.small)
	normal.set_border_width_all(1)
	normal.border_color = t.color.outline
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	var focus = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.small)
	focus.set_border_width_all(2)
	focus.border_color = t.color.primary
	focus.content_margin_left = padding_h - 1
	focus.content_margin_right = padding_h - 1
	focus.content_margin_top = padding_v - 1
	focus.content_margin_bottom = padding_v - 1
	
	var readonly = ThemeHelpers.stylebox(t.color.surface_container_low, t.shape.small)
	readonly.set_border_width_all(1)
	readonly.border_color = t.color.outline_variant
	readonly.content_margin_left = padding_h
	readonly.content_margin_right = padding_h
	readonly.content_margin_top = padding_v
	readonly.content_margin_bottom = padding_v
	
	theme.set_stylebox("normal", "TextEdit", normal)
	theme.set_stylebox("focus", "TextEdit", focus)
	theme.set_stylebox("read_only", "TextEdit", readonly)
	
	# Use on_surface_container_highest for correct contrast
	theme.set_color("font_color", "TextEdit", t.color.on_surface_container_highest)
	theme.set_color("font_placeholder_color", "TextEdit", t.color.on_surface_variant)
	theme.set_color("caret_color", "TextEdit", t.color.primary)
	
	# Selection uses primary_container
	var selection_color = t.color.primary_container
	selection_color.a = 0.5
	theme.set_color("selection_color", "TextEdit", selection_color)
	theme.set_color("font_readonly_color", "TextEdit", t.color.on_surface_variant)
