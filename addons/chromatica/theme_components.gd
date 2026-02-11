extends RefCounted
class_name ThemeComponents

# =========================================================
# OTHER UI COMPONENTS
# =========================================================

static func apply_panels(theme: Theme, t: Dictionary) -> void:
	# Surface containers with different elevation levels
	set_panel(theme, "Panel", t.color.surface)
	set_panel_elevated(theme, "PanelElevated1", t.color.surface, t.elevation.level1, 0)
	set_panel_elevated(theme, "PanelElevated2", t.color.surface, t.elevation.level2, 0)
	set_panel_elevated(theme, "PanelElevated3", t.color.surface, t.elevation.level3, 0)
	
	# Surface variants
	set_panel(theme, "SurfaceContainer", t.color.surface_container)
	set_panel(theme, "SurfaceContainerLow", t.color.surface_container_low)
	set_panel(theme, "SurfaceContainerHigh", t.color.surface_container_high)
	set_panel(theme, "SurfaceContainerHighest", t.color.surface_container_highest)


static func set_panel(theme: Theme, panel_name: String, color: Color) -> void:
	var sb = ThemeHelpers.stylebox(color, 0)
	theme.set_stylebox("panel", panel_name, sb)


static func set_panel_elevated(theme: Theme, panel_name: String, color: Color, elevation: Dictionary, radius: int) -> void:
	var sb = ThemeHelpers.stylebox_with_elevation(color, radius, elevation)
	theme.set_stylebox("panel", panel_name, sb)


static func apply_labels(theme: Theme, t: Dictionary) -> void:
	for type_name in ["Label", "RichTextLabel", "LineEdit", "CheckBox"]:
		theme.set_color("font_color", type_name, t.color.on_surface)


static func apply_tab_buttons(theme: Theme, t: Dictionary) -> void:
	# M3 primary navigation tabs for TabBar (tabs with indicator)
	add_tab_bar(theme, "TabBar", t)
	# Secondary tabs (more compact)
	add_secondary_tab(theme, "SecondaryTab", t)


static func add_tab_bar(theme: Theme, type_name: String, t: Dictionary) -> void:
	# M3 primary tabs for TabBar (tab container)
	var indicator_h = t.tab.indicator_height
	var padding_h = t.tab.padding_horizontal
	var padding_v = (t.tab.height - t.sizing.default.font_size) / 2 - indicator_h - 4
	
	var normal = ThemeHelpers.stylebox(Color.TRANSPARENT, 0)
	normal.border_width_bottom = indicator_h
	normal.border_color = Color.TRANSPARENT
	normal.content_margin_left = padding_h
	normal.content_margin_right = padding_h
	normal.content_margin_top = padding_v
	normal.content_margin_bottom = padding_v
	
	var hover = normal.duplicate()
	var hover_bg = ThemeHelpers.apply_state_layer(t.color.surface, t.color.primary, t.state.hover)
	hover.bg_color = hover_bg
	hover.border_color = Color.TRANSPARENT
	
	var pressed = normal.duplicate()
	pressed.border_color = t.color.primary
	pressed.bg_color = Color.TRANSPARENT
	
	var disabled = normal.duplicate()
	disabled.border_color = Color.TRANSPARENT
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, t.color.on_surface_variant)
	theme.set_color("font_hover_color", type_name, t.color.on_surface)
	theme.set_color("font_pressed_color", type_name, t.color.primary)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)


static func add_secondary_tab(theme: Theme, type_name: String, t: Dictionary) -> void:
	# M3 secondary tabs (more compact)
	var normal = ThemeHelpers.stylebox(t.color.surface_container, t.shape.small)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	
	var hover_bg = ThemeHelpers.apply_state_layer(t.color.surface_container, t.color.primary, t.state.hover)
	var hover = ThemeHelpers.stylebox(hover_bg, t.shape.small)
	hover.content_margin_left = 12
	hover.content_margin_right = 12
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	
	var pressed = ThemeHelpers.stylebox(t.color.secondary_container, t.shape.small)
	pressed.content_margin_left = 12
	pressed.content_margin_right = 12
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	
	var disabled = ThemeHelpers.stylebox(t.color.surface_container, t.shape.small)
	disabled.bg_color.a = 0.38
	disabled.content_margin_left = 12
	disabled.content_margin_right = 12
	disabled.content_margin_top = 8
	disabled.content_margin_bottom = 8
	
	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover)
	theme.set_stylebox("pressed", type_name, pressed)
	theme.set_stylebox("disabled", type_name, disabled)
	
	theme.set_color("font_color", type_name, t.color.on_surface_variant)
	theme.set_color("font_hover_color", type_name, t.color.on_surface)
	theme.set_color("font_pressed_color", type_name, t.color.on_secondary_container)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", type_name, disabled_text)


static func apply_tab_container(theme: Theme, t: Dictionary) -> void:
	# TabContainer uses TabBar for tabs
	var indicator_h = t.tab.indicator_height
	var padding_h = t.tab.padding_horizontal
	var padding_v = (t.tab.height - t.sizing.default.font_size) / 2 - indicator_h - 4
	
	# Panel (container background)
	var panel = ThemeHelpers.stylebox(t.color.surface_container, t.shape.medium)
	panel.content_margin_left = 0
	panel.content_margin_right = 0
	panel.content_margin_top = t.tab.height + 4
	panel.content_margin_bottom = 0
	
	# TabBar background
	var tabbar_bg = ThemeHelpers.stylebox(t.color.surface, 0)
	tabbar_bg.content_margin_left = 0
	tabbar_bg.content_margin_right = 0
	tabbar_bg.content_margin_top = 0
	tabbar_bg.content_margin_bottom = 0
	
	# Tab buttons
	var tab_unselected = ThemeHelpers.stylebox(Color.TRANSPARENT, 0)
	tab_unselected.border_width_bottom = indicator_h
	tab_unselected.border_color = Color.TRANSPARENT
	tab_unselected.content_margin_left = padding_h
	tab_unselected.content_margin_right = padding_h
	tab_unselected.content_margin_top = padding_v
	tab_unselected.content_margin_bottom = padding_v
	
	var tab_hovered = tab_unselected.duplicate()
	var hover_bg = ThemeHelpers.apply_state_layer(t.color.surface, t.color.primary, t.state.hover)
	tab_hovered.bg_color = hover_bg
	tab_hovered.border_color = Color.TRANSPARENT
	
	var tab_selected = tab_unselected.duplicate()
	tab_selected.border_color = t.color.primary
	tab_selected.bg_color = Color.TRANSPARENT
	
	var tab_disabled = tab_unselected.duplicate()
	tab_disabled.border_color = Color.TRANSPARENT
	
	theme.set_stylebox("panel", "TabContainer", panel)
	theme.set_stylebox("tabbar_background", "TabContainer", tabbar_bg)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hovered)
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_disabled", "TabContainer", tab_disabled)
	
	theme.set_color("font_unselected_color", "TabContainer", t.color.on_surface_variant)
	theme.set_color("font_hovered_color", "TabContainer", t.color.on_surface)
	theme.set_color("font_selected_color", "TabContainer", t.color.primary)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", "TabContainer", disabled_text)


static func apply_scrollbars(theme: Theme, t: Dictionary) -> void:
	# Scrollbar
	var scroll_bg = ThemeHelpers.stylebox(t.color.surface_container, 4)
	scroll_bg.content_margin_left = 2
	scroll_bg.content_margin_right = 2
	scroll_bg.content_margin_top = 2
	scroll_bg.content_margin_bottom = 2
	
	var grabber = ThemeHelpers.stylebox(t.color.on_surface_variant.darkened(0.3), 4)
	var grabber_highlight = ThemeHelpers.stylebox(t.color.on_surface_variant, 4)
	var grabber_pressed = ThemeHelpers.stylebox(t.color.primary, 4)
	
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)
	theme.set_stylebox("scroll", "HScrollBar", scroll_bg)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber", "HScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_highlight)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_pressed)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber_pressed)


static func apply_sliders(theme: Theme, t: Dictionary) -> void:
	# Slider track
	var slider_bg = ThemeHelpers.stylebox(t.color.surface_container_highest, 2)
	slider_bg.content_margin_top = 2
	slider_bg.content_margin_bottom = 2
	
	var grabber_area = ThemeHelpers.stylebox(t.color.primary, 2)
	grabber_area.content_margin_top = 2
	grabber_area.content_margin_bottom = 2
	
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("slider", "VSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area", "VSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "VSlider", grabber_area)
	
	# Grabber (handle) - use an icon
	theme.set_constant("grabber_offset", "HSlider", 0)
	theme.set_constant("grabber_offset", "VSlider", 0)


static func apply_progress_bars(theme: Theme, t: Dictionary) -> void:
	var bg = ThemeHelpers.stylebox(t.color.surface_container_highest, t.shape.extra_small)
	bg.content_margin_left = 0
	bg.content_margin_right = 0
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	
	var fill = ThemeHelpers.stylebox(t.color.primary, t.shape.extra_small)
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_color("font_color", "ProgressBar", t.color.on_surface)


static func apply_tree(theme: Theme, t: Dictionary) -> void:
	var tree_bg = ThemeHelpers.stylebox(t.color.surface_container, t.shape.medium)
	
	var selected = ThemeHelpers.stylebox(t.color.secondary_container, 0)
	var selected_focus = ThemeHelpers.stylebox(t.color.primary_container, 0)
	
	theme.set_stylebox("panel", "Tree", tree_bg)
	theme.set_stylebox("selected", "Tree", selected)
	theme.set_stylebox("selected_focus", "Tree", selected_focus)
	
	theme.set_color("font_color", "Tree", t.color.on_surface)
	theme.set_color("font_selected_color", "Tree", t.color.on_secondary_container)
	theme.set_color("title_button_color", "Tree", t.color.on_surface_variant)
	theme.set_color("guide_color", "Tree", t.color.outline_variant)
	theme.set_color("relationship_line_color", "Tree", t.color.outline_variant)


static func apply_item_list(theme: Theme, t: Dictionary) -> void:
	var list_bg = ThemeHelpers.stylebox(t.color.surface_container, t.shape.medium)
	
	var selected = ThemeHelpers.stylebox(t.color.secondary_container, t.shape.small)
	var selected_focus = ThemeHelpers.stylebox(t.color.primary_container, t.shape.small)
	var hover = ThemeHelpers.stylebox(ThemeHelpers.apply_state_layer(t.color.surface_container, t.color.on_surface, t.state.hover), t.shape.small)
	
	theme.set_stylebox("panel", "ItemList", list_bg)
	theme.set_stylebox("selected", "ItemList", selected)
	theme.set_stylebox("selected_focus", "ItemList", selected_focus)
	theme.set_stylebox("hovered", "ItemList", hover)
	
	theme.set_color("font_color", "ItemList", t.color.on_surface)
	theme.set_color("font_selected_color", "ItemList", t.color.on_secondary_container)
	theme.set_color("font_hovered_color", "ItemList", t.color.on_surface)
	theme.set_color("guide_color", "ItemList", t.color.outline_variant)


static func apply_popup_menu(theme: Theme, t: Dictionary) -> void:
	# PopupMenu - M3 Menu (elevated surface)
	var panel = ThemeHelpers.stylebox_with_elevation(t.color.surface_container, t.shape.extra_small, t.elevation.level2)
	panel.content_margin_left = 0
	panel.content_margin_right = 0
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	
	# Menu items
	var item_normal = ThemeHelpers.stylebox(Color.TRANSPARENT, 0)
	item_normal.content_margin_left = 16
	item_normal.content_margin_right = 16
	item_normal.content_margin_top = 8
	item_normal.content_margin_bottom = 8
	
	var item_hover = ThemeHelpers.stylebox(ThemeHelpers.apply_state_layer(t.color.surface_container, t.color.on_surface, t.state.hover), 0)
	item_hover.content_margin_left = 16
	item_hover.content_margin_right = 16
	item_hover.content_margin_top = 8
	item_hover.content_margin_bottom = 8
	
	var item_disabled = ThemeHelpers.stylebox(Color.TRANSPARENT, 0)
	item_disabled.content_margin_left = 16
	item_disabled.content_margin_right = 16
	item_disabled.content_margin_top = 8
	item_disabled.content_margin_bottom = 8
	
	theme.set_stylebox("panel", "PopupMenu", panel)
	theme.set_stylebox("hover", "PopupMenu", item_hover)
	theme.set_stylebox("normal", "PopupMenu", item_normal)
	theme.set_stylebox("disabled", "PopupMenu", item_disabled)
	
	theme.set_color("font_color", "PopupMenu", t.color.on_surface)
	theme.set_color("font_hover_color", "PopupMenu", t.color.on_surface)
	var disabled_text = t.color.on_surface
	disabled_text.a = 0.38
	theme.set_color("font_disabled_color", "PopupMenu", disabled_text)
	theme.set_color("font_separator_color", "PopupMenu", t.color.outline_variant)
