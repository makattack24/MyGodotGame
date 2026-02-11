extends RefCounted
class_name ThemeTokens

# Token construction

static func build_tokens(colors: Dictionary) -> Dictionary:
	var t = {}
	
	# ========== COLOR SYSTEM ==========
	# Material 3 uses the color roles system
	t.color = {}
	
	# Determine theme type (dark / light)
	var base_luminance = ThemeHelpers.luminance(colors.base)
	var is_dark_theme = base_luminance < 0.4
	
	# Detect if primary/secondary are already light (helps for dark themes)
	var primary_luminance = ThemeHelpers.luminance(colors.primary)
	var primary_is_light = primary_luminance > 0.5
	
	# Primary
	t.color.primary = colors.primary
	t.color.on_primary = ThemeHelpers.contrast_text(colors.primary)
	
	# For dark themes with a light primary, invert container logic
	if is_dark_theme and primary_is_light:
		# primary is already light — make container darker
		t.color.primary_container = colors.primary.darkened(0.6)
		t.color.on_primary_container = colors.primary
	else:
		# Standard logic
		t.color.primary_container = colors.primary.lightened(0.7)
		t.color.on_primary_container = ThemeHelpers.contrast_text(t.color.primary_container)
	
	# Secondary
	var secondary_luminance = ThemeHelpers.luminance(colors.secondary)
	var secondary_is_light = secondary_luminance > 0.5
	
	t.color.secondary = colors.secondary
	t.color.on_secondary = ThemeHelpers.contrast_text(colors.secondary)
	
	if is_dark_theme and secondary_is_light:
		t.color.secondary_container = colors.secondary.darkened(0.6)
		t.color.on_secondary_container = colors.secondary
	else:
		t.color.secondary_container = colors.secondary.lightened(0.7)
		t.color.on_secondary_container = ThemeHelpers.contrast_text(t.color.secondary_container)
	
	# Tertiary (accent)
	var tertiary_luminance = ThemeHelpers.luminance(colors.accent)
	var tertiary_is_light = tertiary_luminance > 0.5
	
	t.color.tertiary = colors.accent
	t.color.on_tertiary = ThemeHelpers.contrast_text(colors.accent)
	
	if is_dark_theme and tertiary_is_light:
		t.color.tertiary_container = colors.accent.darkened(0.6)
		t.color.on_tertiary_container = colors.accent
	else:
		t.color.tertiary_container = colors.accent.lightened(0.7)
		t.color.on_tertiary_container = ThemeHelpers.contrast_text(t.color.tertiary_container)
	
	# Error
	t.color.error = colors.error
	t.color.on_error = ThemeHelpers.contrast_text(colors.error)
	t.color.error_container = colors.error.lightened(0.7)
	t.color.on_error_container = ThemeHelpers.contrast_text(t.color.error_container)
	
	# Background & Surface
	t.color.background = colors.base
	t.color.on_background = ThemeHelpers.contrast_text(colors.base)
	t.color.surface = colors.base.lightened(0.02)
	t.color.on_surface = ThemeHelpers.contrast_text(t.color.surface)
	t.color.surface_variant = colors.neutral.lightened(0.1)
	t.color.on_surface_variant = ThemeHelpers.contrast_text(t.color.surface_variant)
	
	# Surface levels (for elevation)
	t.color.surface_dim = colors.base.darkened(0.03)
	t.color.surface_bright = colors.base.lightened(0.08)
	t.color.surface_container_lowest = colors.base.darkened(0.05)
	t.color.surface_container_low = colors.base.lightened(0.01)
	t.color.surface_container = colors.base.lightened(0.03)
	t.color.surface_container_high = colors.base.lightened(0.05)
	t.color.surface_container_highest = colors.base.lightened(0.08)
	
	# On-surface for each level (important for correct contrast)
	t.color.on_surface_dim = ThemeHelpers.contrast_text(t.color.surface_dim)
	t.color.on_surface_bright = ThemeHelpers.contrast_text(t.color.surface_bright)
	t.color.on_surface_container_lowest = ThemeHelpers.contrast_text(t.color.surface_container_lowest)
	t.color.on_surface_container_low = ThemeHelpers.contrast_text(t.color.surface_container_low)
	t.color.on_surface_container = ThemeHelpers.contrast_text(t.color.surface_container)
	t.color.on_surface_container_high = ThemeHelpers.contrast_text(t.color.surface_container_high)
	t.color.on_surface_container_highest = ThemeHelpers.contrast_text(t.color.surface_container_highest)
	
	# Outline — adaptive for light/dark themes
	if base_luminance > 0.5:
		# Light theme — darken outline
		t.color.outline = colors.neutral.darkened(0.5)
		t.color.outline_variant = colors.neutral.darkened(0.3)
	else:
		# Dark theme — lighten outline
		t.color.outline = colors.neutral.lightened(0.3)
		t.color.outline_variant = colors.neutral.lightened(0.15)
	
	# Additional semantic colors (info, success, warning)
	t.color.info = colors.info
	t.color.on_info = ThemeHelpers.contrast_text(colors.info)
	t.color.success = colors.success
	t.color.on_success = ThemeHelpers.contrast_text(colors.success)
	t.color.warning = colors.warning
	t.color.on_warning = ThemeHelpers.contrast_text(colors.warning)
	
	# ========== STATE LAYERS ==========
	# Material uses overlays for interaction states
	t.state = {
		"hover": 0.08,      # 8% overlay
		"focus": 0.12,      # 12% overlay
		"pressed": 0.12,    # 12% overlay
		"dragged": 0.16,    # 16% overlay
		"disabled": 0.38    # 38% opacity
	}
	
	# ========== ELEVATION ==========
	# Material uses multiple elevation levels
	t.elevation = {
		"level0": {"shadow_size": 0, "shadow_offset": Vector2(0, 0), "tint": 0.0},
		"level1": {"shadow_size": 1, "shadow_offset": Vector2(0, 1), "tint": 0.05},
		"level2": {"shadow_size": 3, "shadow_offset": Vector2(0, 2), "tint": 0.08},
		"level3": {"shadow_size": 6, "shadow_offset": Vector2(0, 4), "tint": 0.11},
		"level4": {"shadow_size": 8, "shadow_offset": Vector2(0, 6), "tint": 0.12},
		"level5": {"shadow_size": 12, "shadow_offset": Vector2(0, 8), "tint": 0.14}
	}
	
	# ========== SHAPE (BORDER RADIUS) ==========
	# Material defines shape families
	t.shape = {
		"none": 0,
		"extra_small": 4,
		"small": 8,
		"medium": 12,
		"large": 16,
		"extra_large": 28,
		"full": 9999  # fully rounded
	}
	
	# ========== TYPOGRAPHY ==========
	# Material type scale
	t.typography = {
		"display_large": {"size": 57, "line_height": 64, "weight": "regular"},
		"display_medium": {"size": 45, "line_height": 52, "weight": "regular"},
		"display_small": {"size": 36, "line_height": 44, "weight": "regular"},
		
		"header_large": {"size": 32, "line_height": 40, "weight": "regular"},
		"header_medium": {"size": 28, "line_height": 36, "weight": "regular"},
		"header_small": {"size": 24, "line_height": 32, "weight": "regular"},
		
		"title_large": {"size": 22, "line_height": 28, "weight": "regular"},
		"title_medium": {"size": 16, "line_height": 24, "weight": "medium"},
		"title_small": {"size": 14, "line_height": 20, "weight": "medium"},
		
		"body_large": {"size": 16, "line_height": 24, "weight": "regular"},
		"body_medium": {"size": 14, "line_height": 20, "weight": "regular"},
		"body_small": {"size": 12, "line_height": 16, "weight": "regular"},
		
		"label_large": {"size": 14, "line_height": 20, "weight": "medium"},
		"label_medium": {"size": 12, "line_height": 16, "weight": "medium"},
		"label_small": {"size": 11, "line_height": 16, "weight": "medium"}
	}
	
	# ========== SPACING ==========
	# Material uses an 8dp spacing grid
	t.spacing = {
		"xs": 4,
		"sm": 8,
		"md": 16,
		"lg": 24,
		"xl": 32,
		"xxl": 48
	}
	
	# ========== SIZING SYSTEM ==========
	# For mobile baseline 540x1200 (with auto-scaling)
	# Minimum tap area 44-48px per Apple/Google recommendations
	t.sizing = {
		"compact": {
			"button_height": 36,
			"button_padding_h": 16,
			"input_height": 44,
			"input_padding_h": 12,
			"tab_height": 42,
			"font_size": 13,
			"icon_size": 16
		},
		"default": {
			"button_height": 48,
			"button_padding_h": 20,
			"input_height": 56,
			"input_padding_h": 16,
			"tab_height": 52,
			"font_size": 15,
			"icon_size": 20
		},
		"comfortable": {
			"button_height": 56,
			"button_padding_h": 28,
			"input_height": 64,
			"input_padding_h": 20,
			"tab_height": 60,
			"font_size": 16,
			"icon_size": 24
		}
	}
	
	# ========== COMPONENT SPECIFIC ==========
	# Default sizing (optimized for mobile 540x1200)
	t.button = t.sizing.default.duplicate()
	t.button.padding_icon = 16
	
	t.tab = {
		"height": t.sizing.default.tab_height,
		"indicator_height": 3,
		"padding_horizontal": 16
	}
	
	t.input = {
		"height": t.sizing.default.input_height,
		"padding_horizontal": t.sizing.default.input_padding_h
	}
	
	return t
