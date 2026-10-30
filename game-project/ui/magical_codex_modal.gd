class_name MagicalCodexModal
extends Control
## Matches "Magical Codex_ Wind Current.png":
## - Top Header: "MAGICAL CODEX — Discover · Learn · Create" + "Total Spells Unlocked: X / 24"
## - Left Sidebar: Categories (All Spells, Offensive, Defensive, Utility, Exploration, Special) + Quote Box
## - Center Pane: Search bar, Filter dropdowns, 4x3 Spell Card Grid with Level badges & Lock icons
## - Right Inspector: Selected Spell details, description, Command syntax, Required Sigils, Mana/Cooldown/Range/Duration, [Q] Equip & [▶ Cast Preview]

signal closed()

var selected_category: String = "All Spells"
var search_query: String = ""
var selected_spell_id: String = "spell_wind_current"

var _unlocked_count_lbl: Label
var _grid_container: GridContainer
var _cat_buttons: Dictionary = {}

# Right Inspector UI References
var _insp_name_lbl: Label
var _insp_lvl_lbl: Label
var _insp_tags_lbl: Label
var _insp_desc_lbl: Label
var _insp_cmd_lbl: Label
var _insp_sigils_lbl: Label
var _insp_stats_lbl: Label
var _insp_preview_banner: Label
var _equip_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_codex()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.06, 0.13, 0.92)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	# 1. Ornate Top Banner
	var top_bar := PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	root_vbox.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_bar.add_child(top_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "✦ MAGICAL CODEX — Discover · Learn · Create"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	title_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Stores all acquired magical spells, their formal mathematical commands, and required sigils."
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	title_vbox.add_child(sub_lbl)

	_unlocked_count_lbl = Label.new()
	_unlocked_count_lbl.text = "✦ Total Spells Unlocked: 8 / 24"
	_unlocked_count_lbl.add_theme_font_size_override("font_size", 15)
	_unlocked_count_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
	top_hbox.add_child(_unlocked_count_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕ Back [Esc]"
	UIThemeHelper.style_button(close_btn, UIThemeHelper.COLOR_DANGER)
	close_btn.pressed.connect(func():
		AudioManager.play_ui_click()
		closed.emit()
	)
	top_hbox.add_child(close_btn)

	# 2. Main 3-Column Body (Left Sidebar | Center Spell Grid | Right Spell Details)
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 14)
	root_vbox.add_child(body_hbox)

	# --- LEFT SIDEBAR: Categories + Quote Box ---
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(205, 0)
	left_col.add_theme_constant_override("separation", 10)
	body_hbox.add_child(left_col)

	var cat_panel := PanelContainer.new()
	cat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cat_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	left_col.add_child(cat_panel)

	var cat_vbox := VBoxContainer.new()
	cat_vbox.add_theme_constant_override("separation", 8)
	cat_panel.add_child(cat_vbox)

	var categories := ["All Spells", "Offensive", "Defensive", "Utility", "Exploration", "Special"]
	for cat in categories:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 40)
		b.text = "✦  " + cat
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var c_name: String = cat
		b.pressed.connect(func():
			selected_category = c_name
			AudioManager.play_ui_click()
			_refresh_codex()
		)
		cat_vbox.add_child(b)
		_cat_buttons[cat] = b

	# Archive Quote Card (Matches bottom-left of Magical Codex_ Wind Current.png)
	var quote_card := PanelContainer.new()
	quote_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_GOLD_MUTED, 10, 2))
	left_col.add_child(quote_card)

	var quote_lbl := Label.new()
	quote_lbl.text = "\"Mathematics is a language that lets you speak to the world.\"\n\n— The Archives"
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_lbl.add_theme_font_size_override("font_size", 12)
	quote_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	quote_card.add_child(quote_lbl)

	# --- CENTER COLUMN: Search + 4-Column Spell Cards Grid ---
	var center_panel := PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	body_hbox.add_child(center_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 10)
	center_panel.add_child(center_vbox)

	var search_hbox := HBoxContainer.new()
	search_hbox.add_theme_constant_override("separation", 10)
	center_vbox.add_child(search_hbox)

	var search_input := LineEdit.new()
	search_input.placeholder_text = "🔍 Search spells by name, category, or command..."
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.text_changed.connect(func(new_text: String):
		search_query = new_text.strip_edges().to_lower()
		_refresh_codex()
	)
	search_hbox.add_child(search_input)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(scroll)

	_grid_container = GridContainer.new()
	_grid_container.columns = 4
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_container.add_theme_constant_override("h_separation", 10)
	_grid_container.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid_container)

	# --- RIGHT COLUMN: Detailed Spell Inspector ---
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(390, 0)
	right_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	body_hbox.add_child(right_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 10)
	right_panel.add_child(r_vbox)

	var r_top := HBoxContainer.new()
	r_vbox.add_child(r_top)

	_insp_name_lbl = Label.new()
	_insp_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp_name_lbl.add_theme_font_size_override("font_size", 22)
	_insp_name_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	r_top.add_child(_insp_name_lbl)

	_insp_lvl_lbl = Label.new()
	_insp_lvl_lbl.add_theme_font_size_override("font_size", 14)
	_insp_lvl_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
	r_top.add_child(_insp_lvl_lbl)

	_insp_tags_lbl = Label.new()
	_insp_tags_lbl.add_theme_font_size_override("font_size", 12)
	_insp_tags_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	r_vbox.add_child(_insp_tags_lbl)

	_insp_desc_lbl = Label.new()
	_insp_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc_lbl.add_theme_font_size_override("font_size", 13)
	_insp_desc_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	r_vbox.add_child(_insp_desc_lbl)

	# Visual Illustration & Two-Table Summary Box
	var preview_card := PanelContainer.new()
	preview_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color("102544"), UIThemeHelper.COLOR_CYAN_GLOW, 10, 2))
	r_vbox.add_child(preview_card)

	_insp_preview_banner = Label.new()
	_insp_preview_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_preview_banner.add_theme_font_size_override("font_size", 12)
	_insp_preview_banner.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	preview_card.add_child(_insp_preview_banner)

	# Formal Command Syntax Box
	var cmd_box := PanelContainer.new()
	cmd_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color("071020"), UIThemeHelper.COLOR_GOLD_MUTED, 8, 1))
	r_vbox.add_child(cmd_box)

	_insp_cmd_lbl = Label.new()
	_insp_cmd_lbl.add_theme_font_size_override("font_size", 13)
	_insp_cmd_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
	cmd_box.add_child(_insp_cmd_lbl)

	_insp_sigils_lbl = Label.new()
	_insp_sigils_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_sigils_lbl.add_theme_font_size_override("font_size", 12)
	_insp_sigils_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	r_vbox.add_child(_insp_sigils_lbl)

	_insp_stats_lbl = Label.new()
	_insp_stats_lbl.add_theme_font_size_override("font_size", 12)
	_insp_stats_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	r_vbox.add_child(_insp_stats_lbl)

	var actions_hbox := HBoxContainer.new()
	actions_hbox.add_theme_constant_override("separation", 10)
	r_vbox.add_child(actions_hbox)

	_equip_btn = Button.new()
	_equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equip_btn.custom_minimum_size = Vector2(0, 42)
	_equip_btn.text = "✦ [Q] Equip Active Spell"
	UIThemeHelper.style_button(_equip_btn, UIThemeHelper.COLOR_GOLD_BRIGHT, UIThemeHelper.COLOR_CYAN_DEEP)
	_equip_btn.pressed.connect(_on_equip_pressed)
	actions_hbox.add_child(_equip_btn)

	var preview_btn := Button.new()
	preview_btn.custom_minimum_size = Vector2(145, 42)
	preview_btn.text = "▶ Cast Preview"
	UIThemeHelper.style_button(preview_btn, UIThemeHelper.COLOR_CYAN_GLOW)
	preview_btn.pressed.connect(_on_cast_preview_pressed)
	actions_hbox.add_child(preview_btn)

func _refresh_codex() -> void:
	_unlocked_count_lbl.text = "✦ Total Spells Unlocked: %d / 24" % CodexManager.get_unlocked_count()

	for cat in _cat_buttons:
		var btn: Button = _cat_buttons[cat]
		var active: bool = (String(cat) == selected_category)
		UIThemeHelper.style_button(btn, UIThemeHelper.COLOR_CYAN_GLOW if active else UIThemeHelper.COLOR_GOLD_MUTED, Color("163461") if active else UIThemeHelper.COLOR_NAVY_DEEP)

	for child in _grid_container.get_children():
		child.queue_free()

	for spell in CodexManager.get_all_spells():
		if selected_category != "All Spells" and spell["category"] != selected_category:
			continue
		if not search_query.is_empty():
			var hay := ("%s %s %s" % [spell["name"], spell["category"], spell["command_syntax"]]).to_lower()
			if not hay.contains(search_query):
				continue

		var card_btn := Button.new()
		card_btn.custom_minimum_size = Vector2(128, 118)
		var is_sel: bool = (String(spell["id"]) == selected_spell_id)
		var is_unlocked: bool = spell["unlocked"]
		var lock_prefix := "" if is_unlocked else "🔒 "
		var equipped_tag := "\n[EQUIPPED]" if CodexManager.equipped_spell_id == spell["id"] else ""
		card_btn.text = "%s%s\nLv. %d · %s%s" % [lock_prefix, spell["name"], spell["level"], spell["category"], equipped_tag]
		card_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_btn.add_theme_font_size_override("font_size", 12)
		var border_col: Color = UIThemeHelper.COLOR_GOLD_BRIGHT if is_sel else (spell["icon_color"] if is_unlocked else Color("334155"))
		var bg_col := Color("17315c") if is_sel else (Color("0d1f3d") if is_unlocked else Color("07101e"))
		UIThemeHelper.style_button(card_btn, border_col, bg_col)
		var sid: String = spell["id"]
		card_btn.pressed.connect(func():
			selected_spell_id = sid
			AudioManager.play_ui_click()
			_refresh_codex()
		)
		_grid_container.add_child(card_btn)

	_update_inspector()

func _update_inspector() -> void:
	if not CodexManager.spells.has(selected_spell_id):
		return
	var sp: Dictionary = CodexManager.spells[selected_spell_id]
	var unlocked: bool = sp["unlocked"]
	_insp_name_lbl.text = sp["name"] if unlocked else ("🔒 " + sp["name"] + " (Locked)")
	_insp_lvl_lbl.text = "Lv. %d" % int(sp["level"])
	_insp_tags_lbl.text = "%s  •  Tags: %s" % [sp["category"], ", ".join(sp["tags"])]
	_insp_desc_lbl.text = sp["description"]

	var env: Dictionary = sp.get("envision", {})
	_insp_preview_banner.text = "TABLE I — ENVISION:\n• Intent: %s\n• Target Effect: %s\n• Mathematical Model: %s\n\nSPRITE INTERPRETATION:\n%s\n\nPHYSICAL RESPONSE:\n%s" % [
		env.get("intent", ""),
		env.get("target_effect", ""),
		env.get("conceptual_shape", ""),
		sp.get("interpretation", ""),
		sp.get("response", "")
	]

	_insp_cmd_lbl.text = "⚙ Command:   %s" % sp["command_syntax"]

	var sig_parts: PackedStringArray = []
	for req in sp.get("required_sigils", []):
		sig_parts.append("%s %s" % [req["name"], req["symbol"]])
	_insp_sigils_lbl.text = "✦ Required Sigils:   " + "  +  ".join(sig_parts)

	_insp_stats_lbl.text = "Mana Cost: %d   |   Cooldown: %s   |   Range: %s   |   Duration: %s" % [
		int(sp["mana_cost"]),
		str(sp["cooldown"]),
		str(sp["range"]),
		str(sp["duration"])
	]

	_equip_btn.disabled = not unlocked
	if CodexManager.equipped_spell_id == selected_spell_id:
		_equip_btn.text = "✓ Currently Equipped [K]"
	elif unlocked:
		_equip_btn.text = "✦ [Q] Equip Spell for Active Play"
	else:
		_equip_btn.text = "🔒 Solve Encounter / Side Quest to Unlock"

func _on_equip_pressed() -> void:
	CodexManager.equip_spell(selected_spell_id)
	_refresh_codex()

func _on_cast_preview_pressed() -> void:
	AudioManager.play_spell_cast()
	var sp: Dictionary = CodexManager.spells.get(selected_spell_id, {})
	_insp_preview_banner.text = "✨ [CAST PREVIEW EXECUTED]\n\nCommand Sent: %s\n\n%s\n\nResult: %s" % [
		sp.get("command_syntax", ""),
		sp.get("interpretation", ""),
		sp.get("response", "")
	]
