extends RefCounted
## Colours and a ready-made Theme for Murim Life.
##
## Use it on the root Control of any screen:
##     const UiTheme = preload("res://ui_pack/murim_theme.gd")
##     theme = UiTheme.make()
## Every Button, Label, panel, bar and text field below that node then shares one look.

const INK = Color("0b1020")
const PANEL = Color("141e30")
const PANEL_LIGHT = Color("20354a")
const PAPER = Color("f1e9d6")
const DIM = Color("a8acb9")
const GOLD = Color("dfbc77")
const RED = Color("d75d6d")
const JADE = Color("70d6c5")


## A flat rounded box. Used for every panel and button state.
static func box(bg, border, margin = 14, radius = 6, border_width = 1):
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


## Builds the Theme. Pass your serif font to use it everywhere.
static func make(font = null):
	var t = Theme.new()
	if font != null:
		t.default_font = font
	t.default_font_size = 20

	# Buttons: quiet gold outline, brighter on hover, pressed-in when held.
	t.set_stylebox("normal", "Button", box(PANEL, Color(GOLD, 0.40)))
	t.set_stylebox("hover", "Button", box(PANEL_LIGHT, Color(GOLD, 0.85)))
	var pressed = box(INK, GOLD, 14, 6, 2)
	pressed.content_margin_top = 15
	pressed.content_margin_bottom = 13
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), JADE, 14, 6, 2))
	t.set_stylebox("disabled", "Button", box(Color(PANEL, 0.6), Color(DIM, 0.25)))
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", PAPER)
	t.set_color("font_focus_color", "Button", PAPER)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", DIM)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(PANEL, Color(GOLD, 0.35), 18))
	t.set_stylebox("panel", "Panel", box(PANEL, Color(GOLD, 0.35), 18))

	# Text
	t.set_color("font_color", "Label", PAPER)
	t.set_color("default_color", "RichTextLabel", PAPER)
	t.set_constant("line_separation", "RichTextLabel", 6)

	# Text fields
	t.set_stylebox("normal", "LineEdit", box(INK, Color(GOLD, 0.40), 12))
	t.set_stylebox("focus", "LineEdit", box(INK, GOLD, 12))
	t.set_color("font_color", "LineEdit", PAPER)
	t.set_color("font_placeholder_color", "LineEdit", DIM)
	t.set_color("caret_color", "LineEdit", GOLD)

	# Bars: red by default. Call UiTheme.tint_bar(bar, UiTheme.JADE) for other colours.
	t.set_stylebox("background", "ProgressBar", box(INK, Color(GOLD, 0.30), 0, 5))
	t.set_stylebox("fill", "ProgressBar", box(RED, RED, 0, 5))

	# Thin gold scrollbars
	var empty = StyleBoxEmpty.new()
	var grabber = box(Color(GOLD, 0.45), Color(0, 0, 0, 0), 3, 3, 0)
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, empty)
		t.set_stylebox("scroll_focus", bar, empty)
		t.set_stylebox("grabber", bar, grabber)
		t.set_stylebox("grabber_highlight", bar, grabber)
		t.set_stylebox("grabber_pressed", bar, grabber)
	return t


## Gives one ProgressBar its own fill colour.
static func tint_bar(bar, color):
	bar.add_theme_stylebox_override("fill", box(color, color, 0, 5))


## A small label, handy for captions and section titles.
static func label(text, size = 20, color = PAPER):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A bar with its text written inside, for Health, Qi and stats.
static func make_bar(color, height = 24):
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	tint_bar(bar, color)
	var text = label("", 14)
	text.name = "Text"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(text)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return bar


## Sets a bar made by make_bar. The fill glides to the new value.
static func set_bar(bar, title, value, max_value, show_max = true):
	bar.max_value = max_value
	var text = "%s  %d / %d" % [title, value, max_value] if show_max else "%s  %d" % [title, value]
	bar.get_node("Text").text = text
	if bar.is_inside_tree():
		bar.create_tween().tween_property(bar, "value", float(value), 0.3)
	else:
		bar.value = value
