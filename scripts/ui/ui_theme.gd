class_name UiTheme
## Builds the shared UI theme and small widget helpers.

const ACCENT := Color(0.12, 0.63, 0.86)
const ACCENT_DARK := Color(0.08, 0.45, 0.66)
const GOOD := Color(0.3, 0.78, 0.42)
const GOLD := Color(0.98, 0.78, 0.26)
const PANEL := Color(0.09, 0.12, 0.2, 0.9)
const PANEL_LIGHT := Color(0.95, 0.96, 0.98)
const TEXT := Color(0.96, 0.97, 1.0)
const TEXT_DARK := Color(0.15, 0.18, 0.26)
const MUTED := Color(0.62, 0.68, 0.78)

static var _theme: Theme
static var font_regular: Font
static var font_bold: Font


static func get_theme() -> Theme:
	if _theme:
		return _theme
	font_regular = load("res://assets/fonts/Nunito-SemiBold.ttf")
	font_bold = load("res://assets/fonts/Nunito-ExtraBold.ttf")
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)

	t.set_stylebox("panel", "PanelContainer", box(PANEL, 16))
	t.set_stylebox("panel", "Panel", box(PANEL, 16))

	t.set_stylebox("normal", "Button", box(ACCENT, 12, 10))
	t.set_stylebox("hover", "Button", box(ACCENT.lightened(0.15), 12, 10))
	t.set_stylebox("pressed", "Button", box(ACCENT_DARK, 12, 10))
	t.set_stylebox("disabled", "Button", box(Color(0.35, 0.4, 0.48, 0.8), 12, 10))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", 19)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.8, 0.82, 0.86))

	t.set_stylebox("slider", "HSlider", box(Color(1, 1, 1, 0.2), 4, 3))
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT, 4, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT.lightened(0.2), 4, 3))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12)
	sb.set_corner_radius_all(6)
	t.set_stylebox("background", "ProgressBar", sb)
	t.set_stylebox("fill", "ProgressBar", box(GOOD, 6, 0))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_stylebox("panel", "TooltipPanel", box(PANEL, 8, 8))
	_theme = t
	return t


## Anchors `c` to a preset point plus an offset; it grows from there to fit.
static func anchor(c: Control, preset: int, off := Vector2.ZERO) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = off.x
	c.offset_right = off.x
	c.offset_top = off.y
	c.offset_bottom = off.y
	var dirs := {
		0.0: Control.GROW_DIRECTION_END,
		1.0: Control.GROW_DIRECTION_BEGIN,
		0.5: Control.GROW_DIRECTION_BOTH
	}
	c.grow_horizontal = dirs[c.anchor_left]
	c.grow_vertical = dirs[c.anchor_top]


static func box(
	c: Color, radius := 12, pad := 14, border := Color.TRANSPARENT, border_w := 0
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.6
	sb.content_margin_bottom = pad * 0.6
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.anti_aliasing = true
	return sb


static func label(text: String, size := 18, color := TEXT, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		get_theme()
		l.add_theme_font_override("font", font_bold)
	return l


static func shadow_label(text: String, size := 18, color := TEXT, bold := true) -> Label:
	var l := label(text, size, color, bold)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 4)
	return l


static func button(text: String, color := ACCENT, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 46)
	if color != ACCENT:
		b.add_theme_stylebox_override("normal", box(color, 12, 10))
		b.add_theme_stylebox_override("hover", box(color.lightened(0.15), 12, 10))
		b.add_theme_stylebox_override("pressed", box(color.darkened(0.2), 12, 10))
	b.pressed.connect(func(): Sfx.play("click"))
	return b


static func icon(path: String, size := 32.0, tint := Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-$" if n < 0 else "$") + s + out
