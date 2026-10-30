class_name UIThemeHelper
extends RefCounted
## Central styling helper implementing the Royal Navy, Gold Filigree,
## Warm Parchment, and Glowing Cyan aesthetic from the INSPO - IMAGES mockups.

const COLOR_NAVY_DEEP := Color("091326")
const COLOR_NAVY_PANEL := Color("0e1e38")
const COLOR_NAVY_HEADER := Color("13294b")
const COLOR_PARCHMENT := Color("f3ede0")
const COLOR_PARCHMENT_DARK := Color("e2d8c3")
const COLOR_INK_DARK := Color("1c2838")
const COLOR_GOLD_BRIGHT := Color("eab308")
const COLOR_GOLD_BORDER := Color("d4a349")
const COLOR_GOLD_TRIM := Color("d4a349")
const COLOR_GOLD_MUTED := Color("8c6b2d")
const COLOR_CYAN_GLOW := Color("38bdf8")
const COLOR_CYAN_DEEP := Color("0369a1")
const COLOR_TEXT_LIGHT := Color("f8fafc")
const COLOR_TEXT_CREAM := Color("f8fafc")
const COLOR_TEXT_MUTED := Color("94a3b8")
const COLOR_TEXT_DIM := Color("94a3b8")
const COLOR_HP_RED := Color("ef4444")
const COLOR_MANA_BLUE := Color("0ea5e9")
const COLOR_SUCCESS := Color("22c55e")
const COLOR_EMERALD := Color("22c55e")
const COLOR_DANGER := Color("f43f5e")
const COLOR_CRIMSON := Color("f43f5e")

static func make_panel_style(bg: Color = COLOR_NAVY_PANEL, border: Color = COLOR_GOLD_BORDER, corner_radius: int = 10, border_width: int = 2, shadow_size: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = shadow_size
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func make_navy_panel(bg: Color = COLOR_NAVY_PANEL, border: Color = COLOR_GOLD_BORDER, border_width: int = 2, corner_radius: int = 10) -> StyleBoxFlat:
	return make_panel_style(bg, border, corner_radius, border_width, 6)

static func make_parchment_style(border: Color = COLOR_GOLD_BORDER, corner_radius: int = 10) -> StyleBoxFlat:
	return make_panel_style(COLOR_PARCHMENT, border, corner_radius, 2, 4)

static func make_parchment_panel(bg: Color = COLOR_PARCHMENT, border: Color = COLOR_GOLD_BORDER, border_width: int = 2, corner_radius: int = 10) -> StyleBoxFlat:
	return make_panel_style(bg, border, corner_radius, border_width, 4)

static func make_sigil_slot_style(active: bool = false, glow_color: Color = COLOR_CYAN_GLOW) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("102648") if active else Color("0a172e")
	sb.border_color = glow_color if active else COLOR_GOLD_MUTED
	sb.set_border_width_all(3 if active else 2)
	sb.set_corner_radius_all(8)
	if active:
		sb.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.45)
		sb.shadow_size = 8
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

static func style_button(btn: Button, accent: Color = COLOR_GOLD_BORDER, bg: Color = Color("162b4d"), text_col: Color = COLOR_TEXT_LIGHT) -> void:
	var normal := make_panel_style(bg, accent, 8, 2, 2)
	var hover := make_panel_style(bg.lightened(0.15), accent.lightened(0.25), 8, 2, 4)
	var pressed := make_panel_style(bg.darkened(0.15), COLOR_CYAN_GLOW, 8, 2, 1)
	var disabled := make_panel_style(Color("0b1320"), Color("334155"), 8, 1, 0)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", COLOR_CYAN_GLOW)

static func make_label(text_val: String, font_size: int = 14, color: Color = COLOR_TEXT_LIGHT, autowrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	if autowrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

static func make_stylized_button(text_val: String, font_size: int = 13, highlighted: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.add_theme_font_size_override("font_size", font_size)
	var accent := COLOR_CYAN_GLOW if highlighted else COLOR_GOLD_BORDER
	var bg := Color("19355c") if highlighted else Color("11223d")
	style_button(btn, accent, bg, COLOR_TEXT_LIGHT)
	return btn

static func make_gold_button(text_val: String, font_size: int = 14) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.add_theme_font_size_override("font_size", font_size)
	style_button(btn, COLOR_GOLD_BRIGHT, Color("3b2d12"), COLOR_GOLD_BRIGHT)
	return btn
