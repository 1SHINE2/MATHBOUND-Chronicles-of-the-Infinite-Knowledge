class_name CharacterCrestBanner
extends Control
## High-detail Gacha/Wish-style Vertical Crest Character Selection Banner
## Strictly modeled on the 2nd reference image (Event Wish Preview vertical crests):
## - Pointed ogee-arch top frame where the character's hat/hair pops out above the border.
## - Multi-layered anime-style character illustration (shaded face, expressive anime eyes
##   with iris gradients & catchlights, layered hair locks, ornate academy attire, and hand spell).
## - Golden "UP!" badge on the right shoulder above the name.
## - Bold white Character Name + 5 Golden Stars (★★★★★) over a soft dark vignette.
## - Wide cream-and-gold pointed hexagonal title ribbon ("Meditative Scholar", "Calculative Scholar", etc.).
## - Scalloped white-and-gold filigree bottom tail point with a glowing circular Sigil Emblem.

signal banner_pressed(char_id: String)

var char_id: String = "SAMANTHA"
var char_name: String = "Samantha Yu"
var role_title: String = "Meditative Scholar"
var sigil_symbol: String = "✦"
var primary_color: Color = Color("38bdf8")
var secondary_color: Color = Color("1e3a8a")
var is_playable: bool = true
var is_selected: bool = false
var is_inspected: bool = false
var is_hovered: bool = false
var anim_time: float = 0.0


func setup(
	p_id: String,
	p_name: String,
	p_role: String,
	p_sigil: String,
	p_primary: Color,
	p_secondary: Color,
	p_playable: bool = true
) -> void:
	char_id = p_id
	char_name = p_name
	role_title = p_role
	sigil_symbol = p_sigil
	primary_color = p_primary
	secondary_color = p_secondary
	is_playable = p_playable
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func _ready() -> void:
	mouse_entered.connect(func() -> void:
		is_hovered = true
		AudioManager.play_tone(660.0, 0.03, 0.12)
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		is_hovered = false
		queue_redraw()
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		banner_pressed.emit(char_id)
		accept_event()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		anim_time += delta
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var font := ThemeDB.fallback_font

	var y_off := -14.0 if is_inspected else (-8.0 if is_selected else (-5.0 if is_hovered else 0.0))

	var top_y := 26.0 + y_off
	var arch_shoulder_y := 64.0 + y_off
	var waist_y := h - 102.0 + y_off
	var rib_mid_y := h - 84.0 + y_off
	var rib_bot_y := h - 66.0 + y_off
	var tail_mid_y := h - 38.0 + y_off
	var bot_y := h - 8.0 + y_off
	var mx := 12.0

	# 1. Outer Pointed-Arch Crest Polygon (Matches 2nd Reference Image Silhouette)
	var upper_crest := PackedVector2Array([
		Vector2(cx, top_y),
		Vector2(cx + (w * 0.24), top_y + 14.0),
		Vector2(w - mx, arch_shoulder_y),
		Vector2(w - mx, waist_y),
		Vector2(mx, waist_y),
		Vector2(mx, arch_shoulder_y),
		Vector2(cx - (w * 0.24), top_y + 14.0)
	])

	# Outer Selection / Hover Aura Glow
	if is_selected or is_inspected or is_hovered:
		var glow_alpha := 0.55 if is_inspected else (0.38 if is_selected else 0.24)
		var glow_col := Color(primary_color.r, primary_color.g, primary_color.b, glow_alpha)
		var glow_poly := PackedVector2Array([
			Vector2(cx, top_y - 8.0),
			Vector2(w - mx + 7.0, arch_shoulder_y - 4.0),
			Vector2(w - mx + 7.0, waist_y + 4.0),
			Vector2(cx, bot_y + 8.0),
			Vector2(mx - 7.0, waist_y + 4.0),
			Vector2(mx - 7.0, arch_shoulder_y - 4.0)
		])
		draw_colored_polygon(glow_poly, glow_col)

	# 2. Inner Elemental Gradient Backdrop inside Upper Crest
	draw_colored_polygon(upper_crest, secondary_color.darkened(0.25))

	var inner_upper := PackedVector2Array([
		Vector2(cx, top_y + 5.0),
		Vector2(cx + (w * 0.22), top_y + 18.0),
		Vector2(w - mx - 4.0, arch_shoulder_y + 3.0),
		Vector2(w - mx - 4.0, waist_y),
		Vector2(mx + 4.0, waist_y),
		Vector2(mx + 4.0, arch_shoulder_y + 3.0),
		Vector2(cx - (w * 0.22), top_y + 18.0)
	])
	draw_colored_polygon(inner_upper, secondary_color)

	# Radiant Elemental Aura behind Character Portrait
	var aura_c := Vector2(cx, top_y + 125.0)
	var pulse := 1.0 + 0.04 * sin(anim_time * 3.0)
	draw_circle(aura_c, 74.0 * pulse, Color(primary_color.r, primary_color.g, primary_color.b, 0.22))
	draw_circle(aura_c, 54.0 * pulse, Color(primary_color.r, primary_color.g, primary_color.b, 0.35))
	draw_arc(aura_c, 64.0, 0.0, TAU, 36, Color(1.0, 0.95, 0.75, 0.40), 1.6)

	# Four-pointed sparkle stars in background
	var sparkles: Array[Vector2] = [
		Vector2(-56, -68), Vector2(58, -58), Vector2(-64, 8), Vector2(62, 16), Vector2(-42, -92), Vector2(46, -86)
	]
	for sp: Vector2 in sparkles:
		_draw_four_point_sparkle(aura_c + sp, 4.5, Color(1, 1, 1, 0.8))

	# 3. Ornate Double-Border around Upper Crest (drawn BEFORE character head pop-out so hat/hair overlaps top!)
	var frame_col := Color("fde047") if (is_selected or is_inspected) else (Color("ffffff") if is_hovered else Color("e2e8f0"))
	var closed_upper := PackedVector2Array(upper_crest)
	closed_upper.append(upper_crest[0])
	draw_polyline(closed_upper, frame_col, 3.2 if (is_selected or is_inspected) else 2.4)
	draw_polyline(closed_upper, Color("d4a349"), 1.2)

	# 4. Rich Anime-Style Character Illustration (Head & Hat Pop Out over the Top Arch!)
	_draw_anime_character_portrait(Vector2(cx, waist_y), Vector2(cx, top_y + 114.0))

	# 5. Lower Scalloped Filigree Tail (Below the Ribbon Plaque, matching 2nd Reference Image!)
	var outer_tail := PackedVector2Array([
		Vector2(mx + 2.0, rib_bot_y - 2.0),
		Vector2(w - mx - 2.0, rib_bot_y - 2.0),
		Vector2(w - mx - 8.0, tail_mid_y),
		Vector2(cx, bot_y),
		Vector2(mx + 8.0, tail_mid_y)
	])
	draw_colored_polygon(outer_tail, Color("f8fafc"))

	var inner_tail := PackedVector2Array([
		Vector2(mx + 8.0, rib_bot_y + 2.0),
		Vector2(w - mx - 8.0, rib_bot_y + 2.0),
		Vector2(w - mx - 14.0, tail_mid_y - 2.0),
		Vector2(cx, bot_y - 7.0),
		Vector2(mx + 14.0, tail_mid_y - 2.0)
	])
	draw_colored_polygon(inner_tail, primary_color.darkened(0.35))
	var closed_tail := PackedVector2Array(outer_tail)
	closed_tail.append(outer_tail[0])
	draw_polyline(closed_tail, Color("d4a349"), 2.2)

	# 6. Lower Torso Dark Gradient Vignette (for crisp Name & 5-Star legibility)
	var vig_top := waist_y - 68.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(mx + 3.0, vig_top),
		Vector2(w - mx - 3.0, vig_top),
		Vector2(w - mx - 3.0, waist_y),
		Vector2(mx + 3.0, waist_y)
	]), Color(0.02, 0.05, 0.14, 0.68))

	# 7. Golden "UP!" Badge on Right Side (Exact match to 2nd image!)
	if is_playable:
		var up_pos := Vector2(w - mx - 46.0, waist_y - 56.0)
		draw_string(font, up_pos + Vector2(1, 1), "UP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0, 0, 0, 0.9))
		draw_string(font, up_pos, "UP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("facc15"))

	# 8. Character Name & 5 Golden Stars (★★★★★)
	var name_y := waist_y - 30.0
	draw_string(font, Vector2(mx + 1.0, name_y + 1.0), char_name, HORIZONTAL_ALIGNMENT_CENTER, w - mx * 2.0, 18, Color(0, 0, 0, 0.92))
	draw_string(font, Vector2(mx, name_y), char_name, HORIZONTAL_ALIGNMENT_CENTER, w - mx * 2.0, 18, Color.WHITE)

	var star_count := 5 if is_playable else 4
	var star_spacing := 16.0
	var stars_start_x := cx - (float(star_count - 1) * star_spacing) * 0.5
	for s_i in range(star_count):
		_draw_gold_star(Vector2(stars_start_x + float(s_i) * star_spacing, waist_y - 14.0), 6.2)

	# 9. Wide Cream-Parchment & Gold-Trimmed Pointed Hexagonal Title Plaque (Matches 2nd image!)
	var ribbon_pts := PackedVector2Array([
		Vector2(mx + 2.0, waist_y - 2.0),
		Vector2(w - mx - 2.0, waist_y - 2.0),
		Vector2(w - 1.0, rib_mid_y),
		Vector2(w - mx - 2.0, rib_bot_y),
		Vector2(mx + 2.0, rib_bot_y),
		Vector2(1.0, rib_mid_y)
	])
	draw_colored_polygon(ribbon_pts, Color("f7f2e4"))

	# Inner gold hairline inside the cream ribbon plaque
	var inner_rib := PackedVector2Array([
		Vector2(mx + 5.0, waist_y + 1.5),
		Vector2(w - mx - 5.0, waist_y + 1.5),
		Vector2(w - 5.0, rib_mid_y),
		Vector2(w - mx - 5.0, rib_bot_y - 1.5),
		Vector2(mx + 5.0, rib_bot_y - 1.5),
		Vector2(5.0, rib_mid_y)
	])
	var closed_inner_rib := PackedVector2Array(inner_rib)
	closed_inner_rib.append(inner_rib[0])
	draw_polyline(closed_inner_rib, Color("c89d42"), 1.3)

	var closed_rib := PackedVector2Array(ribbon_pts)
	closed_rib.append(ribbon_pts[0])
	draw_polyline(closed_rib, Color("a1741f"), 2.2)

	draw_string(font, Vector2(8.0, rib_mid_y + 5.0), role_title, HORIZONTAL_ALIGNMENT_CENTER, w - 16.0, 13, Color("27272a"))

	# 10. Glowing Elemental / Mathematical Sigil Medallion in the Bottom Tail
	var medal_c := Vector2(cx, (rib_bot_y + bot_y) * 0.5 - 2.0)
	draw_circle(medal_c, 17.0, primary_color.darkened(0.45))
	draw_circle(medal_c, 13.5, primary_color)
	draw_circle(medal_c + Vector2(-4, -4), 5.0, primary_color.lightened(0.45))
	draw_arc(medal_c, 16.5, 0.0, TAU, 24, Color("fef08a"), 2.0)
	draw_string(font, medal_c + Vector2(-14.0, 6.0), sigil_symbol, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 16, Color.WHITE)

	# 11. Active "SELECTED" Top Pill if this is the active protagonist
	if is_selected and is_playable:
		var pill_rect := Rect2(cx - 46.0, top_y - 22.0, 92.0, 18.0)
		draw_rect(pill_rect, Color("0f172a"), true)
		draw_rect(pill_rect, Color("fde047"), false, 1.5)
		draw_string(font, Vector2(cx - 46.0, top_y - 8.0), "✓ LEAD SCHOLAR", HORIZONTAL_ALIGNMENT_CENTER, 92.0, 10, Color("fde047"))


# ==============================================================================
# MULTI-LAYERED ANIME-STYLE CHARACTER ILLUSTRATIONS
# ==============================================================================
func _draw_anime_character_portrait(waist_center: Vector2, head_center: Vector2) -> void:
	match char_id:
		"SAMANTHA":
			_draw_portrait_samantha(waist_center, head_center)
		"MIGUEL":
			_draw_portrait_miguel(waist_center, head_center)
		"AURI":
			_draw_portrait_auri(waist_center, head_center)
		"ORON":
			_draw_portrait_oron(waist_center, head_center)
		_:
			_draw_portrait_lyra(waist_center, head_center)


func _draw_portrait_samantha(waist_c: Vector2, head_c: Vector2) -> void:
	# Back Flowing Silver-Blue Twin Locks
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-28, -8),
		head_c + Vector2(-48, 75),
		head_c + Vector2(-18, 85),
		head_c + Vector2(-10, 12)
	]), Color("93c5fd"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(28, -8),
		head_c + Vector2(50, 75),
		head_c + Vector2(18, 85),
		head_c + Vector2(10, 12)
	]), Color("93c5fd"))

	# Ornate Royal Navy & Sapphire Tailcoat (Furina-inspired Academy Regalia)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-24, 30),
		head_c + Vector2(24, 30),
		waist_c + Vector2(62, 0),
		waist_c + Vector2(-62, 0)
	]), Color("172554"))
	# Lapels
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-22, 30),
		head_c + Vector2(-4, 68),
		waist_c + Vector2(-28, 0),
		waist_c + Vector2(-46, 0)
	]), Color("1d4ed8"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(22, 30),
		head_c + Vector2(4, 68),
		waist_c + Vector2(28, 0),
		waist_c + Vector2(46, 0)
	]), Color("1d4ed8"))

	# White Ruffled Ascot & Glowing Hydro/Cyan Cravat Gem
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-14, 28),
		head_c + Vector2(14, 28),
		waist_c + Vector2(20, 0),
		waist_c + Vector2(-20, 0)
	]), Color("f8fafc"))
	draw_circle(head_c + Vector2(0, 44), 8.0, Color("0284c7"))
	draw_circle(head_c + Vector2(0, 44), 5.0, Color("7dd3fc"))
	draw_arc(head_c + Vector2(0, 44), 8.5, 0, TAU, 16, Color("fde047"), 1.8)

	# Neck & Shaded Anime Face Contour (Pointed Chin)
	draw_rect(Rect2(head_c.x - 7, head_c.y + 16, 14, 16), Color("f5cbb7"))
	_draw_anime_face_base(head_c, Color("ffe4d6"), Color("f5cbb7"))

	# Heterochromia Hydro Anime Eyes (Deep Sapphire Left, Glowing Cyan Right)
	_draw_anime_eye(head_c + Vector2(-11, 2), Color("1d4ed8"), Color("60a5fa"), true)
	_draw_anime_eye(head_c + Vector2(11, 2), Color("0284c7"), Color("7dd3fc"), false)
	# Cheerful confident smile
	draw_arc(head_c + Vector2(0, 12), 4.5, 0.15, PI - 0.15, 10, Color("be123c"), 1.8)

	# Layered White-Blue Front Hair Bangs & Side Framing Locks
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-28, -14),
		head_c + Vector2(-16, -28),
		head_c + Vector2(0, -30),
		head_c + Vector2(18, -28),
		head_c + Vector2(28, -12),
		head_c + Vector2(20, 4),
		head_c + Vector2(8, -12),
		head_c + Vector2(0, 2),
		head_c + Vector2(-10, -12),
		head_c + Vector2(-22, 4)
	]), Color("e0f2fe"))

	# Jaunty Tilted Royal Blue & Gold Arch-Scholar Top Hat (Pops OUT above the crest arch!)
	var brim_pts := PackedVector2Array([
		head_c + Vector2(-36, -18),
		head_c + Vector2(38, -28),
		head_c + Vector2(30, -38),
		head_c + Vector2(-30, -28)
	])
	draw_colored_polygon(brim_pts, Color("172554"))
	draw_polyline(brim_pts, Color("fde047"), 2.0)

	var crown_pts := PackedVector2Array([
		head_c + Vector2(-20, -28),
		head_c + Vector2(24, -34),
		head_c + Vector2(30, -72),
		head_c + Vector2(-14, -64)
	])
	draw_colored_polygon(crown_pts, Color("1d4ed8"))
	draw_line(head_c + Vector2(-19, -32), head_c + Vector2(24, -38), Color("facc15"), 4.0)
	# Hat Cockade Bow & Glowing Feather Plume breaking out above the frame
	draw_circle(head_c + Vector2(16, -46), 8.5, Color("38bdf8"))
	draw_circle(head_c + Vector2(16, -46), 4.5, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-14, -60),
		head_c + Vector2(-28, -82),
		head_c + Vector2(-6, -74)
	]), Color("f8fafc"))


func _draw_portrait_miguel(waist_c: Vector2, head_c: Vector2) -> void:
	# Dynamic Crimson & Obsidian Calculative Scholar Coat with Gold Epaulettes
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-26, 30),
		head_c + Vector2(26, 30),
		waist_c + Vector2(64, 0),
		waist_c + Vector2(-64, 0)
	]), Color("450a0a"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-20, 30),
		head_c + Vector2(20, 30),
		waist_c + Vector2(34, 0),
		waist_c + Vector2(-34, 0)
	]), Color("991b1b"))
	# Gold Geometric Collar & Scarf
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-18, 26),
		head_c + Vector2(18, 26),
		head_c + Vector2(10, 62),
		head_c + Vector2(-10, 62)
	]), Color("f59e0b"))
	draw_circle(head_c + Vector2(0, 44), 6.5, Color("fef08a"))

	# Neck & Shaded Anime Face Contour
	draw_rect(Rect2(head_c.x - 7, head_c.y + 16, 14, 16), Color("eab69f"))
	_draw_anime_face_base(head_c, Color("f9dccb"), Color("eab69f"))

	# Sharp Crimson-Amber Calculative Anime Eyes
	_draw_anime_eye(head_c + Vector2(-11, 2), Color("b91c1c"), Color("fbbf24"), true)
	_draw_anime_eye(head_c + Vector2(11, 2), Color("b91c1c"), Color("fbbf24"), false)
	draw_line(head_c + Vector2(-4, 13), head_c + Vector2(5, 12), Color("9a3412"), 1.8)

	# Spiky Platinum-Blonde & Autumn-Maple Layered Hair (Kazuha-inspired silhouette with crimson streak!)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-34, -10),
		head_c + Vector2(-28, -36),
		head_c + Vector2(-8, -46),
		head_c + Vector2(14, -44),
		head_c + Vector2(34, -28),
		head_c + Vector2(36, -4),
		head_c + Vector2(22, 8),
		head_c + Vector2(14, -12),
		head_c + Vector2(2, 4),
		head_c + Vector2(-8, -14),
		head_c + Vector2(-24, 6)
	]), Color("fef3c7"))
	# Iconic Crimson Hair Streak
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(4, -36),
		head_c + Vector2(16, -32),
		head_c + Vector2(22, 2),
		head_c + Vector2(12, -4)
	]), Color("dc2626"))
	# Top ahoge hair lock popping above crest
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-4, -44),
		head_c + Vector2(10, -68),
		head_c + Vector2(14, -42)
	]), Color("fde68a"))

	# Floating Golden Multiplication Astrolabe Ring in front of chest
	var orb_p := head_c + Vector2(30, 56)
	draw_arc(orb_p, 18.0, 0.0, TAU, 24, Color("fde047"), 2.2)
	draw_circle(orb_p, 5.5, Color("f59e0b"))


func _draw_portrait_auri(waist_c: Vector2, head_c: Vector2) -> void:
	# Celestial Sprite Priestess / Crystalline Spirit Silhouette (Kokomi-inspired pastel blue & pearl palette)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-24, 28),
		head_c + Vector2(24, 28),
		waist_c + Vector2(56, 0),
		waist_c + Vector2(-56, 0)
	]), Color("0c4a6e"))
	# Flowing Pearl-Pink & Cyan Ribbon Sleeves
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-14, 28),
		head_c + Vector2(14, 28),
		waist_c + Vector2(24, 0),
		waist_c + Vector2(-24, 0)
	]), Color("e0f2fe"))
	draw_circle(head_c + Vector2(0, 42), 7.5, Color("38bdf8"))

	# Pastel Coral-Blonde Flowing Twin-Tails
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-26, -12),
		head_c + Vector2(-46, 70),
		head_c + Vector2(-20, 78)
	]), Color("fed7aa"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(26, -12),
		head_c + Vector2(46, 70),
		head_c + Vector2(20, 78)
	]), Color("fed7aa"))

	_draw_anime_face_base(head_c, Color("fff1e6"), Color("f5cbb7"))
	_draw_anime_eye(head_c + Vector2(-10, 2), Color("0284c7"), Color("a5f3fc"), true)
	_draw_anime_eye(head_c + Vector2(10, 2), Color("0284c7"), Color("a5f3fc"), false)
	draw_arc(head_c + Vector2(0, 12), 3.8, 0.2, PI - 0.2, 8, Color("f43f5e"), 1.6)

	# Bangs & Crystalline Sprite Fin Headpiece
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-28, -12),
		head_c + Vector2(0, -34),
		head_c + Vector2(28, -12),
		head_c + Vector2(16, 2),
		head_c + Vector2(0, -10),
		head_c + Vector2(-16, 2)
	]), Color("ffedd5"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-20, -28),
		head_c + Vector2(-32, -52),
		head_c + Vector2(-8, -36)
	]), Color("38bdf8"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(20, -28),
		head_c + Vector2(32, -52),
		head_c + Vector2(8, -36)
	]), Color("38bdf8"))


func _draw_portrait_oron(waist_c: Vector2, head_c: Vector2) -> void:
	# Sovereign Violet & Gold Arch-Keeper Regalia (Raiden-inspired violet palette)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-26, 28),
		head_c + Vector2(26, 28),
		waist_c + Vector2(60, 0),
		waist_c + Vector2(-60, 0)
	]), Color("2e1065"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-14, 28),
		head_c + Vector2(14, 28),
		waist_c + Vector2(22, 0),
		waist_c + Vector2(-22, 0)
	]), Color("7e22ce"))
	draw_circle(head_c + Vector2(0, 44), 7.0, Color("fde047"))

	_draw_anime_face_base(head_c, Color("f9dccb"), Color("e2b298"))
	_draw_anime_eye(head_c + Vector2(-10, 2), Color("6b21a8"), Color("d8b4fe"), true)
	_draw_anime_eye(head_c + Vector2(10, 2), Color("6b21a8"), Color("d8b4fe"), false)

	# Silver-Indigo Scholar Hair & Golden Astrolabe Crown
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-30, -12),
		head_c + Vector2(-18, -38),
		head_c + Vector2(18, -38),
		head_c + Vector2(30, -12),
		head_c + Vector2(20, 6),
		head_c + Vector2(0, -12),
		head_c + Vector2(-20, 6)
	]), Color("c4b5fd"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-14, -36),
		head_c + Vector2(0, -64),
		head_c + Vector2(14, -36)
	]), Color("facc15"))


func _draw_portrait_lyra(waist_c: Vector2, head_c: Vector2) -> void:
	# Sakura-Rose & Gold Harmonic Arch-Scholar Shrine Attire (Yae-inspired rose & white palette)
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-26, 28),
		head_c + Vector2(26, 28),
		waist_c + Vector2(58, 0),
		waist_c + Vector2(-58, 0)
	]), Color("881337"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-16, 28),
		head_c + Vector2(16, 28),
		waist_c + Vector2(28, 0),
		waist_c + Vector2(-28, 0)
	]), Color("fff1f2"))
	draw_circle(head_c + Vector2(0, 42), 6.5, Color("f43f5e"))

	# Flowing Rose-Pink Hair Locks
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-28, -10),
		head_c + Vector2(-48, 72),
		head_c + Vector2(-18, 80)
	]), Color("fda4af"))
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(28, -10),
		head_c + Vector2(48, 72),
		head_c + Vector2(18, 80)
	]), Color("fda4af"))

	_draw_anime_face_base(head_c, Color("fff1e6"), Color("f5cbb7"))
	_draw_anime_eye(head_c + Vector2(-10, 2), Color("be185d"), Color("f472b6"), true)
	_draw_anime_eye(head_c + Vector2(10, 2), Color("be185d"), Color("f472b6"), false)
	draw_arc(head_c + Vector2(0, 12), 4.0, 0.2, PI - 0.2, 8, Color("e11d48"), 1.6)

	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-30, -12),
		head_c + Vector2(0, -38),
		head_c + Vector2(30, -12),
		head_c + Vector2(18, 4),
		head_c + Vector2(0, -12),
		head_c + Vector2(-18, 4)
	]), Color("fecdd3"))
	# Golden Hair Ornament popping above top arch
	draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-16, -34),
		head_c + Vector2(0, -58),
		head_c + Vector2(16, -34)
	]), Color("fde047"))


func _draw_anime_face_base(head_c: Vector2, skin_col: Color, shadow_col: Color) -> void:
	var face_pts := PackedVector2Array([
		head_c + Vector2(-23, -12),
		head_c + Vector2(23, -12),
		head_c + Vector2(21, 6),
		head_c + Vector2(12, 18),
		head_c + Vector2(0, 24),
		head_c + Vector2(-12, 18),
		head_c + Vector2(-21, 6)
	])
	draw_colored_polygon(face_pts, skin_col)
	# Subtle blush on cheeks
	draw_circle(head_c + Vector2(-13, 8), 4.5, Color(0.96, 0.55, 0.55, 0.28))
	draw_circle(head_c + Vector2(13, 8), 4.5, Color(0.96, 0.55, 0.55, 0.28))
	# Chin outline shadow
	draw_line(head_c + Vector2(-12, 18), head_c + Vector2(0, 24), shadow_col, 1.5)
	draw_line(head_c + Vector2(0, 24), head_c + Vector2(12, 18), shadow_col, 1.5)


func _draw_anime_eye(eye_c: Vector2, upper_iris: Color, lower_iris: Color, is_left: bool) -> void:
	# Sclera
	draw_circle(eye_c, 5.6, Color.WHITE)
	# Upper & lower iris gradient circles
	draw_circle(eye_c + Vector2(0, -0.5), 4.4, upper_iris)
	draw_circle(eye_c + Vector2(0, 1.2), 3.2, lower_iris)
	# Dark pupil
	draw_circle(eye_c, 2.0, Color("0f172a"))
	# Specular catchlights
	draw_circle(eye_c + Vector2(-1.8, -1.8), 1.6, Color.WHITE)
	draw_circle(eye_c + Vector2(1.5, 1.5), 0.9, Color.WHITE)
	# Thick upper eyelash arch
	var lash_tilt := -1.5 if is_left else 1.5
	draw_line(eye_c + Vector2(-6.0, -3.5 - lash_tilt * 0.3), eye_c + Vector2(6.0, -3.5 + lash_tilt * 0.3), Color("1e1b4b"), 2.4)


func _draw_gold_star(center: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI * 0.5 + float(i) * (TAU / 10.0)
		var rad := r if (i % 2 == 0) else (r * 0.44)
		pts.append(center + Vector2(cos(ang) * rad, sin(ang) * rad))
	draw_colored_polygon(pts, Color("facc15"))


func _draw_four_point_sparkle(center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r * 0.28, -r * 0.28),
		center + Vector2(r, 0),
		center + Vector2(r * 0.28, r * 0.28),
		center + Vector2(0, r),
		center + Vector2(-r * 0.28, r * 0.28),
		center + Vector2(-r, 0),
		center + Vector2(-r * 0.28, -r * 0.28)
	])
	draw_colored_polygon(pts, col)
