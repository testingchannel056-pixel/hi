extends RefCounted

# The look of the whole game, kept in one place.
#
# It starts from the theme in ui_pack/murim_theme.gd (buttons, panels, bars,
# text fields and scrollbars) and adds the pieces only this game has: the big
# gold button, the stat chips, the bottom dock, the small hint text, titles,
# the badge and the pop-up card.
#
# Every colour comes from murim_theme.gd. To change a colour everywhere in
# the game, change it there.
#
# A node asks for one of the extra pieces by name. In the editor that is
# Inspector > Theme > Type Variation; in code it is
#     label.theme_type_variation = "HintLabel"
#
# The theme is put on when the game starts (see apply_look() in game.gd), so
# in the editor the scenes look plain. Press F5 to see the real thing.

const UiTheme = preload("res://ui_pack/murim_theme.gd")
const FONT = preload("res://EBGaramond-VariableFont_wght.ttf")

const TEXT_SIZE = 24    # ordinary text and buttons
const HINT_SIZE = 18    # the small line under a choice
const TITLE_SIZE = 30   # the title of a pop-up

# The colour of each stat's bar, in the Profile and on the New Life screen.
# They are the ones ui_pack/character_creator.gd uses.
const BAR_COLOURS = {
	"Health": UiTheme.RED,
	"Smarts": Color("5f86a8"),
	"Looks": Color("a8658c"),
	"Happiness": Color("b08a3c"),
	"Willpower": UiTheme.JADE,
}


static func make():
	var theme = UiTheme.make(FONT)
	theme.default_font_size = TEXT_SIZE
	theme.set_font_size("font_size", "Button", TEXT_SIZE)
	theme.set_font_size("normal_font_size", "RichTextLabel", TEXT_SIZE)
	theme.set_color("icon_disabled_color", "Button", Color(1, 1, 1, 0.3))
	# A button that is switched on (your gender, birth and talent on the New
	# Life screen) keeps its lit look while the mouse is over it.
	theme.set_stylebox("hover_pressed", "Button", theme.get_stylebox("pressed", "Button"))

	# The big gold button: "+ Age" and "Begin this life".
	theme.set_type_variation("AgeButton", "Button")
	theme.set_stylebox("normal", "AgeButton", UiTheme.box(UiTheme.GOLD, UiTheme.GOLD))
	theme.set_stylebox("hover", "AgeButton", UiTheme.box(UiTheme.GOLD.lightened(0.15), UiTheme.GOLD))
	theme.set_stylebox("pressed", "AgeButton", UiTheme.box(UiTheme.GOLD.darkened(0.2), UiTheme.GOLD))
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "AgeButton", UiTheme.INK)
	theme.set_font_size("font_size", "AgeButton", 30)

	# A stat chip under the header, and the text in it.
	var chip = UiTheme.box(UiTheme.INK, Color(UiTheme.GOLD, 0.2), 10, 5)
	chip.content_margin_top = 6
	chip.content_margin_bottom = 6
	theme.set_type_variation("Chip", "PanelContainer")
	theme.set_stylebox("panel", "Chip", chip)
	theme.set_type_variation("ChipLabel", "Label")
	theme.set_font_size("font_size", "ChipLabel", HINT_SIZE)

	# The bar at the bottom of the screen, and the buttons in it.
	theme.set_type_variation("Dock", "PanelContainer")
	theme.set_stylebox("panel", "Dock", UiTheme.box(UiTheme.PANEL, Color(UiTheme.GOLD, 0.35), 6, 8))
	var plain = StyleBoxEmpty.new()
	plain.set_content_margin_all(6)
	plain.content_margin_top = 8
	var lit = UiTheme.box(UiTheme.PANEL_LIGHT, Color(UiTheme.GOLD, 0.0), 6, 6)
	lit.content_margin_top = 8
	theme.set_type_variation("DockButton", "Button")
	theme.set_stylebox("normal", "DockButton", plain)
	theme.set_stylebox("disabled", "DockButton", plain)
	theme.set_stylebox("hover", "DockButton", lit)
	theme.set_stylebox("pressed", "DockButton", lit)
	theme.set_font_size("font_size", "DockButton", 17)

	# Small, quiet text: the line under a choice, a caption.
	theme.set_type_variation("HintLabel", "Label")
	theme.set_color("font_color", "HintLabel", UiTheme.DIM)
	theme.set_font_size("font_size", "HintLabel", HINT_SIZE)

	# A gold title.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_color("font_color", "TitleLabel", UiTheme.GOLD)
	theme.set_font_size("font_size", "TitleLabel", TITLE_SIZE)

	# The small gold badge with your cultivation stage in it.
	var badge = UiTheme.box(Color(UiTheme.GOLD, 0.12), UiTheme.GOLD, 14, 16)
	badge.content_margin_top = 4
	badge.content_margin_bottom = 4
	theme.set_type_variation("Badge", "PanelContainer")
	theme.set_stylebox("panel", "Badge", badge)
	theme.set_type_variation("BadgeLabel", "Label")
	theme.set_color("font_color", "BadgeLabel", UiTheme.GOLD)
	theme.set_font_size("font_size", "BadgeLabel", 16)

	# The card of a pop-up (Profile, Settings, Menu).
	var card = UiTheme.box(UiTheme.PANEL, Color(UiTheme.GOLD, 0.7), 26, 8)
	card.shadow_color = Color(0, 0, 0, 0.5)
	card.shadow_size = 16
	theme.set_type_variation("PopupCard", "PanelContainer")
	theme.set_stylebox("panel", "PopupCard", card)

	# The thin line between the story and the choices.
	var line = StyleBoxLine.new()
	line.color = Color(UiTheme.GOLD, 0.35)
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_constant("separation", "HSeparator", 1)

	# Sliders on the New Life screen: a dark groove that fills with gold.
	var groove = UiTheme.box(UiTheme.INK, Color(UiTheme.GOLD, 0.3), 3, 3)
	var filled = UiTheme.box(UiTheme.GOLD, UiTheme.GOLD, 3, 3)
	theme.set_stylebox("slider", "HSlider", groove)
	theme.set_stylebox("grabber_area", "HSlider", filled)
	theme.set_stylebox("grabber_area_highlight", "HSlider", filled)
	return theme


# A colour written as text, such as "#c9a961". The story on the page needs
# its colours this way: [color=#c9a961]gold words[/color].
static func hex(color):
	return "#" + color.to_html(false)
