extends RefCounted
class_name ThemeButtons

static func apply_buttons(theme: Theme, t: Dictionary) -> void:
	# Material Button types: Filled, Outlined, Text, Elevated, Tonal
	
	# Default sizing
	# Filled Button (Primary)
	add_filled_button(theme, "FilledButton", t.color.primary, t.color.on_primary, t)
	
	# Filled Tonal Button
	add_filled_button(theme, "TonalButton", t.color.secondary_container, t.color.on_secondary_container, t)
	
	# Outlined Button
	add_outlined_button(theme, "OutlinedButton", t.color.primary, t)
	
	# Text Button
	add_text_button(theme, "TextButton", t.color.primary, t)
	
	# Elevated Button
	add_elevated_button(theme, "ElevatedButton", t.color.surface_container_low, t.color.primary, t)
	
	# Default Button (Filled)
	add_filled_button(theme, "Button", t.color.primary, t.color.on_primary, t)
	
	# OptionButton - uses surface styles with appropriate colors
	add_option_button(theme, "OptionButton", t)
	
	# Semantic variants
	add_filled_button(theme, "SecondaryButton", t.color.secondary, t.color.on_secondary, t)
	add_filled_button(theme, "TertiaryButton", t.color.tertiary, t.color.on_tertiary, t)
	add_filled_button(theme, "ErrorButton", t.color.error, t.color.on_error, t)
	add_filled_button(theme, "SuccessButton", t.color.success, t.color.on_success, t)
	add_filled_button(theme, "WarningButton", t.color.warning, t.color.on_warning, t)
	add_filled_button(theme, "InfoButton", t.color.info, t.color.on_info, t)
	
	# ========== SIZING VARIATIONS ==========
	# Compact sizing
	var t_compact = t.duplicate(true)
	t_compact.button = t.sizing.compact.duplicate()
	t_compact.button.padding_icon = 12
	
	add_filled_button(theme, "ButtonCompact", t.color.primary, t.color.on_primary, t_compact)
	add_outlined_button(theme, "OutlinedButtonCompact", t.color.primary, t_compact)
	add_text_button(theme, "TextButtonCompact", t.color.primary, t_compact)
	add_elevated_button(theme, "ElevatedButtonCompact", t.color.surface_container_low, t.color.primary, t_compact)
	add_filled_button(theme, "TonalButtonCompact", t.color.secondary_container, t.color.on_secondary_container, t_compact)
	
	# Semantic compact
	add_filled_button(theme, "SecondaryButtonCompact", t.color.secondary, t.color.on_secondary, t_compact)
	add_filled_button(theme, "ErrorButtonCompact", t.color.error, t.color.on_error, t_compact)
	add_filled_button(theme, "SuccessButtonCompact", t.color.success, t.color.on_success, t_compact)
	add_filled_button(theme, "WarningButtonCompact", t.color.warning, t.color.on_warning, t_compact)
	
	# Comfortable sizing
	var t_comfortable = t.duplicate(true)
	t_comfortable.button = t.sizing.comfortable.duplicate()
	t_comfortable.button.padding_icon = 20
	
	add_filled_button(theme, "ButtonLarge", t.color.primary, t.color.on_primary, t_comfortable)
	add_outlined_button(theme, "OutlinedButtonLarge", t.color.primary, t_comfortable)
	add_text_button(theme, "TextButtonLarge", t.color.primary, t_comfortable)
	add_elevated_button(theme, "ElevatedButtonLarge", t.color.surface_container_low, t.color.primary, t_comfortable)
	add_filled_button(theme, "TonalButtonLarge", t.color.secondary_container, t.color.on_secondary_container, t_comfortable)
	
	# Semantic large
	add_filled_button(theme, "SecondaryButtonLarge", t.color.secondary, t.color.on_secondary, t_comfortable)
	add_filled_button(theme, "ErrorButtonLarge", t.color.error, t.color.on_error, t_comfortable)
	add_filled_button(theme, "SuccessButtonLarge", t.color.success, t.color.on_success, t_comfortable)
	add_filled_button(theme, "WarningButtonLarge", t.color.warning, t.color.on_warning, t_comfortable)


static func add_filled_button(theme: Theme, type_name: String, bg: Color, text: Color, t: Dictionary) -> void:
	# Normal
	var normal = ThemeHelpers.stylebox_with_elevation(bg, t.shape.large, t.elevation.level0)
	var padding_h = t.button.button_padding_h
	var padding_v = (t.button.button_height - t.button.font_size) / 2 - 4
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	# Hover (state layer)
	var hover_color = ThemeHelpers.apply_state_layer(bg, text, t.state.hover)
	var hover = ThemeHelpers.stylebox_with_elevation(hover_color, t.shape.large, t.elevation.level1)
	hover.content_margin_left = padding_h
	hover.content_margin_right = padding_h
	hover.content_margin_top = padding_v
	hover.content_margin_bottom = padding_v
	
	# Pressed
	var pressed_color = ThemeHelpers.apply_state_layer(bg, text, t.state.pressed)
	var pressed = ThemeHelpers.stylebox(pressed_color, t.shape.large)
	pressed.content_margin_left = padding_h
	pressed.content_margin_right = padding_h
	pressed.content_margin_top = padding_v
	pressed.content_margin_bottom = padding_v
	
	# Disabled
	var disabled = ThemeHelpers.stylebox(bg.darkened(0.5), t.shape.large)
	disabled.bg_color.a = 0.12
	disabled.content_margin_left = padding_h
	disabled.content_margin_right = padding_h
	disabled.content_margin_top = padding_v
	disabled.content_margin_bottom = padding_v
	
	# Focus - same as normal (no outline)
	var focus = ThemeHelpers.stylebox(bg, t.shape.large)
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_focus_color", type_name, text)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38  # Material disabled opacity
	theme.set_color("font_disabled_color", type_name, disabled_text)
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, text)
	theme.set_color("icon_pressed_color", type_name, text)
	var disabled_icon = t.color.on_surface
	disabled_icon.a = 0.38
	theme.set_color("icon_disabled_color", type_name, disabled_icon)


static func add_outlined_button(theme: Theme, type_name: String, outline_color: Color, t: Dictionary) -> void:
	var padding_h = t.button.button_padding_h
	var padding_v = (t.button.button_height - t.button.font_size) / 2 - 4
	
	# Normal
	var normal = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	normal.set_border_width_all(1)
	normal.border_color = t.color.outline
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	# Hover
	var hover_color = ThemeHelpers.apply_state_layer(Color.TRANSPARENT, outline_color, t.state.hover)
	var hover = ThemeHelpers.stylebox(hover_color, t.shape.large)
	hover.set_border_width_all(1)
	hover.border_color = t.color.outline
	hover.content_margin_left = padding_h
	hover.content_margin_right = padding_h
	hover.content_margin_top = padding_v
	hover.content_margin_bottom = padding_v
	
	# Pressed
	var pressed_color = ThemeHelpers.apply_state_layer(Color.TRANSPARENT, outline_color, t.state.pressed)
	var pressed = ThemeHelpers.stylebox(pressed_color, t.shape.large)
	pressed.set_border_width_all(1)
	pressed.border_color = t.color.outline
	pressed.content_margin_left = padding_h
	pressed.content_margin_right = padding_h
	pressed.content_margin_top = padding_v
	pressed.content_margin_bottom = padding_v
	
	# Disabled
	var disabled = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	disabled.set_border_width_all(1)
	disabled.border_color = t.color.on_surface
	disabled.border_color.a = 0.12
	disabled.content_margin_left = padding_h
	disabled.content_margin_right = padding_h
	disabled.content_margin_top = padding_v
	disabled.content_margin_bottom = padding_v
	
	# Focus - same as normal
	var focus = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	focus.set_border_width_all(1)
	focus.border_color = t.color.outline
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, outline_color)
	theme.set_color("font_hover_color", type_name, outline_color)
	theme.set_color("font_pressed_color", type_name, outline_color)
	theme.set_color("font_focus_color", type_name, outline_color)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)


static func add_text_button(theme: Theme, type_name: String, text_color: Color, t: Dictionary) -> void:
	var padding_h = 12
	var padding_v = (t.button.button_height - t.button.font_size) / 2 - 4
	
	# Normal
	var normal = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	# Hover
	var hover_color = ThemeHelpers.apply_state_layer(Color.TRANSPARENT, text_color, t.state.hover)
	var hover = ThemeHelpers.stylebox(hover_color, t.shape.large)
	hover.content_margin_left = padding_h
	hover.content_margin_right = padding_h
	hover.content_margin_top = padding_v
	hover.content_margin_bottom = padding_v
	
	# Pressed
	var pressed_color = ThemeHelpers.apply_state_layer(Color.TRANSPARENT, text_color, t.state.pressed)
	var pressed = ThemeHelpers.stylebox(pressed_color, t.shape.large)
	pressed.content_margin_left = padding_h
	pressed.content_margin_right = padding_h
	pressed.content_margin_top = padding_v
	pressed.content_margin_bottom = padding_v
	
	# Disabled
	var disabled = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	disabled.content_margin_left = padding_h
	disabled.content_margin_right = padding_h
	disabled.content_margin_top = padding_v
	disabled.content_margin_bottom = padding_v
	
	# Focus - same as normal
	var focus = ThemeHelpers.stylebox(Color.TRANSPARENT, t.shape.large)
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, text_color)
	theme.set_color("font_hover_color", type_name, text_color)
	theme.set_color("font_pressed_color", type_name, text_color)
	theme.set_color("font_focus_color", type_name, text_color)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)


static func add_elevated_button(theme: Theme, type_name: String, bg: Color, text_color: Color, t: Dictionary) -> void:
	var padding_h = t.button.button_padding_h
	var padding_v = (t.button.button_height - t.button.font_size) / 2 - 4
	
	# Normal
	var normal = ThemeHelpers.stylebox_with_elevation(bg, t.shape.large, t.elevation.level1)
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	# Hover
	var hover_color = ThemeHelpers.apply_state_layer(bg, text_color, t.state.hover)
	var hover = ThemeHelpers.stylebox_with_elevation(hover_color, t.shape.large, t.elevation.level2)
	hover.content_margin_left = padding_h
	hover.content_margin_right = padding_h
	hover.content_margin_top = padding_v
	hover.content_margin_bottom = padding_v
	
	# Pressed
	var pressed_color = ThemeHelpers.apply_state_layer(bg, text_color, t.state.pressed)
	var pressed = ThemeHelpers.stylebox_with_elevation(pressed_color, t.shape.large, t.elevation.level1)
	pressed.content_margin_left = padding_h
	pressed.content_margin_right = padding_h
	pressed.content_margin_top = padding_v
	pressed.content_margin_bottom = padding_v
	
	# Disabled
	var disabled = ThemeHelpers.stylebox(bg.darkened(0.5), t.shape.large)
	disabled.bg_color.a = 0.12
	disabled.content_margin_left = padding_h
	disabled.content_margin_right = padding_h
	disabled.content_margin_top = padding_v
	disabled.content_margin_bottom = padding_v
	
	# Focus - same as normal
	var focus = ThemeHelpers.stylebox_with_elevation(bg, t.shape.large, t.elevation.level1)
	focus.content_margin_left = padding_h
	focus.content_margin_right = padding_h
	focus.content_margin_top = padding_v
	focus.content_margin_bottom = padding_v
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, text_color)
	theme.set_color("font_hover_color", type_name, text_color)
	theme.set_color("font_pressed_color", type_name, text_color)
	theme.set_color("font_focus_color", type_name, text_color)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)


static func add_option_button(theme: Theme, type_name: String, t: Dictionary) -> void:
	# OptionButton - Material filled style (similar to FilledButton, but uses surface background)
	var bg = t.color.surface_container_high
	var text = t.color.on_surface
	
	# Normal
	var normal = ThemeHelpers.stylebox(bg, t.shape.small)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	
	# Hover
	var hover_color = ThemeHelpers.apply_state_layer(bg, text, t.state.hover)
	var hover = ThemeHelpers.stylebox(hover_color, t.shape.small)
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	
	# Pressed
	var pressed_color = ThemeHelpers.apply_state_layer(bg, text, t.state.pressed)
	var pressed = ThemeHelpers.stylebox(pressed_color, t.shape.small)
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	
	# Disabled
	var disabled = ThemeHelpers.stylebox(bg.darkened(0.3), t.shape.small)
	disabled.bg_color.a = 0.12
	disabled.content_margin_left = 16
	disabled.content_margin_right = 16
	disabled.content_margin_top = 8
	disabled.content_margin_bottom = 8
	
	# Focus - выглядит как normal
	var focus = ThemeHelpers.stylebox(bg, t.shape.small)
	focus.content_margin_left = 16
	focus.content_margin_right = 16
	focus.content_margin_top = 8
	focus.content_margin_bottom = 8
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, disabled)
	
	# Text colors
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_focus_color", type_name, text)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)
	
	# Icon colors
	theme.set_color("icon_normal_color", type_name, text)
	theme.set_color("icon_hover_color", type_name, text)
	theme.set_color("icon_pressed_color", type_name, text)
	var disabled_icon = t.color.on_surface
	disabled_icon.a = 0.38
	theme.set_color("icon_disabled_color", type_name, disabled_icon)
