class_name ChalkboardModal
extends Control
## Scholastic Discovery Slate & Companion Hypothesis Station:
## Lets Samantha Yu ("What does it mean?") and Miguel Perez ("How does it work?")
## compare Arithmetic (+4) vs. Geometric (×2) hypotheses and review the Progression Hierarchy.

signal closed()
signal open_proving_table_requested()
signal open_digital_book_requested()

var _content_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_show_tab("GEOMETRIC")

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.06, 0.12, 0.90)
	add_child(bg)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 48)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color("07261f"), UIThemeHelper.COLOR_GOLD_BORDER, 14, 3))
	add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var top_hbox := HBoxContainer.new()
	vbox.add_child(top_hbox)

	var title := Label.new()
	title.text = "📐 Courtyard Working Slate — Samantha & Miguel's Hypothesis Station"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UIThemeHelper.COLOR_GOLD_BRIGHT)
	top_hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕ Close [Esc]"
	UIThemeHelper.style_button(close_btn, UIThemeHelper.COLOR_DANGER)
	close_btn.pressed.connect(func():
		AudioManager.play_ui_click()
		closed.emit()
	)
	top_hbox.add_child(close_btn)

	# Tabs
	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(tab_hbox)

	for t in [
		{"id": "GEOMETRIC", "label": "1. Geometric Doubling (4, 8, 16, 32 → 64)"},
		{"id": "ARITHMETIC", "label": "2. Rule II Verification: Arithmetic (+4) vs. Geometric (×2)"},
		{"id": "HIERARCHY", "label": "3. Story Bible v0.09 Progression Hierarchy"}
	]:
		var b := Button.new()
		b.text = t["label"]
		var tid: String = t["id"]
		UIThemeHelper.style_button(b, UIThemeHelper.COLOR_CYAN_GLOW)
		b.pressed.connect(func():
			AudioManager.play_ui_click()
			_show_tab(tid)
		)
		tab_hbox.add_child(b)

	var slate_box := PanelContainer.new()
	slate_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slate_box.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(Color("041a15"), UIThemeHelper.COLOR_GOLD_MUTED, 10, 2))
	vbox.add_child(slate_box)

	_content_lbl = Label.new()
	_content_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_lbl.add_theme_font_size_override("font_size", 15)
	_content_lbl.add_theme_color_override("font_color", Color("d1fae5"))
	slate_box.add_child(_content_lbl)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	vbox.add_child(footer)

	var btn_prove := Button.new()
	btn_prove.text = "✒ Test at The Proving Table"
	UIThemeHelper.style_button(btn_prove, UIThemeHelper.COLOR_GOLD_BRIGHT, UIThemeHelper.COLOR_CYAN_DEEP)
	btn_prove.pressed.connect(func(): open_proving_table_requested.emit())
	footer.add_child(btn_prove)

	var btn_book := Button.new()
	btn_book.text = "📖 Open Digital Book Knowledge"
	UIThemeHelper.style_button(btn_book, UIThemeHelper.COLOR_GOLD_BORDER)
	btn_book.pressed.connect(func(): open_digital_book_requested.emit())
	footer.add_child(btn_book)

func _show_tab(tab_id: String) -> void:
	match tab_id:
		"GEOMETRIC":
			_content_lbl.text = "CHALK INSCRIPTION: THE SEQUENCE SOCKETS OF FOUNDATIONS\n\nSocket I = 4   |   Socket II = 8   |   Socket III = 16   |   Socket IV = 32   |   Socket V = [ 64 ]\n\n• Samantha Yu (Meditative — \"What does it mean?\"):\n  \"Every socket isn't just a random lock—it's a living rhythm growing by factors across space. Understanding the pattern shows us why the gate exists.\"\n\n• Miguel Perez (Calculative — \"How does it work?\"):\n  \"Look at the ratio between consecutive sockets: 8 ÷ 4 = 2, 16 ÷ 8 = 2, 32 ÷ 16 = 2. Because the constant multiplier is r = 2, Socket V must evaluate to Multiply(32, 2) = 64!\""
		"ARITHMETIC":
			_content_lbl.text = "RULE II VERIFICATION: \"What you believe may be true. It may also be wrong.\"\n\nWhy did the initial hypothesis of adding +4 fail?\n• Arithmetic Hypothesis (Addition d = +4):   4  →  8  →  12  →  16  →  20\n  (Contradicts reality! Socket III on the gate is 16, not 12.)\n\n• Geometric Hypothesis (Multiplication r = ×2):   4  →  8  →  16  →  32  →  64\n  (Matches every observed socket on the Requirement Gate!)"
		"HIERARCHY":
			_content_lbl.text = "CANONICAL NARRATIVE & ENCOUNTER HIERARCHY (Story Bible v0.09 Section 11):\n\n• BOOK  →  BOSS (Culmination of the entire Book's mathematical & narrative journey)\n• VOLUME  →  SUB-BOSS (Major intermediate culmination across a Volume)\n• CHAPTER  →  ELITE (Focused culmination of a Chapter's developing ideas — e.g., The Sequence Warden in the Northern Sanctum)"
