extends RefCounted
class_name ThemeFonts

# =========================================================
# TYPOGRAPHY AND FONTS
# =========================================================

static func apply_fonts(theme: Theme, font_regular: Font, font_medium: Font) -> void:
	# Apply Material typography to Godot components
	
	# Body (default text)
	for t_name in ["Label", "RichTextLabel"]:
		theme.set_font("font", t_name, font_regular)
		theme.set_font_size("font_size", t_name, 16)
		theme.set_constant("line_spacing", t_name, 8)
	
	# Buttons - Label Large
	theme.set_font("font", "Button", font_medium)
	theme.set_font_size("font_size", "Button", 14)
	
	# Input Fields - Body Large
	for t_name in ["LineEdit", "TextEdit"]:
		theme.set_font("font", t_name, font_regular)
		theme.set_font_size("font_size", t_name, 16)
	
	# CheckBox, CheckButton, RadioButton - Body Medium
	for t_name in ["CheckBox", "CheckButton", "RadioButton"]:
		theme.set_font("font", t_name, font_regular)
		theme.set_font_size("font_size", t_name, 14)
		
	
	# Create additional variations for the Material type scale
	# Display
	theme.set_font("font", "DisplayLarge", font_regular)
	theme.set_font_size("font_size", "DisplayLarge", 57)
	theme.set_font("font", "DisplayMedium", font_regular)
	theme.set_font_size("font_size", "DisplayMedium", 45)
	theme.set_font("font", "DisplaySmall", font_regular)
	theme.set_font_size("font_size", "DisplaySmall", 36)
	
	# Header
	theme.set_font("font", "HeaderLarge", font_regular)
	theme.set_font_size("font_size", "HeaderLarge", 32)
	theme.set_font("font", "HeaderMedium", font_regular)
	theme.set_font_size("font_size", "HeaderMedium", 28)
	theme.set_font("font", "HeaderSmall", font_regular)
	theme.set_font_size("font_size", "HeaderSmall", 24)
	
	# Title
	theme.set_font("font", "TitleLarge", font_regular)
	theme.set_font_size("font_size", "TitleLarge", 22)
	theme.set_font("font", "TitleMedium", font_medium)
	theme.set_font_size("font_size", "TitleMedium", 16)
	theme.set_font("font", "TitleSmall", font_medium)
	theme.set_font_size("font_size", "TitleSmall", 14)
	
	# Body
	theme.set_font("font", "BodyLarge", font_regular)
	theme.set_font_size("font_size", "BodyLarge", 16)
	theme.set_font("font", "BodyMedium", font_regular)
	theme.set_font_size("font_size", "BodyMedium", 14)
	theme.set_font("font", "BodySmall", font_regular)
	theme.set_font_size("font_size", "BodySmall", 12)
	
	# Label
	theme.set_font("font", "LabelLarge", font_medium)
	theme.set_font_size("font_size", "LabelLarge", 14)
	theme.set_font("font", "LabelMedium", font_medium)
	theme.set_font_size("font_size", "LabelMedium", 12)
	theme.set_font("font", "LabelSmall", font_medium)
	theme.set_font_size("font_size", "LabelSmall", 11)
