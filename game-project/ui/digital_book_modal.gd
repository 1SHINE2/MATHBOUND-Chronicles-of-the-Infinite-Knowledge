class_name DigitalBookModal
extends Control
## Implements the canonical Three-Layer Digital Book Architecture (Story Bible v0.09 Section 33):
## 1. CHRONICLE (Narrative chapters, dual reflections from Samantha & Miguel, clickable Archive annotations)
## 2. KNOWLEDGE (Discovered mathematical structures, Discovery Loop, and direct bridge to the Magical Codex)
## 3. ARCHIVE (5 Categories: People, Places, Documents [3-Question Inquiry], Objects, Words + End-of-Volume Side Quests)

signal closed()
signal open_magical_codex_requested()

var active_layer: String = "CHRONICLE"
var selected_chapter_id: String = "chronicle_ch1"
var selected_archive_cat: String = "All"
var selected_archive_id: String = "documents_five_rules"

var _layer_btns: Dictionary = {}
var _chronicle_pane: Control
var _knowledge_pane: Control
var _archive_pane: Control

# Chronicle UI
var _ch_list_vbox: VBoxContainer
var _ch_title_lbl: Label
var _ch_body_lbl: Label
var _ch_refl_samantha_lbl: Label
var _ch_refl_miguel_lbl: Label
var _ch_annot_hbox: HBoxContainer

# Knowledge UI
var _know_list_vbox: VBoxContainer

# Archive UI
var _arch_cat_hbox: HBoxContainer
var _arch_list_vbox: VBoxContainer
var _arch_detail_lbl: Label
var _arch_inquiry_lbl: Label
var _sidequest_status_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	switch_layer(active_layer)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.06, 0.13, 0.92)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	# Top Header Bar with 3-Layer Segmented Tabs
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_HEADER, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	root_vbox.add_child(header)

	var h_hbox := HBoxContainer.new()
	h_hbox.add_theme_constant_override("separation", 12)
	header.add_child(h_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_hbox.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "📖 Chronicles of the Infinite Knowledge — Three-Layer Digital Book (v0.09)"
	title_lbl.add_theme_font_size_override("font_size", 19)
	title_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	title_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "1. Chronicle (Experience the Story)  ·  2. Knowledge (Understand What Was Discovered)  ·  3. Archive (Supplementary Reference & Side Quests)"
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_MUTED)
	title_vbox.add_child(sub_lbl)

	for layer_info in [
		{"id": "CHRONICLE", "label": "1. Chronicle"},
		{"id": "KNOWLEDGE", "label": "2. Knowledge"},
		{"id": "ARCHIVE", "label": "3. Archive & Side Quests"}
	]:
		var b := Button.new()
		b.text = layer_info["label"]
		var lid: String = layer_info["id"]
		b.pressed.connect(func():
			AudioManager.play_ui_click()
			switch_layer(lid)
		)
		h_hbox.add_child(b)
		_layer_btns[lid] = b

	var codex_bridge_btn := Button.new()
	codex_bridge_btn.text = "✨ Magical Codex"
	UIThemeHelper.style_button(codex_bridge_btn, UIThemeHelper.COLOR_CYAN_GLOW)
	codex_bridge_btn.pressed.connect(func():
		AudioManager.play_ui_click()
		open_magical_codex_requested.emit()
	)
	h_hbox.add_child(codex_bridge_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Close [Esc]"
	UIThemeHelper.style_button(close_btn, UIThemeHelper.COLOR_DANGER)
	close_btn.pressed.connect(func():
		AudioManager.play_ui_click()
		closed.emit()
	)
	h_hbox.add_child(close_btn)

	# Layer Content Holder
	var content_holder := Control.new()
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(content_holder)

	_build_chronicle_layer(content_holder)
	_build_knowledge_layer(content_holder)
	_build_archive_layer(content_holder)

func _build_chronicle_layer(parent: Control) -> void:
	_chronicle_pane = HBoxContainer.new()
	_chronicle_pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chronicle_pane.add_theme_constant_override("separation", 14)
	parent.add_child(_chronicle_pane)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(310, 0)
	left_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	_chronicle_pane.add_child(left_panel)

	_ch_list_vbox = VBoxContainer.new()
	_ch_list_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(_ch_list_vbox)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_style(UIThemeHelper.COLOR_GOLD_BORDER, 12))
	_chronicle_pane.add_child(right_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 12)
	right_panel.add_child(r_vbox)

	_ch_title_lbl = Label.new()
	_ch_title_lbl.add_theme_font_size_override("font_size", 20)
	_ch_title_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	r_vbox.add_child(_ch_title_lbl)

	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r_vbox.add_child(body_scroll)

	_ch_body_lbl = Label.new()
	_ch_body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ch_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ch_body_lbl.add_theme_font_size_override("font_size", 14)
	_ch_body_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	body_scroll.add_child(_ch_body_lbl)

	# Dual Protagonist Reflections (Samantha vs Miguel)
	var refl_hbox := HBoxContainer.new()
	refl_hbox.add_theme_constant_override("separation", 12)
	r_vbox.add_child(refl_hbox)

	var sam_box := PanelContainer.new()
	sam_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sam_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_CYAN_GLOW, 8, 2))
	refl_hbox.add_child(sam_box)

	_ch_refl_samantha_lbl = Label.new()
	_ch_refl_samantha_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ch_refl_samantha_lbl.add_theme_font_size_override("font_size", 12)
	_ch_refl_samantha_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	sam_box.add_child(_ch_refl_samantha_lbl)

	var mig_box := PanelContainer.new()
	mig_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mig_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BRIGHT, 8, 2))
	refl_hbox.add_child(mig_box)

	_ch_refl_miguel_lbl = Label.new()
	_ch_refl_miguel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ch_refl_miguel_lbl.add_theme_font_size_override("font_size", 12)
	_ch_refl_miguel_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	mig_box.add_child(_ch_refl_miguel_lbl)

	_ch_annot_hbox = HBoxContainer.new()
	_ch_annot_hbox.add_theme_constant_override("separation", 8)
	r_vbox.add_child(_ch_annot_hbox)

func _build_knowledge_layer(parent: Control) -> void:
	_knowledge_pane = PanelContainer.new()
	_knowledge_pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_knowledge_pane.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	parent.add_child(_knowledge_pane)

	var scroll := ScrollContainer.new()
	_knowledge_pane.add_child(scroll)

	_know_list_vbox = VBoxContainer.new()
	_know_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_know_list_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(_know_list_vbox)

func _build_archive_layer(parent: Control) -> void:
	_archive_pane = VBoxContainer.new()
	_archive_pane.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_archive_pane.add_theme_constant_override("separation", 10)
	parent.add_child(_archive_pane)

	_arch_cat_hbox = HBoxContainer.new()
	_arch_cat_hbox.add_theme_constant_override("separation", 8)
	_archive_pane.add_child(_arch_cat_hbox)

	for cat in ["All", "People", "Places", "Documents", "Objects", "Words", "Volume Side Quests"]:
		var b := Button.new()
		b.text = cat
		var c_str: String = cat
		b.pressed.connect(func():
			selected_archive_cat = c_str
			AudioManager.play_ui_click()
			_refresh_archive_layer()
		)
		_arch_cat_hbox.add_child(b)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	_archive_pane.add_child(split)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(330, 0)
	left_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_BORDER, 12, 2))
	split.add_child(left_panel)

	var l_scroll := ScrollContainer.new()
	left_panel.add_child(l_scroll)

	_arch_list_vbox = VBoxContainer.new()
	_arch_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arch_list_vbox.add_theme_constant_override("separation", 6)
	l_scroll.add_child(_arch_list_vbox)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_style(UIThemeHelper.COLOR_GOLD_BORDER, 12))
	split.add_child(right_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 10)
	right_panel.add_child(r_vbox)

	_arch_detail_lbl = Label.new()
	_arch_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_arch_detail_lbl.add_theme_font_size_override("font_size", 14)
	_arch_detail_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
	r_vbox.add_child(_arch_detail_lbl)

	var inq_card := PanelContainer.new()
	inq_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inq_card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_PANEL, UIThemeHelper.COLOR_GOLD_MUTED, 10, 2))
	r_vbox.add_child(inq_card)

	_arch_inquiry_lbl = Label.new()
	_arch_inquiry_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_arch_inquiry_lbl.add_theme_font_size_override("font_size", 13)
	_arch_inquiry_lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
	inq_card.add_child(_arch_inquiry_lbl)

func switch_layer(layer: String) -> void:
	active_layer = layer
	for lid in _layer_btns:
		var btn: Button = _layer_btns[lid]
		var active: bool = (String(lid) == layer)
		UIThemeHelper.style_button(btn, UIThemeHelper.COLOR_CYAN_GLOW if active else UIThemeHelper.COLOR_GOLD_MUTED, Color("163461") if active else UIThemeHelper.COLOR_NAVY_DEEP)

	_chronicle_pane.visible = (layer == "CHRONICLE")
	_knowledge_pane.visible = (layer == "KNOWLEDGE")
	_archive_pane.visible = (layer == "ARCHIVE")

	if layer == "CHRONICLE":
		_refresh_chronicle_layer()
	elif layer == "KNOWLEDGE":
		_refresh_knowledge_layer()
	else:
		_refresh_archive_layer()

func _refresh_chronicle_layer() -> void:
	for c in _ch_list_vbox.get_children():
		c.queue_free()

	for ch in BookManager.chapters:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 62)
		var status := "✓ Unlocked" if ch["unlocked"] else "🔒 Locked"
		b.text = "Ch. %d — %s\n[%s | Sync: %s]" % [ch["chapter_number"], ch["title"], status, ch["sync_code"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var cid: String = ch["id"]
		UIThemeHelper.style_button(b, UIThemeHelper.COLOR_GOLD_BRIGHT if cid == selected_chapter_id else UIThemeHelper.COLOR_GOLD_MUTED)
		b.pressed.connect(func():
			selected_chapter_id = cid
			AudioManager.play_ui_click()
			_refresh_chronicle_layer()
		)
		_ch_list_vbox.add_child(b)

	for ch in BookManager.chapters:
		if ch["id"] == selected_chapter_id:
			_ch_title_lbl.text = "Chapter %d: %s — %s" % [ch["chapter_number"], ch["title"], ch["subtitle"]]
			if ch["unlocked"]:
				_ch_body_lbl.text = "\n\n".join(ch["narrative_text"]) + "\n\n✦ Key Milestone: " + ch["key_event"]
				_ch_refl_samantha_lbl.text = "💭 Samantha's Meditative Lens (\"What does it mean?\"):\n" + ch["samantha_reflection"]
				_ch_refl_miguel_lbl.text = "📐 Miguel's Calculative Lens (\"How does it work?\"):\n" + ch["miguel_reflection"]
			else:
				_ch_body_lbl.text = "🔒 This Chronicle Chapter is currently unwritten in your playthrough. Progress further in the Academy Outpost (or enter Sync Code '%s' on the Title Screen) to unlock it!" % ch["sync_code"]
				_ch_refl_samantha_lbl.text = "Samantha's reflection unlocks with this chapter."
				_ch_refl_miguel_lbl.text = "Miguel's reflection unlocks with this chapter."

			for child in _ch_annot_hbox.get_children():
				child.queue_free()
			var annot_title := Label.new()
			annot_title.text = "Contextual Archive Annotations:"
			annot_title.add_theme_color_override("font_color", UIThemeHelper.COLOR_INK_DARK)
			_ch_annot_hbox.add_child(annot_title)
			for aid in ch.get("annotations", []):
				var abtn := Button.new()
				abtn.text = "🔗 " + str(aid)
				UIThemeHelper.style_button(abtn, UIThemeHelper.COLOR_CYAN_GLOW)
				var target_aid: String = aid
				abtn.pressed.connect(func():
					selected_archive_cat = "All"
					selected_archive_id = target_aid
					switch_layer("ARCHIVE")
				)
				_ch_annot_hbox.add_child(abtn)
			return

func _refresh_knowledge_layer() -> void:
	for c in _know_list_vbox.get_children():
		c.queue_free()

	var banner := Label.new()
	banner.text = "THE CANONICAL MATHEMATICAL DISCOVERY LOOP:\nObserve  →  Question  →  Measure  →  Represent  →  Understand  →  Apply  →  Discover  →  Question Again"
	banner.add_theme_font_size_override("font_size", 14)
	banner.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	_know_list_vbox.add_child(banner)

	for entry in BookManager.get_knowledge_entries():
		var mc: Dictionary = entry["math_concept"]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_NAVY_DEEP, UIThemeHelper.COLOR_CYAN_GLOW, 10, 2))
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "✦ %s\n• Governing Rule: %s\n• Mathematical Formula: %s\n• Explanation: %s\n• Concrete World Example: %s" % [
			mc["topic"],
			mc["rule"],
			mc["formula"],
			mc["explanation"],
			mc["example"]
		]
		lbl.add_theme_color_override("font_color", UIThemeHelper.COLOR_TEXT_LIGHT)
		card.add_child(lbl)
		_know_list_vbox.add_child(card)

func _refresh_archive_layer() -> void:
	for c in _arch_list_vbox.get_children():
		c.queue_free()

	if selected_archive_cat == "Volume Side Quests":
		_build_side_quests_view()
		return

	for entry in BookManager.archive_entries:
		if selected_archive_cat != "All" and entry["category"] != selected_archive_cat:
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46)
		var disc: bool = entry["discovered"]
		b.text = ("%s [%s]" % [entry["title"], entry["category"]]) if disc else ("🔒 Undiscovered (%s)" % entry["category"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var eid: String = entry["id"]
		UIThemeHelper.style_button(b, UIThemeHelper.COLOR_GOLD_BRIGHT if eid == selected_archive_id else UIThemeHelper.COLOR_GOLD_MUTED)
		b.pressed.connect(func():
			selected_archive_id = eid
			AudioManager.play_ui_click()
			_refresh_archive_layer()
		)
		_arch_list_vbox.add_child(b)

	for entry in BookManager.archive_entries:
		if entry["id"] == selected_archive_id:
			if entry["discovered"]:
				_arch_detail_lbl.text = "%s  (%s)\n\n%s\n\n%s" % [
					entry["title"],
					entry["category"],
					entry["summary"],
					entry["detailed_text"]
				]
				if entry.has("inquiry"):
					var inq: Dictionary = entry["inquiry"]
					_arch_inquiry_lbl.text = "📜 DOCUMENT THREE-QUESTION INQUIRY:\n\n1. Is it real?\n%s\n\n2. What does it mean?\n%s\n\n3. What can it tell us?\n%s" % [
						inq["is_it_real"],
						inq["what_does_it_mean"],
						inq["what_can_it_tell_us"]
					]
				else:
					_arch_inquiry_lbl.text = "🔗 Related Archive Records: " + ", ".join(entry.get("related_ids", []))
			else:
				_arch_detail_lbl.text = "🔒 Undiscovered Archive Record\n\nExplore the Academy Outpost, inspect inscriptions, and speak with inhabitants to record this entry."
				_arch_inquiry_lbl.text = "Undiscovered."
			return

func _build_side_quests_view() -> void:
	_arch_detail_lbl.text = "🏛 END-OF-VOLUME ARCHIVE SIDE QUESTS (Story Bible v0.09 Section 32)\n\nOptional historical context and advanced mathematical challenges that unlock Legendary Codex Spells without blocking the main story."
	var details_text := ""
	for sq in BookManager.archive_side_quests:
		var status := "✓ COMPLETED" if sq["solved"] else "OPEN CHALLENGE"
		details_text += "✦ %s [%s]\n%s\nPrompt: %s\n\n" % [sq["title"], status, sq["historical_note"], sq["prompt"]]

		for opt in sq["options"]:
			var btn := Button.new()
			btn.text = "%s  →  Answer: %s" % [sq["title"].split(":")[0], opt]
			var sq_ref: Dictionary = sq
			var chosen: String = opt
			UIThemeHelper.style_button(btn, UIThemeHelper.COLOR_CYAN_GLOW)
			btn.pressed.connect(func():
				if chosen == sq_ref["correct_option"]:
					sq_ref["solved"] = true
					CodexManager.unlock_spell(sq_ref["reward_spell_id"])
					AudioManager.play_puzzle_success()
					_arch_inquiry_lbl.text = "✓ Correct (%s)! %s" % [chosen, sq_ref["reward_text"]]
				else:
					AudioManager.play_error()
					_arch_inquiry_lbl.text = "✗ '%s' does not satisfy the historical balance. Try another expression!" % chosen
			)
			_arch_list_vbox.add_child(btn)
	_arch_inquiry_lbl.text = details_text
