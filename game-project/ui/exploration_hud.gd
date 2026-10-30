class_name ExplorationHUD
extends Control
## Matches "Floating Path Counting Spell Tutorial.png":
## - Top-Left: Character Portrait, Level Badge (Lv. 3), Red HP bar, Blue Mana bar, Swap Protagonist button
## - Below Top-Left: Magic Sprite Auri Companion Banner ("Look at the floating rocks...")
## - Top-Right: Active Quest Tracker Banner ("The Floating Path • Count the floating rocks (0/6)")
## - Bottom-Left: Circular Minimap with North compass, islands, and player arrow
## - Bottom-Center: Available Sigils Dock (Count, Add, Subtract, Multiply, Divide, Greater Than, Less Than)
## - Bottom-Right: Quick "Construct Your Spell" Widget + Context Action Prompts ([E], [C] Codex, [Tab] Book)

signal open_proving_table_pressed()
signal open_magical_codex_pressed()
signal open_digital_book_pressed()
signal open_chalkboard_pressed()
signal quick_spell_submitted(sigil_id: String, input_value: int)

var world_ref: AcademyWorldView

var _lvl_label: Label
var _name_label: Label
var _hp_bar: ProgressBar
var _mana_bar: ProgressBar
var _sprite_msg_label: Label
var _quest_title_label: Label
var _quest_obj_label: Label
var _interact_label: Label
var _equipped_spell_btn: Button

var _quick_sigil_btn: Button
var _quick_value_label: Label
var _quick_value: int = 6
var _sigil_buttons: Dictionary = {}
var _minimap_canvas: Control
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_hud()

	GameManager.player_stats_changed.connect(_on_stats_changed)
	GameManager.protagonist_changed.connect(_on_protagonist_changed)
	GameManager.quest_updated.connect(_on_quest_updated)
	MagicManager.active_sigil_changed.connect(_on_sigil_changed)
	CodexManager.equipped_spell_changed.connect(_on_equipped_spell_changed)
	BookManager.archive_entry_unlocked.connect(_on_archive_unlocked)

	_refresh_all()

func _process(delta: float) -> void:
	if _minimap_canvas:
		_minimap_canvas.queue_redraw()
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel:
			_toast_panel.visible = false

func _build_hud() -> void:
	# 1. TOP-LEFT: Portrait, Level, HP/Mana Bars & Magic Sprite Banner
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(18, 16)
	top_left.add_theme_constant_override("separation", 10)
	add_child(top_left)

	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	status_card.custom_minimum_size = Vector2(340, 86)
	top_left.add_child(status_card)

	var status_hbox := HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 12)
	status_card.add_child(status_hbox)

	# Portrait Box + Lv Badge
	var portrait_vbox := VBoxContainer.new()
	portrait_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	status_hbox.add_child(portrait_vbox)

	var swap_btn := Button.new()
	swap_btn.text = "✦ Swap"
	swap_btn.tooltip_text = "Switch Lead Scholar (Samantha Yu / Miguel Perez)"
	UIThemeHelper.style_button(swap_btn, UIThemeHelper.COLOR_GOLD_BORDER, UIThemeHelper.COLOR_NAVY_HEADER)
	swap_btn.pressed.connect(func(): GameManager.swap_protagonist())
	portrait_vbox.add_child(swap_btn)

	_lvl_label = Label.new()
	_lvl_label.text = "Lv. 3"
	_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	portrait_vbox.add_child(_lvl_label)

	# Bars VBox
	var bars_vbox := VBoxContainer.new()
	bars_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars_vbox.add_theme_constant_override("separation", 6)
	status_hbox.add_child(bars_vbox)

	_name_label = Label.new()
	_name_label.text = "Samantha Yu (Meditative)"
	_name_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	bars_vbox.add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.custom_minimum_size = Vector2(200, 16)
	_hp_bar.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = UIThemeHelper.COLOR_HP_RED
	hp_fill.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	bars_vbox.add_child(_hp_bar)

	_mana_bar = ProgressBar.new()
	_mana_bar.max_value = 100
	_mana_bar.value = 100
	_mana_bar.custom_minimum_size = Vector2(180, 14)
	_mana_bar.show_percentage = false
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = UIThemeHelper.COLOR_MANA_BLUE
	mana_fill.set_corner_radius_all(4)
	_mana_bar.add_theme_stylebox_override("fill", mana_fill)
	bars_vbox.add_child(_mana_bar)

	# Magic Sprite Companion Speech Banner (Matches Floating Path mockup)
	var sprite_card := PanelContainer.new()
	sprite_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color(0.05, 0.12, 0.24, 0.92), UIThemeHelper.COLOR_CYAN_GLOW, 10, 2))
	sprite_card.custom_minimum_size = Vector2(350, 74)
	top_left.add_child(sprite_card)

	var sprite_hbox := HBoxContainer.new()
	sprite_hbox.add_theme_constant_override("separation", 10)
	sprite_card.add_child(sprite_hbox)

	var sprite_icon := Label.new()
	sprite_icon.text = "🧚"
	sprite_icon.add_theme_font_size_override("font_size", 26)
	sprite_hbox.add_child(sprite_icon)

	_sprite_msg_label = Label.new()
	_sprite_msg_label.text = "Look at the floating rocks. Count them, then use the counting sigil to cast a spell!"
	_sprite_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sprite_msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sprite_msg_label.add_theme_font_size_override("font_size", 13)
	_sprite_msg_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	sprite_hbox.add_child(_sprite_msg_label)

	# 2. TOP-RIGHT: Active Quest Banner & Top Menu Buttons
	var top_right := VBoxContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right.add_theme_constant_override("separation", 8)
	add_child(top_right)

	var quest_card := PanelContainer.new()
	quest_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 10, 2))
	quest_card.custom_minimum_size = Vector2(330, 72)
	top_right.add_child(quest_card)

	var q_vbox := VBoxContainer.new()
	quest_card.add_child(q_vbox)

	_quest_title_label = Label.new()
	_quest_title_label.text = "✦ The Floating Path"
	_quest_title_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	_quest_title_label.add_theme_font_size_override("font_size", 15)
	q_vbox.add_child(_quest_title_label)

	_quest_obj_label = Label.new()
	_quest_obj_label.text = "• Count the floating rocks (0/6)"
	_quest_obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_obj_label.add_theme_font_size_override("font_size", 12)
	_quest_obj_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	q_vbox.add_child(_quest_obj_label)

	# Quick Access Bar for Proving Table, Magical Codex, Digital Book & Chalkboard
	var nav_hbox := HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_END
	nav_hbox.add_theme_constant_override("separation", 6)
	top_right.add_child(nav_hbox)

	var btn_proving := Button.new()
	btn_proving.text = "📐 Proving Table [P]"
	UIThemeHelper.style_button(btn_proving, UIThemeHelper.COLOR_CYAN_GLOW)
	btn_proving.pressed.connect(func(): open_proving_table_pressed.emit())
	nav_hbox.add_child(btn_proving)

	var btn_codex := Button.new()
	btn_codex.text = "✨ Magical Codex [C]"
	UIThemeHelper.style_button(btn_codex, UIThemeHelper.COLOR_GOLD_BORDER)
	btn_codex.pressed.connect(func(): open_magical_codex_pressed.emit())
	nav_hbox.add_child(btn_codex)

	var btn_book := Button.new()
	btn_book.text = "📖 Digital Book [Tab]"
	UIThemeHelper.style_button(btn_book, UIThemeHelper.COLOR_GOLD_BORDER)
	btn_book.pressed.connect(func(): open_digital_book_pressed.emit())
	nav_hbox.add_child(btn_book)

	# 3. BOTTOM-LEFT: Circular Minimap
	var minimap_holder := PanelContainer.new()
	minimap_holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	minimap_holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	minimap_holder.custom_minimum_size = Vector2(150, 150)
	var mm_style := UIThemeHelper.make_panel_style(Color("081529"), UIThemeHelper.COLOR_GOLD_BORDER, 75, 3)
	minimap_holder.add_theme_stylebox_override("panel", mm_style)
	add_child(minimap_holder)

	_minimap_canvas = Control.new()
	_minimap_canvas.custom_minimum_size = Vector2(126, 126)
	_minimap_canvas.draw.connect(_draw_minimap)
	minimap_holder.add_child(_minimap_canvas)

	# 4. BOTTOM-CENTER: Available Sigils Dock (Matches Floating Path Counting Spell Tutorial.png)
	var sigil_dock := PanelContainer.new()
	sigil_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sigil_dock.offset_left = 250
	sigil_dock.offset_right = -360
	sigil_dock.offset_top = -108
	sigil_dock.offset_bottom = -14
	sigil_dock.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	add_child(sigil_dock)

	var dock_vbox := VBoxContainer.new()
	dock_vbox.add_theme_constant_override("separation", 4)
	sigil_dock.add_child(dock_vbox)

	var dock_title := Label.new()
	dock_title.text = "Available Sigils (Click or Press 1–7)"
	dock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dock_title.add_theme_font_size_override("font_size", 11)
	dock_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	dock_vbox.add_child(dock_title)

	var sigil_hbox := HBoxContainer.new()
	sigil_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sigil_hbox.add_theme_constant_override("separation", 8)
	dock_vbox.add_child(sigil_hbox)

	for s in MagicManager.get_sigil_list():
		if s["id"] == "sigil_equal":
			continue # Keep the 7 exact dock sigils from the mockup
		var sbtn := Button.new()
		sbtn.custom_minimum_size = Vector2(78, 52)
		sbtn.text = "%s\n%s" % [s["symbol"], s["name"]]
		sbtn.add_theme_font_size_override("font_size", 11)
		var sid: String = s["id"]
		sbtn.pressed.connect(func(): MagicManager.select_sigil(sid))
		sigil_hbox.add_child(sbtn)
		_sigil_buttons[sid] = sbtn

	# 5. BOTTOM-RIGHT: "Construct Your Spell" Quick Widget & Context Prompt
	var bottom_right := VBoxContainer.new()
	bottom_right.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	bottom_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bottom_right.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_right.add_theme_constant_override("separation", 8)
	add_child(bottom_right)

	var construct_card := PanelContainer.new()
	construct_card.custom_minimum_size = Vector2(320, 148)
	construct_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	bottom_right.add_child(construct_card)

	var cc_vbox := VBoxContainer.new()
	cc_vbox.add_theme_constant_override("separation", 8)
	construct_card.add_child(cc_vbox)

	var cc_header := HBoxContainer.new()
	cc_vbox.add_child(cc_header)

	var cc_title := Label.new()
	cc_title.text = "Construct Your Spell"
	cc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc_title.add_theme_font_size_override("font_size", 14)
	cc_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	cc_header.add_child(cc_title)

	_equipped_spell_btn = Button.new()
	_equipped_spell_btn.text = "[K] Wind Current"
	_equipped_spell_btn.add_theme_font_size_override("font_size", 11)
	UIThemeHelper.style_button(_equipped_spell_btn, UIThemeHelper.COLOR_CYAN_GLOW)
	_equipped_spell_btn.pressed.connect(func(): open_magical_codex_pressed.emit())
	cc_header.add_child(_equipped_spell_btn)

	var expr_hbox := HBoxContainer.new()
	expr_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	expr_hbox.add_theme_constant_override("separation", 8)
	cc_vbox.add_child(expr_hbox)

	_quick_sigil_btn = Button.new()
	_quick_sigil_btn.custom_minimum_size = Vector2(68, 46)
	_quick_sigil_btn.text = "✦\nCount"
	UIThemeHelper.style_button(_quick_sigil_btn, UIThemeHelper.COLOR_CYAN_GLOW)
	_quick_sigil_btn.pressed.connect(func(): open_proving_table_pressed.emit())
	expr_hbox.add_child(_quick_sigil_btn)

	var minus_btn := Button.new()
	minus_btn.text = "◀"
	UIThemeHelper.style_button(minus_btn)
	minus_btn.pressed.connect(func():
		_quick_value = maxi(1, _quick_value - 1)
		_quick_value_label.text = str(_quick_value)
		AudioManager.play_ui_click()
	)
	expr_hbox.add_child(minus_btn)

	var val_panel := PanelContainer.new()
	val_panel.custom_minimum_size = Vector2(62, 42)
	val_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_sigil_slot_style(true))
	expr_hbox.add_child(val_panel)

	_quick_value_label = Label.new()
	_quick_value_label.text = "6"
	_quick_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quick_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quick_value_label.add_theme_font_size_override("font_size", 18)
	val_panel.add_child(_quick_value_label)

	var plus_btn := Button.new()
	plus_btn.text = "▶"
	UIThemeHelper.style_button(plus_btn)
	plus_btn.pressed.connect(func():
		_quick_value = mini(99, _quick_value + 1)
		_quick_value_label.text = str(_quick_value)
		AudioManager.play_ui_click()
	)
	expr_hbox.add_child(plus_btn)

	var cast_quick_btn := Button.new()
	cast_quick_btn.text = "✦ Cast"
	UIThemeHelper.style_button(cast_quick_btn, UIThemeHelper.COLOR_GOLD_BRIGHT, UIThemeHelper.COLOR_CYAN_DEEP)
	cast_quick_btn.pressed.connect(func():
		quick_spell_submitted.emit(MagicManager.selected_sigil_id, _quick_value)
	)
	expr_hbox.add_child(cast_quick_btn)

	# Context Prompt Banner
	var prompt_panel := PanelContainer.new()
	prompt_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color(0.04, 0.09, 0.18, 0.9), UIThemeHelper.COLOR_GOLD_MUTED, 8, 1))
	bottom_right.add_child(prompt_panel)

	_interact_label = Label.new()
	_interact_label.text = "[WASD] Move   [J] Strike   [K] Spell   [E] Interact"
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.add_theme_font_size_override("font_size", 12)
	_interact_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	prompt_panel.add_child(_interact_label)

	# 6. Top-Center Archive Notification Toast
	_toast_panel = PanelContainer.new()
	_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 18)
	_toast_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BRIGHT, 10, 2))
	_toast_panel.visible = false
	add_child(_toast_panel)

	_toast_label = Label.new()
	_toast_label.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	_toast_panel.add_child(_toast_label)

func set_interact_prompt(prompt_text: String) -> void:
	if prompt_text.is_empty():
		_interact_label.text = "[WASD] Move   [J] Strike   [K] Codex Spell   [Space] Dodge"
	else:
		_interact_label.text = prompt_text

func set_sprite_message(msg: String) -> void:
	if _sprite_msg_label:
		_sprite_msg_label.text = msg

func show_toast(msg: String) -> void:
	_toast_label.text = "📜 " + msg
	_toast_panel.visible = true
	_toast_timer = 3.5

func _refresh_all() -> void:
	_on_protagonist_changed(GameManager.protagonist_id)
	_on_stats_changed(GameManager.player_hp, GameManager.player_max_hp, GameManager.player_mana, GameManager.player_max_mana, GameManager.player_level)
	_on_quest_updated(GameManager.quest)
	_on_sigil_changed(MagicManager.selected_sigil_id)
	_on_equipped_spell_changed(CodexManager.equipped_spell_id)

func _on_protagonist_changed(_id: String) -> void:
	var p := GameManager.get_active_profile()
	_name_label.text = "%s (%s)" % [p["name"], p["thinking_style"].split(" ")[0]]

func _on_stats_changed(hp: int, max_hp: int, mana: int, max_mana: int, level: int) -> void:
	_lvl_label.text = "Lv. %d" % level
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_mana_bar.max_value = max_mana
	_mana_bar.value = mana

func _on_quest_updated(q: Dictionary) -> void:
	_quest_title_label.text = "✦ " + str(q.get("title", "The Floating Path"))
	for obj in q.get("objectives", []):
		if not obj["completed"]:
			_quest_obj_label.text = "• " + str(obj["description"])
			return
	_quest_obj_label.text = "✓ All Outpost Objectives Complete! Enter the Grand Archive!"

func _on_sigil_changed(sigil_id: String) -> void:
	for sid in _sigil_buttons:
		var btn: Button = _sigil_buttons[sid]
		var active: bool = (String(sid) == sigil_id)
		btn.add_theme_stylebox_override("normal", UIThemeHelper.make_sigil_slot_style(active))
	if MagicManager.sigils.has(sigil_id):
		var s: Dictionary = MagicManager.sigils[sigil_id]
		_quick_sigil_btn.text = "%s\n%s" % [s["symbol"], s["name"]]

func _on_equipped_spell_changed(_spell_id: String) -> void:
	var sp := CodexManager.get_equipped_spell()
	_equipped_spell_btn.text = "[K] %s" % sp["name"]

func _on_archive_unlocked(_id: String, title: String) -> void:
	show_toast("Recorded in Digital Book: %s" % title)

func _draw_minimap() -> void:
	var c := _minimap_canvas.size * 0.5
	var r := minf(c.x, c.y) - 4.0
	_minimap_canvas.draw_circle(c, r, Color("0c2340"))
	# Isometric diamond sectors on minimap (Study Hall, Foyer, East Courtyard, Sequence Sanctum)
	var hall_pts := PackedVector2Array([
		c + Vector2(-24, -18),
		c + Vector2(-4, -8),
		c + Vector2(-24, 14),
		c + Vector2(-46, 2)
	])
	_minimap_canvas.draw_colored_polygon(hall_pts, Color("a87442"))
	var foyer_pts := PackedVector2Array([
		c + Vector2(-4, -8),
		c + Vector2(8, -2),
		c + Vector2(-12, 20),
		c + Vector2(-24, 14)
	])
	_minimap_canvas.draw_colored_polygon(foyer_pts, Color("cbd5e1"))
	var east_pts := PackedVector2Array([
		c + Vector2(18, -4),
		c + Vector2(44, 10),
		c + Vector2(22, 30),
		c + Vector2(-4, 16)
	])
	_minimap_canvas.draw_colored_polygon(east_pts, Color("cbbba0"))
	var sanctum_pts := PackedVector2Array([
		c + Vector2(32, -26),
		c + Vector2(48, -16),
		c + Vector2(34, -2),
		c + Vector2(18, -12)
	])
	_minimap_canvas.draw_colored_polygon(sanctum_pts, Color("334155"))
	if GameManager.bridge_aligned:
		_minimap_canvas.draw_line(c + Vector2(-2, 8), c + Vector2(12, 14), UIThemeHelper.COLOR_CYAN_GLOW, 3.5)
	# Player dot
	if world_ref:
		var px := clampf(remap(world_ref.player_pos.x, 220.0, 2000.0, c.x - r + 14.0, c.x + r - 14.0), c.x - r + 10.0, c.x + r - 10.0)
		var py := clampf(remap(world_ref.player_pos.y, 120.0, 1000.0, c.y - r + 14.0, c.y + r - 14.0), c.y - r + 10.0, c.y + r - 10.0)
		_minimap_canvas.draw_circle(Vector2(px, py), 4.5, UIThemeHelper.COLOR_CYAN_GLOW)
	var font := ThemeDB.fallback_font
	_minimap_canvas.draw_string(font, Vector2(c.x - 5, 14), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, UIThemeHelper.COLOR_GOLD_BRIGHT)
