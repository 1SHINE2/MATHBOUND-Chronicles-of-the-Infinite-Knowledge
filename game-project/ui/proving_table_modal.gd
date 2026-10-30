class_name ProvingTableModal
extends Control
## Matches "The Proving Table_ Spellcraft in a Magical Academy.png" & Magic System v0.10.01:
## - Left Parchment Card: ENVISION ("Review your spell" — Target, Action, Quantity, Phenomenon Switcher)
## - Right Parchment & Navy Card: COMMAND ("Use mathematical units and sigils")
##   - Mathematical Units Selector (Number, Operation, Relation, Variable, Function, Other)
##   - Sigils Palette (Count, Add, Subtract, Multiply, Divide, Equal)
##   - Build Your Expression Bar (Interactive Sigil & Input slots + Clear + Submit Command)
##   - Right Live Inspector: Mathematical Expression & Spell Structure (e.g., Count(6) or Multiply(32, 2))
## - Bottom Pipeline Bar: Envision (Review) -> Command (Build Expression) -> Interpretation (Sprite) -> Response (In-Game Effect)

signal closed()
signal encounter_solved(encounter_id: String)

var current_encounter_id: String = "encounter_floating_stones"
var selected_sigil_id: String = "sigil_count"
var current_inputs: Array = [6]
var current_hint_index: int = 0

var _envision_title_lbl: Label
var _envision_desc_lbl: Label
var _target_lbl: Label
var _action_lbl: Label
var _quantity_lbl: Label
var _temp_badge_lbl: Label

var _sigil_btn_map: Dictionary = {}
var _slot_sigil_lbl: Label
var _slot_input1_spin: SpinBox
var _slot_input2_spin: SpinBox
var _expr_preview_lbl: Label
var _expr_meaning_lbl: Label
var _spell_struct_lbl: Label
var _diagnostic_lbl: Label
var _pipeline_step_labels: Array[Label] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	load_encounter(current_encounter_id)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.06, 0.14, 0.90)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	main_vbox.add_theme_constant_override("separation", 12)
	add_child(main_vbox)

	# 1. Top Header Bar ("The Proving Table — Turn your understanding into a spell.")
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	main_vbox.add_child(header_panel)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 14)
	header_panel.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_vbox)

	var main_title := Label.new()
	main_title.text = "✦ The Proving Table — Two-Table Spellcraft (v0.10.01)"
	main_title.add_theme_font_size_override("font_size", 20)
	main_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	title_vbox.add_child(main_title)

	var sub_title := Label.new()
	sub_title.text = "Turn your mathematical understanding into a formal command that Magic Sprites can interpret and enact."
	sub_title.add_theme_font_size_override("font_size", 12)
	sub_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	title_vbox.add_child(sub_title)

	# Encounter Selector Tabs (Switch between Floating Stones Example & Patterned Gate Requirement)
	var btn_enc1 := Button.new()
	btn_enc1.text = "1. Floating Stones (Counting)"
	UIThemeHelper.style_button(btn_enc1, UIThemeHelper.COLOR_CYAN_GLOW)
	btn_enc1.pressed.connect(func(): load_encounter("encounter_floating_stones"))
	header_hbox.add_child(btn_enc1)

	var btn_enc2 := Button.new()
	btn_enc2.text = "2. Patterned Gate (Sequence)"
	UIThemeHelper.style_button(btn_enc2, UIThemeHelper.COLOR_GOLD_BORDER)
	btn_enc2.pressed.connect(func(): load_encounter("encounter_patterned_gate"))
	header_hbox.add_child(btn_enc2)

	var close_btn := Button.new()
	close_btn.text = "✕ Close [Esc]"
	UIThemeHelper.style_button(close_btn, UIThemeHelper.COLOR_DANGER)
	close_btn.pressed.connect(func():
		AudioManager.play_ui_click()
		closed.emit()
	)
	header_hbox.add_child(close_btn)

	# 2. Center Two-Table Split (Left: ENVISION | Right: COMMAND + Expression Inspector)
	var tables_hbox := HBoxContainer.new()
	tables_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tables_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(tables_hbox)

	# --- LEFT TABLE: ENVISION (Parchment Card) ---
	var envision_card := PanelContainer.new()
	envision_card.custom_minimum_size = Vector2(390, 0)
	envision_card.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_style(UIThemeHelper.COLOR_GOLD_BORDER, 14))
	tables_hbox.add_child(envision_card)

	var env_vbox := VBoxContainer.new()
	env_vbox.add_theme_constant_override("separation", 10)
	envision_card.add_child(env_vbox)

	var env_banner := PanelContainer.new()
	env_banner.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BORDER, 8, 2))
	env_vbox.add_child(env_banner)

	var env_head_lbl := Label.new()
	env_head_lbl.text = "👁  TABLE I — ENVISION (Review Your Spell)"
	env_head_lbl.add_theme_font_size_override("font_size", 15)
	env_head_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	env_banner.add_child(env_head_lbl)

	_temp_badge_lbl = Label.new()
	_temp_badge_lbl.text = "[Modular Example Encounter — Swappable]"
	_temp_badge_lbl.add_theme_font_size_override("font_size", 11)
	_temp_badge_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_DEEP)
	env_vbox.add_child(_temp_badge_lbl)

	_envision_title_lbl = Label.new()
	_envision_title_lbl.add_theme_font_size_override("font_size", 16)
	_envision_title_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	env_vbox.add_child(_envision_title_lbl)

	var preview_box := PanelContainer.new()
	preview_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color("122a4d"), UIThemeHelper.COLOR_GOLD_MUTED, 10, 2))
	env_vbox.add_child(preview_box)

	_envision_desc_lbl = Label.new()
	_envision_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_envision_desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_envision_desc_lbl.add_theme_font_size_override("font_size", 14)
	_envision_desc_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	preview_box.add_child(_envision_desc_lbl)

	# Checklist rows (Target, Action, Quantity)
	_target_lbl = Label.new()
	_target_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	env_vbox.add_child(_target_lbl)

	_action_lbl = Label.new()
	_action_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	env_vbox.add_child(_action_lbl)

	_quantity_lbl = Label.new()
	_quantity_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	env_vbox.add_child(_quantity_lbl)

	var hint_btn := Button.new()
	hint_btn.text = "💡 Request Graduated Hint (1–3)"
	UIThemeHelper.style_button(hint_btn, UIThemeHelper.COLOR_GOLD_BORDER, UIThemeHelper.COLOR_NAVY_HEADER)
	hint_btn.pressed.connect(_on_request_hint)
	env_vbox.add_child(hint_btn)

	# --- RIGHT TABLE: COMMAND (Build Your Expression) ---
	var command_card := PanelContainer.new()
	command_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_card.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_style(UIThemeHelper.COLOR_GOLD_BORDER, 14))
	tables_hbox.add_child(command_card)

	var cmd_vbox := VBoxContainer.new()
	cmd_vbox.add_theme_constant_override("separation", 10)
	command_card.add_child(cmd_vbox)

	var cmd_banner := PanelContainer.new()
	cmd_banner.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BORDER, 8, 2))
	cmd_vbox.add_child(cmd_banner)

	var cmd_head_lbl := Label.new()
	cmd_head_lbl.text = "✒  TABLE II — COMMAND (Use Mathematical Units & Sigils)"
	cmd_head_lbl.add_theme_font_size_override("font_size", 15)
	cmd_head_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	cmd_banner.add_child(cmd_head_lbl)

	var cmd_split := HBoxContainer.new()
	cmd_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cmd_split.add_theme_constant_override("separation", 12)
	cmd_vbox.add_child(cmd_split)

	var builder_col := VBoxContainer.new()
	builder_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	builder_col.add_theme_constant_override("separation", 10)
	cmd_split.add_child(builder_col)

	# Mathematical Units & Sigils Palette
	var palette_panel := PanelContainer.new()
	palette_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_MUTED, 10, 2))
	builder_col.add_child(palette_panel)

	var pal_vbox := VBoxContainer.new()
	pal_vbox.add_theme_constant_override("separation", 8)
	palette_panel.add_child(pal_vbox)

	var pal_title := Label.new()
	pal_title.text = "Select Sigil (Strict Mathematical Equivalence):"
	pal_title.add_theme_font_size_override("font_size", 13)
	pal_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	pal_vbox.add_child(pal_title)

	var sigil_grid := GridContainer.new()
	sigil_grid.columns = 4
	sigil_grid.add_theme_constant_override("h_separation", 8)
	sigil_grid.add_theme_constant_override("v_separation", 8)
	pal_vbox.add_child(sigil_grid)

	for s in MagicManager.get_sigil_list():
		var b := Button.new()
		b.custom_minimum_size = Vector2(105, 52)
		b.text = "%s  %s\n[%s]" % [s["symbol"], s["name"], s["unit_category"]]
		b.add_theme_font_size_override("font_size", 11)
		var sid: String = s["id"]
		b.pressed.connect(func(): _select_proving_sigil(sid))
		sigil_grid.add_child(b)
		_sigil_btn_map[sid] = b

	# Build Your Expression Interactive Box
	var expr_box := PanelContainer.new()
	expr_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	expr_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_CYAN_GLOW, 10, 2))
	builder_col.add_child(expr_box)

	var eb_vbox := VBoxContainer.new()
	eb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	eb_vbox.add_theme_constant_override("separation", 12)
	expr_box.add_child(eb_vbox)

	var eb_title := Label.new()
	eb_title.text = "Build Your Expression (Select Sigil + Input Values):"
	eb_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	eb_vbox.add_child(eb_title)

	var slots_hbox := HBoxContainer.new()
	slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_hbox.add_theme_constant_override("separation", 14)
	eb_vbox.add_child(slots_hbox)

	var sigil_slot := PanelContainer.new()
	sigil_slot.custom_minimum_size = Vector2(110, 64)
	sigil_slot.add_theme_stylebox_override("panel", UIThemeHelper.make_sigil_slot_style(true))
	slots_hbox.add_child(sigil_slot)

	_slot_sigil_lbl = Label.new()
	_slot_sigil_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_sigil_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_sigil_lbl.add_theme_font_size_override("font_size", 16)
	_slot_sigil_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
	sigil_slot.add_child(_slot_sigil_lbl)

	_slot_input1_spin = SpinBox.new()
	_slot_input1_spin.min_value = 0
	_slot_input1_spin.max_value = 256
	_slot_input1_spin.step = 1
	_slot_input1_spin.value = 6
	_slot_input1_spin.custom_minimum_size = Vector2(96, 48)
	_slot_input1_spin.value_changed.connect(func(_v): _refresh_expression_preview())
	slots_hbox.add_child(_slot_input1_spin)

	_slot_input2_spin = SpinBox.new()
	_slot_input2_spin.min_value = 0
	_slot_input2_spin.max_value = 256
	_slot_input2_spin.step = 1
	_slot_input2_spin.value = 2
	_slot_input2_spin.custom_minimum_size = Vector2(96, 48)
	_slot_input2_spin.value_changed.connect(func(_v): _refresh_expression_preview())
	slots_hbox.add_child(_slot_input2_spin)

	var clear_btn := Button.new()
	clear_btn.text = "🗑 Reset"
	UIThemeHelper.style_button(clear_btn)
	clear_btn.pressed.connect(func():
		_slot_input1_spin.value = 1
		_slot_input2_spin.value = 1
		_refresh_expression_preview()
	)
	slots_hbox.add_child(clear_btn)

	# Submit Command Button
	var submit_btn := Button.new()
	submit_btn.custom_minimum_size = Vector2(260, 48)
	submit_btn.text = "✦ Submit Command"
	submit_btn.add_theme_font_size_override("font_size", 16)
	UIThemeHelper.style_button(submit_btn, UIThemeHelper.COLOR_GOLD_BRIGHT, UIThemeHelper.COLOR_CYAN_DEEP)
	submit_btn.pressed.connect(_on_submit_command)
	eb_vbox.add_child(submit_btn)

	# Right Sidebar inside Command: Live Mathematical Expression & Spell Structure Inspector
	var struct_card := PanelContainer.new()
	struct_card.custom_minimum_size = Vector2(240, 0)
	struct_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 10, 2))
	cmd_split.add_child(struct_card)

	var sc_vbox := VBoxContainer.new()
	sc_vbox.add_theme_constant_override("separation", 10)
	struct_card.add_child(sc_vbox)

	var sc_head := Label.new()
	sc_head.text = "Mathematical Expression"
	sc_head.add_theme_font_size_override("font_size", 13)
	sc_head.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	sc_vbox.add_child(sc_head)

	_expr_preview_lbl = Label.new()
	_expr_preview_lbl.add_theme_font_size_override("font_size", 22)
	_expr_preview_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
	sc_vbox.add_child(_expr_preview_lbl)

	_expr_meaning_lbl = Label.new()
	_expr_meaning_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expr_meaning_lbl.add_theme_font_size_override("font_size", 12)
	_expr_meaning_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	sc_vbox.add_child(_expr_meaning_lbl)

	var sep := HSeparator.new()
	sc_vbox.add_child(sep)

	var st_head := Label.new()
	st_head.text = "Spell Structure"
	st_head.add_theme_font_size_override("font_size", 13)
	st_head.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	sc_vbox.add_child(st_head)

	_spell_struct_lbl = Label.new()
	_spell_struct_lbl.add_theme_font_size_override("font_size", 18)
	_spell_struct_lbl.add_theme_color_override("font_color", Color.WHITE)
	sc_vbox.add_child(_spell_struct_lbl)

	# 3. Bottom Pipeline & Diagnostic Feedback Bar
	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_GOLD_BORDER, 10, 2))
	main_vbox.add_child(bottom_panel)

	var bot_vbox := VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bot_vbox)

	var pipe_hbox := HBoxContainer.new()
	pipe_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pipe_hbox.add_theme_constant_override("separation", 24)
	bot_vbox.add_child(pipe_hbox)

	var stages := [
		"1. Envision (Review)",
		"→   2. Command (Build Expression)",
		"→   3. Interpretation (Magic Sprite)",
		"→   4. Response (In-Game Effect)"
	]
	_pipeline_step_labels.clear()
	for st in stages:
		var l := Label.new()
		l.text = st
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)
		pipe_hbox.add_child(l)
		_pipeline_step_labels.append(l)

	_diagnostic_lbl = Label.new()
	_diagnostic_lbl.text = "✦ The right mathematical expression opens new possibilities. Select your Sigil and Input Values above."
	_diagnostic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_diagnostic_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diagnostic_lbl.add_theme_font_size_override("font_size", 13)
	_diagnostic_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	bot_vbox.add_child(_diagnostic_lbl)

func load_encounter(encounter_id: String) -> void:
	if not MagicManager.encounters.has(encounter_id):
		return
	current_encounter_id = encounter_id
	current_hint_index = 0
	var enc: Dictionary = MagicManager.encounters[encounter_id]

	_envision_title_lbl.text = enc["title"]
	_temp_badge_lbl.text = "[Temporary Example Encounter — Swappable]" if enc.get("is_temporary_example", false) else "[Requirement Gate Lock — Progression Milestone]"
	_envision_desc_lbl.text = "%s\n\nCompetency: %s\nInterpreting Sprite: %s" % [
		enc["envision_description"],
		enc["competency"],
		MagicManager.magic_sprites.get(enc["sprite_id"], {}).get("name", "Magic Sprite")
	]
	_target_lbl.text = "✔  Target:      %s" % enc["envision_target"]
	_action_lbl.text = "✔  Action:      %s" % enc["envision_action"]
	_quantity_lbl.text = "✔  Quantity:    %s" % str(enc["envision_quantity"])

	if encounter_id == "encounter_floating_stones":
		_select_proving_sigil("sigil_count")
		_slot_input1_spin.value = 6
	else:
		_select_proving_sigil("sigil_multiply")
		_slot_input1_spin.value = 32
		_slot_input2_spin.value = 2

	_diagnostic_lbl.text = "✦ Ready to evaluate %s. Build your Command expression on the right." % enc["title"]
	_diagnostic_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)

func _select_proving_sigil(sigil_id: String) -> void:
	selected_sigil_id = sigil_id
	MagicManager.select_sigil(sigil_id)
	for sid in _sigil_btn_map:
		var btn: Button = _sigil_btn_map[sid]
		btn.add_theme_stylebox_override("normal", UIThemeHelper.make_sigil_slot_style(sid == sigil_id))
	var s: Dictionary = MagicManager.sigils[sigil_id]
	_slot_sigil_lbl.text = "%s\n%s" % [s["symbol"], s["name"]]
	_slot_input2_spin.visible = int(s["expected_inputs"]) > 1
	_refresh_expression_preview()

func _refresh_expression_preview() -> void:
	var s: Dictionary = MagicManager.sigils[selected_sigil_id]
	var inputs: Array = [int(_slot_input1_spin.value)]
	if int(s["expected_inputs"]) > 1:
		inputs.append(int(_slot_input2_spin.value))
	current_inputs = inputs
	var info := MagicManager.format_expression(selected_sigil_id, inputs)
	_expr_preview_lbl.text = info["display"]
	_expr_meaning_lbl.text = info["meaning"]
	_spell_struct_lbl.text = info["structure"]

func _on_request_hint() -> void:
	AudioManager.play_ui_click()
	var enc: Dictionary = MagicManager.encounters.get(current_encounter_id, {})
	var ladder: Array = enc.get("hint_ladder", [])
	if ladder.is_empty():
		return
	var hint_text: String = ladder[mini(current_hint_index, ladder.size() - 1)]
	current_hint_index = mini(current_hint_index + 1, ladder.size() - 1)
	_diagnostic_lbl.text = "💡 " + hint_text
	_diagnostic_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_CYAN_GLOW)

func _on_submit_command() -> void:
	_refresh_expression_preview()
	var res := MagicManager.evaluate_proving_table_command(current_encounter_id, selected_sigil_id, current_inputs)
	_diagnostic_lbl.text = "%s — %s" % [res["title"], res["diagnostic"]]
	if res["success"]:
		_diagnostic_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_SUCCESS)
		if current_encounter_id == "encounter_floating_stones":
			GameManager.mark_bridge_aligned()
		elif current_encounter_id == "encounter_patterned_gate":
			GameManager.mark_gate_unsealed()
		encounter_solved.emit(current_encounter_id)
	else:
		_diagnostic_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_DANGER)
