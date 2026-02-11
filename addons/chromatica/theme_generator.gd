extends Node
class_name ThemeGenerator

## ThemeGenerator
## Material theme generator for Godot.
## Produces a Theme with styles for buttons, panels, inputs, tabs and fonts.
## Usage: ThemeGenerator.generate_theme(input_colors, font_regular, font_medium)


@export var font_regular: Font
@export var font_medium: Font


# =========================================================
# MAIN THEME GENERATION ENTRY
# =========================================================
## Create and return a fully generated Material Theme.
static func generate_theme(input_colors: Dictionary, _font_regular: Font, _font_medium: Font) -> Theme:
	var theme = Theme.new()
	
	# =====================================================
	# 1. Build design-system tokens
	# =====================================================
	## Tokens include colors, sizing, spacing and other Material params
	var tokens = ThemeTokens.build_tokens(input_colors)
	
	# =====================================================
	# 2. Bind component variations
	# =====================================================
	## Variations map component style names to base types
	_bind_variations(theme)
	
	# =====================================================
	# 3. Apply styles to components
	# =====================================================
	ThemeFonts.apply_fonts(theme, _font_regular, _font_medium)   # Apply fonts
	ThemeComponents.apply_panels(theme, tokens)                 # Panels and containers
	ThemeComponents.apply_labels(theme, tokens)                 # Labels
	ThemeInputs.apply_inputs(theme, tokens)                     # Input fields (LineEdit, SpinBox, etc.)
	ThemeButtons.apply_buttons(theme, tokens)                   # Material buttons
	ThemeComponents.apply_tab_buttons(theme, tokens)            # Tab buttons
	ThemeComponents.apply_tab_container(theme, tokens)          # TabContainer
	ThemeComponents.apply_scrollbars(theme, tokens)             # Scrollbars
	ThemeComponents.apply_sliders(theme, tokens)                # Sliders
	ThemeComponents.apply_progress_bars(theme, tokens)          # Progress bars
	ThemeComponents.apply_tree(theme, tokens)                   # Tree
	ThemeComponents.apply_item_list(theme, tokens)              # ItemList
	ThemeComponents.apply_popup_menu(theme, tokens)             # PopupMenu
	ThemeInputs.apply_text_edit(theme, tokens)                  # Multi-line text fields
	
	return theme


# =========================================================
# BIND COMPONENT VARIATIONS
# =========================================================
## Assigns type variations so the Theme recognizes which names map to base types
static func _bind_variations(theme: Theme) -> void:
	# -----------------------------
	# Buttons (Button)
	# -----------------------------
	var button_variations = [
		"FilledButton", "TonalButton", "OutlinedButton", "TextButton", "ElevatedButton",
		"SecondaryButton", "TertiaryButton", "ErrorButton", "SuccessButton", "WarningButton", "InfoButton",
		# Sizing variations
		"ButtonCompact", "ButtonLarge", "OutlinedButtonCompact", "OutlinedButtonLarge",
		"TextButtonCompact", "TextButtonLarge", "ElevatedButtonCompact", "ElevatedButtonLarge",
		"TonalButtonCompact", "TonalButtonLarge",
		# Semantic sizing
		"SecondaryButtonCompact", "SecondaryButtonLarge", "ErrorButtonCompact", "ErrorButtonLarge",
		"SuccessButtonCompact", "SuccessButtonLarge", "WarningButtonCompact", "WarningButtonLarge"
	]
	for v in button_variations:
		theme.set_type_variation(v, "Button")
	
	# -----------------------------
	# Tabs (TabBar)
	# -----------------------------
	theme.set_type_variation("SecondaryTab", "TabBar")
	
	# -----------------------------
	# Panels (Panel)
	# -----------------------------
	var panel_variations = [
		"PanelElevated1", "PanelElevated2", "PanelElevated3",
		"SurfaceContainer", "SurfaceContainerLow", "SurfaceContainerHigh", "SurfaceContainerHighest"
	]
	for v in panel_variations:
		theme.set_type_variation(v, "Panel")
	
	# -----------------------------
	# Input fields (LineEdit)
	# -----------------------------
	theme.set_type_variation("OutlinedLineEdit", "LineEdit")
	theme.set_type_variation("LineEditCompact", "LineEdit")
	theme.set_type_variation("LineEditLarge", "LineEdit")
	
	# -----------------------------
	# Typography (Label)
	# -----------------------------
	var typography_variations = [
		"DisplayLarge", "DisplayMedium", "DisplaySmall",
		"HeaderLarge", "HeaderMedium", "HeaderSmall",
		"TitleLarge", "TitleMedium", "TitleSmall",
		"BodyLarge", "BodyMedium", "BodySmall",
		"LabelLarge", "LabelMedium", "LabelSmall"
	]
	for v in typography_variations:
		theme.set_type_variation(v, "Label")
