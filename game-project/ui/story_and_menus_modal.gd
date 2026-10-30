class_name StoryAndMenusModal
extends Control
## Implements the 5-Stage Startup-to-World Flow for the downloadable release:
## 1. BOOT_LOADING: Initial loading screen with Mystic Crystal M Emblem & progress bar
## 2. START_SCREEN: Key-Art Starting Screen (Start, Settings, Sync Code, Quit)
## 3. PROLOGUE_ANIM_LOADING -> PROLOGUE: Loading screen stating Prologue Animation is yet to be added, then Prologue story
## 4. CHARACTER_SELECT: Strictly Character Selection ONLY (Samantha / Miguel + Begin/Start + Continue Game [Saved Game])
## 5. WORLD_LOADING: Final loading screen before jumping into the playable Academy Outpost main world
## Plus in-game overlays: Caretaker Oron Dialogue, Pause/Inventory, Defeat Recovery, and Victory Summary.

signal enter_main_world_requested(protagonist_id: String, is_continued_game: bool)
signal open_proving_table_from_dialogue(encounter_id: String)
signal open_book_from_dialogue(layer_name: String)
signal resume_world_requested()

enum Mode {
	NONE,
	BOOT_LOADING,
	START_SCREEN,
	START_SETTINGS,
	START_SYNC_CODE,
	PROLOGUE_ANIM_LOADING,
	PROLOGUE,
	CHARACTER_SELECT,
	WORLD_LOADING,
	DIALOGUE,
	PAUSE_INVENTORY,
	DEFEAT,
	VICTORY
}

const CharacterCrestBannerScript = preload("res://ui/character_crest_banner.gd")

var current_mode: Mode = Mode.NONE
var selected_protagonist_start: String = "SAMANTHA"
var inspected_banner_id: String = ""
var is_continuing_saved_game: bool = false
var prologue_slide_idx: int = 0
var sync_feedback_message: String = ""
var sync_feedback_ok: bool = true

# Loading animation state
var _loading_progress: float = 0.0
var _loading_speed: float = 48.0
var _loading_bar: ProgressBar
var _loading_pct_lbl: Label
var _loading_status_lbl: Label
var _emblem_tex_rect: TextureRect
var _pulse_time: float = 0.0

var _tex_keyart: Texture2D
var _tex_emblem: Texture2D

var backdrop: ColorRect
var keyart_bg: TextureRect
var keyart_dimmer: ColorRect
var content_root: Control

const PROLOGUE_SLIDES: Array[Dictionary] = [
	{
		"header": "PROLOGUE // PART I — THE LIBRARY OF SHADOWS",
		"title": "An Ordinary Afternoon & The Ancient Engraving",
		"body": "In the quietest corridor of their school library, childhood friends Samantha Yu (10) and Miguel Perez (11) noticed anomalies that others overlooked—dust motes settling in geometric spirals and shelves aligned to exact ratios.\n\nTucked behind the stacks lay a heavy volume: Chronicles of the Infinite Knowledge. When they touched the crystalline engraving on Book I together, a surge of blue-gold light drew them across the threshold into MATHBOUND.",
		"quote": "\"It wasn't magic pulling us in—it felt like an invitation to understand what had always been right in front of us.\""
	},
	{
		"header": "PROLOGUE // PART II — THE FIVE RULES OF MATHBOUND",
		"title": "The Voice at the Academy Outpost",
		"body": "Awakening upon the floating flagstones of the Magical Academy, a resonant voice imparted the Five Rules:\n• Rule I (Perception): What you see, you can understand. What you cannot see, you must question.\n• Rule II (Doubt): What you believe may be true. It may also be wrong.\n• Rule III (Inquiry): Question what you know. Question what you don't know.\n• Rule IV (Discovery): The unknown is not something to fear. It is something to uncover.\n• Rule V (Invitation): Open your minds, have fun... and let's find out.",
		"quote": "\"To command a Magic Sprite is not to wish—it is to Envision the outcome and Command it through formal mathematical structure.\""
	},
	{
		"header": "PROLOGUE // PART III — THE TWO-TABLE TRIAL",
		"title": "Awakening in the Courtyard",
		"body": "Before them hovers Auri, a Courtyard Magic Sprite awaiting clear mathematical instructions.\n\nTo cross the fractured chasm and unseal the forbidden Patterned Gate, you must choose which young scholar will lead the expedition—knowing you can swap perspectives between Samantha's Meditative lens and Miguel's Calculative lens at any moment.",
		"quote": "Next: Select your character to begin the expedition into the Academy Outpost."
	}
]


func _load_texture_safe(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var tex := load(res_path) as Texture2D
		if tex != null:
			return tex
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_tex_keyart = _load_texture_safe("res://assets/ui/title_keyart.png")
	_tex_emblem = _load_texture_safe("res://assets/ui/m_emblem.png")

	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.10, 0.96)
	add_child(backdrop)

	keyart_bg = TextureRect.new()
	keyart_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	keyart_bg.texture = _tex_keyart
	keyart_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keyart_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	keyart_bg.visible = false
	add_child(keyart_bg)

	keyart_dimmer = ColorRect.new()
	keyart_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	keyart_dimmer.color = Color(0.02, 0.05, 0.12, 0.45)
	keyart_dimmer.visible = false
	add_child(keyart_dimmer)

	content_root = Control.new()
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content_root)


func _process(delta: float) -> void:
	if not visible:
		return

	_pulse_time += delta
	if is_instance_valid(_emblem_tex_rect):
		var s := 1.0 + 0.025 * sin(_pulse_time * 3.0)
		_emblem_tex_rect.scale = Vector2(s, s)
		_emblem_tex_rect.pivot_offset = _emblem_tex_rect.size * 0.5

	if current_mode in [Mode.BOOT_LOADING, Mode.PROLOGUE_ANIM_LOADING, Mode.WORLD_LOADING]:
		if _loading_progress < 100.0:
			_loading_progress = minf(100.0, _loading_progress + _loading_speed * delta)
			_update_loading_widgets()
			if _loading_progress >= 100.0:
				_on_loading_reached_100()


func _update_loading_widgets() -> void:
	if is_instance_valid(_loading_bar):
		_loading_bar.value = _loading_progress
	if is_instance_valid(_loading_pct_lbl):
		_loading_pct_lbl.text = "%d%%" % int(_loading_progress)
	if is_instance_valid(_loading_status_lbl):
		match current_mode:
			Mode.BOOT_LOADING:
				if _loading_progress < 35.0:
					_loading_status_lbl.text = "Initializing MATHBOUND Chronicle Engine..."
				elif _loading_progress < 70.0:
					_loading_status_lbl.text = "Loading Two-Table Sigil Registry & Magical Codex..."
				elif _loading_progress < 95.0:
					_loading_status_lbl.text = "Awakening Courtyard Magic Sprites..."
				else:
					_loading_status_lbl.text = "Ready! Opening Starting Screen..."
			Mode.PROLOGUE_ANIM_LOADING:
				if _loading_progress < 45.0:
					_loading_status_lbl.text = "Checking Prologue Cutscene Assets (Animation Yet To Be Added)..."
				elif _loading_progress < 85.0:
					_loading_status_lbl.text = "Loading Fallback Prologue Storyboard & The Five Rules..."
				else:
					_loading_status_lbl.text = "Prologue Storyboard Ready!"
			Mode.WORLD_LOADING:
				if _loading_progress < 35.0:
					_loading_status_lbl.text = "Loading Book I: The Magical Academy Outpost..."
				elif _loading_progress < 70.0:
					_loading_status_lbl.text = "Positioning Floating Stones & Requirement-Locked Patterned Gate..."
				elif _loading_progress < 95.0:
					_loading_status_lbl.text = "Synchronizing Companion & Magic Sprite Auri..."
				else:
					_loading_status_lbl.text = "Entering the Academy Courtyard..."


func _on_loading_reached_100() -> void:
	match current_mode:
		Mode.BOOT_LOADING:
			show_start_screen()
		Mode.PROLOGUE_ANIM_LOADING:
			# Keep notice visible briefly or let user click button; auto-advance after short delay
			get_tree().create_timer(0.65).timeout.connect(func() -> void:
				if current_mode == Mode.PROLOGUE_ANIM_LOADING:
					show_prologue()
			)
		Mode.WORLD_LOADING:
			var target_char := selected_protagonist_start
			var cont := is_continuing_saved_game
			current_mode = Mode.NONE
			visible = false
			enter_main_world_requested.emit(target_char, cont)


# ==============================================================================
# PUBLIC STAGE ENTRY POINTS
# ==============================================================================
func show_boot_loading_screen() -> void:
	current_mode = Mode.BOOT_LOADING
	_loading_progress = 0.0
	_loading_speed = 52.0
	visible = true
	_rebuild()


func show_start_screen() -> void:
	current_mode = Mode.START_SCREEN
	visible = true
	_rebuild()


func show_prologue_anim_loading() -> void:
	current_mode = Mode.PROLOGUE_ANIM_LOADING
	_loading_progress = 0.0
	_loading_speed = 42.0
	visible = true
	_rebuild()


func show_prologue() -> void:
	current_mode = Mode.PROLOGUE
	prologue_slide_idx = 0
	visible = true
	_rebuild()


func show_character_select() -> void:
	current_mode = Mode.CHARACTER_SELECT
	inspected_banner_id = ""
	visible = true
	_rebuild()


func show_world_loading(is_continue: bool) -> void:
	is_continuing_saved_game = is_continue
	current_mode = Mode.WORLD_LOADING
	_loading_progress = 0.0
	_loading_speed = 55.0
	visible = true
	_rebuild()


func show_oron_dialogue() -> void:
	current_mode = Mode.DIALOGUE
	visible = true
	AudioManager.play_dialogue_chirp()
	_rebuild()


func show_pause_inventory() -> void:
	current_mode = Mode.PAUSE_INVENTORY
	visible = true
	AudioManager.play_ui_click()
	_rebuild()


func show_defeat_modal() -> void:
	current_mode = Mode.DEFEAT
	visible = true
	_rebuild()


func show_victory_modal() -> void:
	current_mode = Mode.VICTORY
	visible = true
	_rebuild()


func is_startup_flow_active() -> bool:
	return current_mode in [
		Mode.BOOT_LOADING,
		Mode.START_SCREEN,
		Mode.START_SETTINGS,
		Mode.START_SYNC_CODE,
		Mode.PROLOGUE_ANIM_LOADING,
		Mode.PROLOGUE,
		Mode.CHARACTER_SELECT,
		Mode.WORLD_LOADING
	]


func close_modal() -> void:
	if is_startup_flow_active():
		return
	current_mode = Mode.NONE
	visible = false
	resume_world_requested.emit()


func _rebuild() -> void:
	_loading_bar = null
	_loading_pct_lbl = null
	_loading_status_lbl = null
	_emblem_tex_rect = null

	for child in content_root.get_children():
		child.queue_free()

	# Configure background visibility per stage
	var use_keyart := current_mode in [
		Mode.START_SCREEN,
		Mode.START_SETTINGS,
		Mode.START_SYNC_CODE,
		Mode.WORLD_LOADING
	]
	keyart_bg.visible = use_keyart and (_tex_keyart != null)
	keyart_dimmer.visible = use_keyart
	if current_mode == Mode.START_SCREEN:
		keyart_dimmer.color = Color(0.01, 0.03, 0.08, 0.22)
	elif current_mode in [Mode.START_SETTINGS, Mode.START_SYNC_CODE, Mode.WORLD_LOADING]:
		keyart_dimmer.color = Color(0.02, 0.05, 0.12, 0.72)

	backdrop.color = Color(0.02, 0.04, 0.10, 0.98) if is_startup_flow_active() else Color(0.02, 0.04, 0.09, 0.88)

	match current_mode:
		Mode.BOOT_LOADING:
			_build_boot_loading_screen()
		Mode.START_SCREEN:
			_build_start_screen()
		Mode.START_SETTINGS:
			_build_start_settings_popup()
		Mode.START_SYNC_CODE:
			_build_start_sync_popup()
		Mode.PROLOGUE_ANIM_LOADING:
			_build_prologue_anim_loading_screen()
		Mode.PROLOGUE:
			_build_prologue_screen()
		Mode.CHARACTER_SELECT:
			_build_character_select_screen()
		Mode.WORLD_LOADING:
			_build_world_loading_screen()
		Mode.DIALOGUE:
			_build_dialogue_screen()
		Mode.PAUSE_INVENTORY:
			_build_pause_inventory_screen()
		Mode.DEFEAT:
			_build_defeat_screen()
		Mode.VICTORY:
			_build_victory_screen()


# ==============================================================================
# STAGE 1: INITIAL BOOT LOADING SCREEN (Mystic Crystal M Emblem)
# ==============================================================================
func _build_boot_loading_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(680, 540)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)

	# Emblem Container
	var emblem_center := CenterContainer.new()
	v.add_child(emblem_center)

	if _tex_emblem != null:
		_emblem_tex_rect = TextureRect.new()
		_emblem_tex_rect.texture = _tex_emblem
		_emblem_tex_rect.custom_minimum_size = Vector2(270, 270)
		_emblem_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_emblem_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem_center.add_child(_emblem_tex_rect)

	var title_lbl := UIThemeHelper.make_label("M A T H B O U N D", 34, UIThemeHelper.COLOR_GOLD_BRIGHT)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_lbl)

	var sub_lbl := UIThemeHelper.make_label("CHRONICLES OF THE INFINITE KNOWLEDGE", 14, UIThemeHelper.COLOR_CYAN_GLOW)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub_lbl)

	# Loading Bar Card
	var bar_card := PanelContainer.new()
	bar_card.custom_minimum_size = Vector2(560, 90)
	bar_card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.05, 0.10, 0.20, 0.95), UIThemeHelper.COLOR_GOLD_BORDER, 2, 10))
	v.add_child(bar_card)

	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 20)
	bm.add_theme_constant_override("margin_right", 20)
	bm.add_theme_constant_override("margin_top", 14)
	bm.add_theme_constant_override("margin_bottom", 14)
	bar_card.add_child(bm)

	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 8)
	bm.add_child(bv)

	var status_row := HBoxContainer.new()
	bv.add_child(status_row)

	_loading_status_lbl = UIThemeHelper.make_label("Initializing MATHBOUND Chronicle Engine...", 13, UIThemeHelper.COLOR_TEXT_CREAM)
	_loading_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(_loading_status_lbl)

	_loading_pct_lbl = UIThemeHelper.make_label("0%", 13, UIThemeHelper.COLOR_GOLD_BRIGHT)
	status_row.add_child(_loading_pct_lbl)

	_loading_bar = ProgressBar.new()
	_loading_bar.custom_minimum_size = Vector2(0, 20)
	_loading_bar.max_value = 100.0
	_loading_bar.value = _loading_progress
	_loading_bar.show_percentage = false
	_loading_bar.add_theme_stylebox_override("background", UIThemeHelper.make_panel_style(Color(0.03, 0.06, 0.12), UIThemeHelper.COLOR_GOLD_MUTED, 6, 1, 0))
	_loading_bar.add_theme_stylebox_override("fill", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_CYAN_GLOW, UIThemeHelper.COLOR_GOLD_BRIGHT, 6, 1, 0))
	bv.add_child(_loading_bar)


# ==============================================================================
# STAGE 2: STARTING SCREEN (Key Art + Start, Settings, Sync Code, Quit)
# ==============================================================================
func _build_start_screen() -> void:
	# Position the menu dock cleanly in the lower center so the key-art logo & book shine
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_bottom", 28)
	root_margin.add_theme_constant_override("margin_top", 20)
	root_margin.add_theme_constant_override("margin_left", 32)
	root_margin.add_theme_constant_override("margin_right", 32)
	content_root.add_child(root_margin)

	var outer_v := VBoxContainer.new()
	outer_v.alignment = BoxContainer.ALIGNMENT_END
	root_margin.add_child(outer_v)

	# Fallback title banner only if keyart texture wasn't found
	if _tex_keyart == null:
		var fallback_title := UIThemeHelper.make_label("MATHBOUND: CHRONICLES OF THE INFINITE KNOWLEDGE", 36, UIThemeHelper.COLOR_GOLD_BRIGHT)
		fallback_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer_v.add_child(fallback_title)

	var dock_center := CenterContainer.new()
	outer_v.add_child(dock_center)

	var dock_card := PanelContainer.new()
	dock_card.custom_minimum_size = Vector2(460, 230)
	dock_card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.04, 0.08, 0.18, 0.92), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 14))
	dock_center.add_child(dock_card)

	var dm := MarginContainer.new()
	dm.add_theme_constant_override("margin_left", 28)
	dm.add_theme_constant_override("margin_right", 28)
	dm.add_theme_constant_override("margin_top", 20)
	dm.add_theme_constant_override("margin_bottom", 20)
	dock_card.add_child(dm)

	var dv := VBoxContainer.new()
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	dv.add_theme_constant_override("separation", 10)
	dm.add_child(dv)

	var start_btn := UIThemeHelper.make_gold_button("▶   START GAME", 18)
	start_btn.custom_minimum_size = Vector2(0, 48)
	start_btn.pressed.connect(func() -> void:
		AudioManager.play_puzzle_success()
		show_prologue_anim_loading()
	)
	dv.add_child(start_btn)

	var row_mid := HBoxContainer.new()
	row_mid.add_theme_constant_override("separation", 10)
	dv.add_child(row_mid)

	var settings_btn := UIThemeHelper.make_stylized_button("⚙  Settings", 14, true)
	settings_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_btn.custom_minimum_size = Vector2(0, 40)
	settings_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		current_mode = Mode.START_SETTINGS
		_rebuild()
	)
	row_mid.add_child(settings_btn)

	var sync_btn := UIThemeHelper.make_stylized_button("🔗  Book Sync Code", 14)
	sync_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sync_btn.custom_minimum_size = Vector2(0, 40)
	sync_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		current_mode = Mode.START_SYNC_CODE
		_rebuild()
	)
	row_mid.add_child(sync_btn)

	var quit_btn := UIThemeHelper.make_stylized_button("✕   Quit to Desktop", 13)
	quit_btn.custom_minimum_size = Vector2(0, 36)
	quit_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		get_tree().quit()
	)
	dv.add_child(quit_btn)


func _build_start_settings_popup() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 380)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.05, 0.10, 0.20, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	v.add_child(UIThemeHelper.make_label("⚙  GAME SETTINGS & ACCESSIBILITY", 20, UIThemeHelper.COLOR_GOLD_BRIGHT))

	var fs_chk := CheckButton.new()
	fs_chk.text = "Full Screen Mode (Uncheck for Resizable Window) [F11]"
	fs_chk.button_pressed = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	fs_chk.toggled.connect(func(on: bool) -> void:
		if on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		AudioManager.play_ui_click()
	)
	v.add_child(fs_chk)

	var relax_chk := CheckButton.new()
	relax_chk.text = "Relaxed Story Mode (50% Reduced Incoming Damage)"
	relax_chk.button_pressed = bool(GameManager.settings.get("relaxed_mode", false))
	relax_chk.toggled.connect(func(on: bool) -> void:
		GameManager.settings["relaxed_mode"] = on
		AudioManager.play_ui_click()
	)
	v.add_child(relax_chk)

	var shake_chk := CheckButton.new()
	shake_chk.text = "Screen Shake Effects Enabled"
	shake_chk.button_pressed = bool(GameManager.settings.get("screen_shake", true))
	shake_chk.toggled.connect(func(on: bool) -> void:
		GameManager.settings["screen_shake"] = on
		AudioManager.play_ui_click()
	)
	v.add_child(shake_chk)

	var mute_chk := CheckButton.new()
	mute_chk.text = "Placeholder Audio Synthesizer Enabled"
	mute_chk.button_pressed = AudioManager.audio_enabled
	mute_chk.toggled.connect(func(on: bool) -> void:
		AudioManager.audio_enabled = on
		if on:
			AudioManager.play_ui_click()
	)
	v.add_child(mute_chk)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	var back_btn := UIThemeHelper.make_gold_button("←  Back to Starting Screen", 14)
	back_btn.custom_minimum_size = Vector2(0, 42)
	back_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		show_start_screen()
	)
	v.add_child(back_btn)


func _build_start_sync_popup() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 380)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.05, 0.10, 0.20, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	v.add_child(UIThemeHelper.make_label("🔗  DIGITAL BOOK ↔ GAME SYNC CODES", 20, UIThemeHelper.COLOR_GOLD_BRIGHT))
	v.add_child(UIThemeHelper.make_label(
		"Reading the standalone Digital Book? Enter a chapter milestone code to synchronize your discoveries and unlock spells:",
		13,
		UIThemeHelper.COLOR_TEXT_DIM,
		true
	))

	var sync_row := HBoxContainer.new()
	sync_row.add_theme_constant_override("separation", 8)
	v.add_child(sync_row)

	var sync_input := LineEdit.new()
	sync_input.placeholder_text = "e.g., BOOK1-CH2, GATE-64, CODEX-ALL"
	sync_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sync_row.add_child(sync_input)

	var apply_btn := UIThemeHelper.make_stylized_button("Apply Code", 13, true)
	apply_btn.pressed.connect(func() -> void:
		var res: Dictionary = BookManager.apply_sync_code(sync_input.text)
		sync_feedback_ok = bool(res.get("success", false))
		sync_feedback_message = String(res.get("message", ""))
		_rebuild()
	)
	sync_row.add_child(apply_btn)

	var preset_row := HFlowContainer.new()
	preset_row.add_theme_constant_override("h_separation", 8)
	preset_row.add_theme_constant_override("v_separation", 8)
	v.add_child(preset_row)
	for sample_code in ["BOOK1-CH2", "GATE-64", "CODEX-ALL"]:
		var p_btn := UIThemeHelper.make_stylized_button("Quick Fill: " + sample_code, 12)
		p_btn.pressed.connect(func() -> void:
			var res: Dictionary = BookManager.apply_sync_code(sample_code)
			sync_feedback_ok = bool(res.get("success", false))
			sync_feedback_message = String(res.get("message", ""))
			_rebuild()
		)
		preset_row.add_child(p_btn)

	if not sync_feedback_message.is_empty():
		v.add_child(UIThemeHelper.make_label(
			sync_feedback_message,
			13,
			UIThemeHelper.COLOR_EMERALD if sync_feedback_ok else UIThemeHelper.COLOR_CRIMSON,
			true
		))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	var back_btn := UIThemeHelper.make_gold_button("←  Back to Starting Screen", 14)
	back_btn.custom_minimum_size = Vector2(0, 42)
	back_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		show_start_screen()
	)
	v.add_child(back_btn)


# ==============================================================================
# STAGE 3A: PROLOGUE ANIMATION PLACEHOLDER LOADING SCREEN
# ==============================================================================
func _build_prologue_anim_loading_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 490)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.05, 0.10, 0.20, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 14))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 26)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var emblem_center := CenterContainer.new()
	v.add_child(emblem_center)

	if _tex_emblem != null:
		_emblem_tex_rect = TextureRect.new()
		_emblem_tex_rect.texture = _tex_emblem
		_emblem_tex_rect.custom_minimum_size = Vector2(150, 150)
		_emblem_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_emblem_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem_center.add_child(_emblem_tex_rect)

	var badge := UIThemeHelper.make_label("PROLOGUE CINEMATIC // LOADING SEQUENCE", 13, UIThemeHelper.COLOR_CYAN_GLOW)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(badge)

	# Explicit Notice Box that the Animation is Yet to be Added
	var notice_box := PanelContainer.new()
	notice_box.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_panel(UIThemeHelper.COLOR_PARCHMENT, UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 10))
	v.add_child(notice_box)

	var nm := MarginContainer.new()
	nm.add_theme_constant_override("margin_left", 18)
	nm.add_theme_constant_override("margin_right", 18)
	nm.add_theme_constant_override("margin_top", 12)
	nm.add_theme_constant_override("margin_bottom", 12)
	notice_box.add_child(nm)

	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 6)
	nm.add_child(nv)

	var notice_title := UIThemeHelper.make_label("🎬  PROLOGUE ANIMATION YET TO BE ADDED", 16, UIThemeHelper.COLOR_INK_DARK)
	notice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nv.add_child(notice_title)

	var notice_desc := UIThemeHelper.make_label(
		"In the full release, an animated prologue cutscene will play here.\nSince animations are yet to be added, loading the interactive Prologue Storyboard below...",
		13,
		Color(0.20, 0.28, 0.40),
		true
	)
	notice_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nv.add_child(notice_desc)

	# Progress Bar
	var status_row := HBoxContainer.new()
	v.add_child(status_row)

	_loading_status_lbl = UIThemeHelper.make_label("Checking Prologue Cutscene Assets...", 13, UIThemeHelper.COLOR_TEXT_CREAM)
	_loading_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(_loading_status_lbl)

	_loading_pct_lbl = UIThemeHelper.make_label("0%", 13, UIThemeHelper.COLOR_GOLD_BRIGHT)
	status_row.add_child(_loading_pct_lbl)

	_loading_bar = ProgressBar.new()
	_loading_bar.custom_minimum_size = Vector2(0, 20)
	_loading_bar.max_value = 100.0
	_loading_bar.value = _loading_progress
	_loading_bar.show_percentage = false
	_loading_bar.add_theme_stylebox_override("background", UIThemeHelper.make_panel_style(Color(0.03, 0.06, 0.12), UIThemeHelper.COLOR_GOLD_MUTED, 6, 1, 0))
	_loading_bar.add_theme_stylebox_override("fill", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_GOLD_BRIGHT, UIThemeHelper.COLOR_CYAN_GLOW, 6, 1, 0))
	v.add_child(_loading_bar)

	var skip_btn := UIThemeHelper.make_stylized_button("Continue to Prologue Story ▶", 13, true)
	skip_btn.custom_minimum_size = Vector2(240, 36)
	skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		show_prologue()
	)
	v.add_child(skip_btn)


# ==============================================================================
# STAGE 3B: PROLOGUE STORY SCENE (Advances to Character Selection!)
# ==============================================================================
func _build_prologue_screen() -> void:
	var slide: Dictionary = PROLOGUE_SLIDES[clampi(prologue_slide_idx, 0, PROLOGUE_SLIDES.size() - 1)]

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(780, 460)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.06, 0.11, 0.22, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 28)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)

	v.add_child(UIThemeHelper.make_label(String(slide.get("header", "")), 12, UIThemeHelper.COLOR_CYAN_GLOW))
	v.add_child(UIThemeHelper.make_label(String(slide.get("title", "")), 26, UIThemeHelper.COLOR_GOLD_BRIGHT, true))

	var body_lbl := UIThemeHelper.make_label(String(slide.get("body", "")), 15, UIThemeHelper.COLOR_TEXT_CREAM, true)
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body_lbl)

	var quote_box := PanelContainer.new()
	quote_box.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_panel(UIThemeHelper.COLOR_PARCHMENT_DARK, UIThemeHelper.COLOR_GOLD_TRIM, 1, 8))
	v.add_child(quote_box)

	var qm := MarginContainer.new()
	qm.add_theme_constant_override("margin_left", 14)
	qm.add_theme_constant_override("margin_right", 14)
	qm.add_theme_constant_override("margin_top", 10)
	qm.add_theme_constant_override("margin_bottom", 10)
	quote_box.add_child(qm)
	qm.add_child(UIThemeHelper.make_label(String(slide.get("quote", "")), 13, UIThemeHelper.COLOR_INK_DARK, true))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	v.add_child(footer)

	var skip_btn := UIThemeHelper.make_stylized_button("Skip Prologue ▶", 13)
	skip_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		show_character_select()
	)
	footer.add_child(skip_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var step_lbl := UIThemeHelper.make_label("Prologue %d / %d" % [prologue_slide_idx + 1, PROLOGUE_SLIDES.size()], 13, UIThemeHelper.COLOR_TEXT_DIM)
	footer.add_child(step_lbl)

	var is_last := prologue_slide_idx >= PROLOGUE_SLIDES.size() - 1
	var next_btn := UIThemeHelper.make_gold_button(
		"Proceed to Character Selection ▶" if is_last else "Next Slide ▶",
		14
	)
	next_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		if not is_last:
			prologue_slide_idx += 1
			_rebuild()
		else:
			show_character_select()
	)
	footer.add_child(next_btn)


# ==============================================================================
# STAGE 4: DEDICATED CHARACTER SELECTION SCREEN (Crest Banners + Click-to-Reveal Details)
# ==============================================================================
func _build_character_select_screen() -> void:
	# 1. Festive Starry Night, Firework Blooms & Floating Lanterns Backdrop (Matches 2nd Reference Image!)
	var festive_bg := Control.new()
	festive_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	festive_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	festive_bg.draw.connect(func() -> void:
		var sz := festive_bg.size
		festive_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color("16132b"))
		# Sweeping celestial arcs across the top sky
		festive_bg.draw_arc(Vector2(sz.x * 0.5, sz.y * 1.15), sz.y * 0.95, PI * 1.15, PI * 1.85, 64, Color(0.55, 0.45, 0.85, 0.16), 2.5)
		festive_bg.draw_arc(Vector2(sz.x * 0.5, sz.y * 1.25), sz.y * 0.98, PI * 1.18, PI * 1.82, 64, Color(0.95, 0.78, 0.35, 0.14), 1.8)
		# Radial firework / dandelion constellation blooms (like the 2nd image backdrop!)
		var blooms: Array[Vector2] = [
			Vector2(sz.x * 0.14, sz.y * 0.16),
			Vector2(sz.x * 0.32, sz.y * 0.11),
			Vector2(sz.x * 0.68, sz.y * 0.12),
			Vector2(sz.x * 0.86, sz.y * 0.18),
			Vector2(sz.x * 0.08, sz.y * 0.42),
			Vector2(sz.x * 0.92, sz.y * 0.40)
		]
		for b_pos: Vector2 in blooms:
			for ray in range(16):
				var ang: float = float(ray) * (TAU / 16.0)
				var inner_p: Vector2 = b_pos + Vector2(cos(ang) * 8.0, sin(ang) * 8.0)
				var outer_p: Vector2 = b_pos + Vector2(cos(ang) * 34.0, sin(ang) * 34.0)
				festive_bg.draw_line(inner_p, outer_p, Color(0.68, 0.62, 0.92, 0.22), 1.5)
				festive_bg.draw_circle(outer_p, 2.0, Color(0.98, 0.88, 0.55, 0.30))
		# Warm floating golden sky lanterns
		var lanterns: Array[Vector2] = [
			Vector2(sz.x * 0.22, sz.y * 0.24),
			Vector2(sz.x * 0.41, sz.y * 0.18),
			Vector2(sz.x * 0.61, sz.y * 0.20),
			Vector2(sz.x * 0.79, sz.y * 0.26),
			Vector2(sz.x * 0.12, sz.y * 0.30),
			Vector2(sz.x * 0.89, sz.y * 0.29)
		]
		for lp: Vector2 in lanterns:
			festive_bg.draw_circle(lp, 9.0, Color(1.0, 0.75, 0.2, 0.25))
			festive_bg.draw_circle(lp, 4.5, Color(1.0, 0.92, 0.55, 0.85))
	)
	content_root.add_child(festive_bg)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_top", 18)
	root_margin.add_theme_constant_override("margin_bottom", 20)
	content_root.add_child(root_margin)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	root_margin.add_child(v)

	# Top Title Header ("Event Wish Preview" style from 2nd reference image)
	var header_v := VBoxContainer.new()
	header_v.add_theme_constant_override("separation", 2)
	v.add_child(header_v)

	var header_lbl := UIThemeHelper.make_label("Chronicle Wish Preview  —  Select Your Scholar", 26, Color.WHITE)
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_v.add_child(header_lbl)

	var sub_lbl := UIThemeHelper.make_label(
		"Press any Character Crest Banner below to reveal their full details and select your Lead Protagonist",
		13,
		UIThemeHelper.COLOR_GOLD_BRIGHT
	)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_v.add_child(sub_lbl)

	# 2. 5-Banner Stepped Crest Showcase (Exact V-Height Stepped Formation from 2nd Reference Image!)
	var center_holder := CenterContainer.new()
	center_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(center_holder)

	var banners_hbox := HBoxContainer.new()
	banners_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banners_hbox.add_theme_constant_override("separation", 16)
	center_holder.add_child(banners_hbox)

	var banner_configs: Array[Dictionary] = [
		{
			"id": "AURI",
			"name": "Auri",
			"role": "Courtyard Sprite",
			"sigil": "◈",
			"primary": Color("38bdf8"),
			"secondary": Color("155e75"),
			"playable": true,
			"size": Vector2(182, 400)
		},
		{
			"id": "ORON",
			"name": "Caretaker Oron",
			"role": "Keeper of Proofs",
			"sigil": "☥",
			"primary": Color("a855f7"),
			"secondary": Color("3b0764"),
			"playable": true,
			"size": Vector2(194, 434)
		},
		{
			"id": "SAMANTHA",
			"name": "Samantha Yu",
			"role": "Meditative Scholar",
			"sigil": "✦",
			"primary": Color("38bdf8"),
			"secondary": Color("1e3a8a"),
			"playable": true,
			"size": Vector2(216, 468)
		},
		{
			"id": "MIGUEL",
			"name": "Miguel Perez",
			"role": "Calculative Scholar",
			"sigil": "×",
			"primary": Color("10b981"),
			"secondary": Color("134e4a"),
			"playable": true,
			"size": Vector2(204, 446)
		},
		{
			"id": "LYRA",
			"name": "Arch-Scholar Lyra",
			"role": "Harmonic Weaver",
			"sigil": "❖",
			"primary": Color("f43f5e"),
			"secondary": Color("4c0519"),
			"playable": true,
			"size": Vector2(182, 400)
		}
	]

	for bcfg in banner_configs:
		var bid: String = String(bcfg["id"])
		var banner := CharacterCrestBannerScript.new()
		banner.custom_minimum_size = bcfg["size"]
		banner.size_flags_vertical = Control.SIZE_SHRINK_END
		banner.setup(
			bid,
			String(bcfg["name"]),
			String(bcfg["role"]),
			String(bcfg["sigil"]),
			bcfg["primary"],
			bcfg["secondary"],
			bool(bcfg["playable"])
		)
		banner.is_selected = (bid == selected_protagonist_start)
		banner.is_inspected = (bid == inspected_banner_id)
		banner.banner_pressed.connect(func(clicked_id: String) -> void:
			AudioManager.play_sigil_place()
			inspected_banner_id = clicked_id
			if clicked_id in ["SAMANTHA", "MIGUEL"]:
				selected_protagonist_start = clicked_id
			_rebuild()
		)
		banners_hbox.add_child(banner)

	# 3. Bottom Action Row: Strictly ONLY Begin / Start and Continue Game (Saved Game)
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 22)
	v.add_child(action_row)

	var chosen_name: String = String(GameManager.protagonist_profiles[selected_protagonist_start].get("name", "Samantha Yu"))
	var begin_btn := UIThemeHelper.make_gold_button("▶   Begin / Start  (%s)" % chosen_name, 16)
	begin_btn.custom_minimum_size = Vector2(350, 48)
	begin_btn.pressed.connect(func() -> void:
		AudioManager.play_puzzle_success()
		GameManager.reset_for_new_game(selected_protagonist_start)
		show_world_loading(false)
	)
	action_row.add_child(begin_btn)

	var has_save := GameManager.has_save_file()
	var cont_btn := UIThemeHelper.make_stylized_button(
		"💾   Continue Game (Saved Game)" if has_save else "💾   Continue Game (No Saved Game)",
		15,
		has_save
	)
	cont_btn.custom_minimum_size = Vector2(350, 48)
	cont_btn.disabled = not has_save
	cont_btn.pressed.connect(func() -> void:
		AudioManager.play_puzzle_success()
		GameManager.load_game()
		selected_protagonist_start = GameManager.protagonist_id
		show_world_loading(true)
	)
	action_row.add_child(cont_btn)

	# 4. Click-to-Reveal Character Details Modal Overlay (ONLY appears when a character banner is pressed!)
	if not inspected_banner_id.is_empty():
		var overlay := _build_inspected_character_details_card(inspected_banner_id)
		content_root.add_child(overlay)


func _build_inspected_character_details_card(banner_id: String) -> Control:
	var details_data: Dictionary = {}
	if GameManager.protagonist_profiles.has(banner_id):
		var p: Dictionary = GameManager.protagonist_profiles[banner_id]
		var is_sam := (banner_id == "SAMANTHA")
		details_data = {
			"id": banner_id,
			"short_name": String(p["name"]),
			"role": "Meditative Scholar" if is_sam else "Calculative Scholar",
			"sigil": "✦" if is_sam else "×",
			"primary": Color("38bdf8") if is_sam else Color("10b981"),
			"secondary": Color("1e3a8a") if is_sam else Color("134e4a"),
			"name": "%s  •  Age %d  •  Height %s" % [String(p["name"]), int(p["age"]), String(p["height"])],
			"badge": "★ ★ ★ ★ ★   PLAYABLE LEAD PROTAGONIST",
			"style": "%s — \"%s\"" % [String(p["thinking_style"]), String(p["guiding_question"])],
			"summary": String(p["summary"]),
			"specialty": String(p["specialty"]),
			"affinity": "Counting Sigil (✦) & Meaning Reflection" if is_sam else "Multiplication Sigil (×) & Structural Ratios",
			"stat_insight": 96 if is_sam else 84,
			"stat_logic": 85 if is_sam else 98,
			"stat_resonance": 94 if is_sam else 92,
			"is_lead_option": true,
			"status": "✓ Active Lead Protagonist! Press 'Begin / Start' to enter the Magical Academy as %s." % String(p["name"])
		}
	elif banner_id == "AURI":
		details_data = {
			"id": "AURI",
			"short_name": "Auri",
			"role": "Courtyard Sprite",
			"sigil": "◈",
			"primary": Color("38bdf8"),
			"secondary": Color("155e75"),
			"name": "Auri  •  Courtyard Magic Sprite",
			"badge": "★ ★ ★ ★ ★   COMPANION MAGIC SPRITE (AUTOMATICALLY JOINS)",
			"style": "Domain: Stone & Spatial Order  •  Max Magnitude: 100",
			"summary": "A living, personality-bearing manifestation of courtyard magic. Under the First Rule of Magic, humans cannot cast spells alone—Auri interprets your mathematical Commands and enacts them upon reality.",
			"specialty": "Counting Sigil (✦) & Geometric Bridge Alignment",
			"affinity": "Resonance Channeling & Real-Time Spell Execution",
			"stat_insight": 90,
			"stat_logic": 88,
			"stat_resonance": 100,
			"is_lead_option": false,
			"status": "✦ Auri automatically bonds with your chosen Lead Protagonist (Samantha or Miguel) in Chapter 1!"
		}
	elif banner_id == "ORON":
		details_data = {
			"id": "ORON",
			"short_name": "Caretaker Oron",
			"role": "Keeper of Proofs",
			"sigil": "☥",
			"primary": Color("a855f7"),
			"secondary": Color("3b0764"),
			"name": "Caretaker Oron  •  Keeper of the Academy",
			"badge": "★ ★ ★ ★ ★   ACADEMY MENTOR & ARCHIVIST",
			"style": "Master of the Two-Table Spellcraft System (Envision + Command)",
			"summary": "An elder scholar who tends the fractured Academy Study Hall and Foyer. He guides new arrivals in translating mathematical intuition into rigorous Sigil Commands at the Proving Table.",
			"specialty": "Diagnostic Feedback, Requirement Gates & Chronicle History",
			"affinity": "Ancient Inscriptions & Geometric Progression",
			"stat_insight": 98,
			"stat_logic": 95,
			"stat_resonance": 88,
			"is_lead_option": false,
			"status": "✦ Speak with Caretaker Oron on the Checkered Foyer carpet as soon as you enter the Academy!"
		}
	else:
		details_data = {
			"id": "LYRA",
			"short_name": "Arch-Scholar Lyra",
			"role": "Harmonic Weaver",
			"sigil": "❖",
			"primary": Color("f43f5e"),
			"secondary": Color("4c0519"),
			"name": "Arch-Scholar Lyra  •  Curator of the Infinite Library",
			"badge": "★ ★ ★ ★ ★   CHRONICLE LORE FIGURE (FUTURE CHAPTERS)",
			"style": "Harmonic Synthesis — \"How do all patterns converge?\"",
			"summary": "The legendary curator who authored the foundational treatises in the Grand Infinite Archive before the Great Fracture sealed the upper wings behind Requirement Gates.",
			"specialty": "Higher-Order Sequences & Codex Spell Synthesis",
			"affinity": "Harmonic Bridge & Celestial Mapping",
			"stat_insight": 99,
			"stat_logic": 97,
			"stat_resonance": 96,
			"is_lead_option": false,
			"status": "✦ Discover Arch-Scholar Lyra's records inside the Digital Book & Magical Codex!"
		}

	# Fullscreen dimmed click-to-dismiss overlay so the 5 crest banners behind stay perfectly centered
	var overlay_root := Control.new()
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.04, 0.10, 0.76)
	dimmer.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play_ui_click()
			inspected_banner_id = ""
			_rebuild()
	)
	overlay_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(820, 470)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.05, 0.09, 0.20, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 3, 16))
	center.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 26)
	cm.add_theme_constant_override("margin_right", 26)
	cm.add_theme_constant_override("margin_top", 22)
	cm.add_theme_constant_override("margin_bottom", 22)
	card.add_child(cm)

	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 26)
	cm.add_child(main_hbox)

	# Left Column: Large Featured Crest Banner Preview
	var preview_banner := CharacterCrestBannerScript.new()
	preview_banner.custom_minimum_size = Vector2(210, 420)
	preview_banner.setup(
		String(details_data["id"]),
		String(details_data["short_name"]),
		String(details_data["role"]),
		String(details_data["sigil"]),
		details_data["primary"],
		details_data["secondary"],
		true
	)
	preview_banner.is_selected = true
	main_hbox.add_child(preview_banner)

	# Right Column: Rich Character Details, Attributes, Lore & Selection Controls
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 10)
	main_hbox.add_child(cv)

	var top_r := HBoxContainer.new()
	cv.add_child(top_r)

	var badge_lbl := UIThemeHelper.make_label(String(details_data["badge"]), 12, UIThemeHelper.COLOR_GOLD_BRIGHT)
	badge_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_r.add_child(badge_lbl)

	var close_det_btn := UIThemeHelper.make_stylized_button("✕  Close Details", 12)
	close_det_btn.pressed.connect(func() -> void:
		AudioManager.play_ui_click()
		inspected_banner_id = ""
		_rebuild()
	)
	top_r.add_child(close_det_btn)

	cv.add_child(UIThemeHelper.make_label(String(details_data["name"]), 24, Color.WHITE, true))
	cv.add_child(UIThemeHelper.make_label(String(details_data["style"]), 14, UIThemeHelper.COLOR_CYAN_GLOW, true))

	var sep := HSeparator.new()
	cv.add_child(sep)

	var sum_lbl := UIThemeHelper.make_label(String(details_data["summary"]), 14, UIThemeHelper.COLOR_TEXT_CREAM, true)
	sum_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(sum_lbl)

	# Attribute Bars (Pattern Insight, Structural Logic, Sprite Resonance)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 6)
	cv.add_child(stats_grid)

	var stat_rows: Array = [
		["Pattern Insight", int(details_data["stat_insight"]), Color("38bdf8")],
		["Structural Logic", int(details_data["stat_logic"]), Color("f59e0b")],
		["Sprite Resonance", int(details_data["stat_resonance"]), Color("a855f7")]
	]
	for sr: Array in stat_rows:
		stats_grid.add_child(UIThemeHelper.make_label(String(sr[0]), 12, UIThemeHelper.COLOR_TEXT_DIM))
		var pbar := ProgressBar.new()
		pbar.custom_minimum_size = Vector2(240, 14)
		pbar.max_value = 100
		pbar.value = int(sr[1])
		pbar.show_percentage = true
		pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fill_s := StyleBoxFlat.new()
		fill_s.bg_color = sr[2] as Color
		fill_s.set_corner_radius_all(4)
		pbar.add_theme_stylebox_override("fill", fill_s)
		stats_grid.add_child(pbar)

	# Specialty & Sigil Affinity Parchment Card
	var spec_box := PanelContainer.new()
	spec_box.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_panel(UIThemeHelper.COLOR_PARCHMENT, UIThemeHelper.COLOR_GOLD_TRIM, 1, 8))
	cv.add_child(spec_box)

	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 14)
	sm.add_theme_constant_override("margin_right", 14)
	sm.add_theme_constant_override("margin_top", 8)
	sm.add_theme_constant_override("margin_bottom", 8)
	spec_box.add_child(sm)
	sm.add_child(UIThemeHelper.make_label(
		"Specialty: %s\nSigil Affinity: %s" % [String(details_data["specialty"]), String(details_data["affinity"])],
		12,
		UIThemeHelper.COLOR_INK_DARK,
		true
	))

	cv.add_child(UIThemeHelper.make_label(String(details_data["status"]), 12, UIThemeHelper.COLOR_EMERALD, true))

	# Bottom Buttons inside Details Modal
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	cv.add_child(btn_row)

	if bool(details_data["is_lead_option"]):
		var confirm_btn := UIThemeHelper.make_gold_button("✓  Select %s as Lead Scholar" % String(details_data["short_name"]), 14)
		confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confirm_btn.custom_minimum_size = Vector2(0, 40)
		confirm_btn.pressed.connect(func() -> void:
			AudioManager.play_puzzle_success()
			selected_protagonist_start = banner_id
			inspected_banner_id = ""
			_rebuild()
		)
		btn_row.add_child(confirm_btn)

		var start_now_btn := UIThemeHelper.make_stylized_button("▶  Begin Game Now", 14, true)
		start_now_btn.custom_minimum_size = Vector2(180, 40)
		start_now_btn.pressed.connect(func() -> void:
			AudioManager.play_puzzle_success()
			selected_protagonist_start = banner_id
			inspected_banner_id = ""
			GameManager.reset_for_new_game(selected_protagonist_start)
			show_world_loading(false)
		)
		btn_row.add_child(start_now_btn)
	else:
		var back_banners_btn := UIThemeHelper.make_gold_button("←  Back to Character Banners", 14)
		back_banners_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		back_banners_btn.custom_minimum_size = Vector2(0, 40)
		back_banners_btn.pressed.connect(func() -> void:
			AudioManager.play_ui_click()
			inspected_banner_id = ""
			_rebuild()
		)
		btn_row.add_child(back_banners_btn)

	return overlay_root



# ==============================================================================
# STAGE 5: WORLD LOADING SCREEN -> JUMPS INTO MAIN WORLD
# ==============================================================================
func _build_world_loading_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 440)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.04, 0.09, 0.18, 0.95), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 14))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 26)
	m.add_theme_constant_override("margin_bottom", 26)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var emblem_center := CenterContainer.new()
	v.add_child(emblem_center)

	if _tex_emblem != null:
		_emblem_tex_rect = TextureRect.new()
		_emblem_tex_rect.texture = _tex_emblem
		_emblem_tex_rect.custom_minimum_size = Vector2(160, 160)
		_emblem_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_emblem_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem_center.add_child(_emblem_tex_rect)

	var char_profile: Dictionary = GameManager.protagonist_profiles.get(selected_protagonist_start, GameManager.protagonist_profiles["SAMANTHA"])
	var dest_title := UIThemeHelper.make_label("ENTERING BOOK I // THE MAGICAL ACADEMY OUTPOST", 18, UIThemeHelper.COLOR_GOLD_BRIGHT)
	dest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dest_title)

	var lead_lbl := UIThemeHelper.make_label(
		"Lead Scholar: %s (%s)" % [String(char_profile.get("name", "")), String(char_profile.get("thinking_style", ""))],
		14,
		UIThemeHelper.COLOR_CYAN_GLOW
	)
	lead_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lead_lbl)

	var status_row := HBoxContainer.new()
	v.add_child(status_row)

	_loading_status_lbl = UIThemeHelper.make_label("Loading Book I: The Magical Academy Outpost...", 13, UIThemeHelper.COLOR_TEXT_CREAM)
	_loading_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(_loading_status_lbl)

	_loading_pct_lbl = UIThemeHelper.make_label("0%", 13, UIThemeHelper.COLOR_GOLD_BRIGHT)
	status_row.add_child(_loading_pct_lbl)

	_loading_bar = ProgressBar.new()
	_loading_bar.custom_minimum_size = Vector2(0, 22)
	_loading_bar.max_value = 100.0
	_loading_bar.value = _loading_progress
	_loading_bar.show_percentage = false
	_loading_bar.add_theme_stylebox_override("background", UIThemeHelper.make_panel_style(Color(0.03, 0.06, 0.12), UIThemeHelper.COLOR_GOLD_MUTED, 6, 1, 0))
	_loading_bar.add_theme_stylebox_override("fill", UIThemeHelper.make_panel_style(UIThemeHelper.COLOR_CYAN_GLOW, UIThemeHelper.COLOR_GOLD_BRIGHT, 6, 1, 0))
	v.add_child(_loading_bar)


# ==============================================================================
# IN-GAME OVERLAYS: CARETAKER ORON DIALOGUE, PAUSE/INVENTORY, DEFEAT, VICTORY
# ==============================================================================
func _build_dialogue_screen() -> void:
	BookManager.unlock_archive_entry("people_oron")

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(780, 430)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.06, 0.11, 0.22, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 22)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)
	var title := UIThemeHelper.make_label("CARETAKER ORON // KEEPER OF THE PROVING TABLE", 18, UIThemeHelper.COLOR_GOLD_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := UIThemeHelper.make_stylized_button("✕ Close [Esc]", 12)
	close_btn.pressed.connect(close_modal)
	header.add_child(close_btn)

	var oron_speech := ""
	var sam_reply := ""
	var mig_reply := ""

	if not GameManager.bridge_aligned:
		oron_speech = "\"Welcome to the Academy Outpost, young travelers. Look upon the Chasm to the east: six Floating Stones drift out of phase because the bridge lacks a counting command.\n\nRemember the Two-Table system: you cannot move those stones yourself. You must Envision the bridge and give Auri an exact mathematical Command: Count(6).\""
		sam_reply = "Samantha: \"So the Sprite interprets our structured intention! If there are 6 displaced stones in the chasm, we select the Count sigil and pass 6 as the input.\""
		mig_reply = "Miguel: \"Six glowing stones, one clear count. Let's open the Proving Table or cast Count(6) right at the chasm edge!\""
	elif not GameManager.gate_opened:
		if GameManager.quest["stage"] == "TALK_TO_CARETAKER":
			GameManager.advance_quest_stage("UNSEAL_GATE")
		oron_speech = "\"Splendidly commanded! Auri aligned all 6 stones without hesitation—and you unlocked the Water Bridge spell in your Magical Codex.\n\nNow inspect the Requirement-Locked Patterned Gate in the East Courtyard. Its four active pillars hum with 4, 8, 16, and 32. Consult the Working Slate and the Ancient Obelisk to prove the 5th term, then command Auri with Multiply(32, 2) or Count(64)!\""
		sam_reply = "Samantha: \"Each term doubles the preceding value: a(n) = 2 * a(n-1). So the 5th pillar requires 32 * 2 = 64.\""
		mig_reply = "Miguel: \"And once we prove that law, the requirement lock on the Northern Sanctum will release!\""
	elif not GameManager.warden_defeated:
		oron_speech = "\"The Patterned Gate stands open! Beyond lies the Sequence Sanctum, where the Sequence Warden (Chapter Elite) tests whether your proofs hold under pressure.\n\nUse [J] for Resonant Strike, [K] to cast your equipped Codex Spell, and [Space] to Phase Dash!\""
		sam_reply = "Samantha: \"Keep an eye on its telegraph ring—when it charges a pulse, we Phase Dash out of range and counter with Wind Current.\""
		mig_reply = "Miguel: \"Let's equip our favorite spell in the Magical Codex [C] before stepping into the Sanctum!\""
	else:
		oron_speech = "\"The Sequence Warden's core stabilizes the entire Outpost! Step into the Grand Archive Portal at the far north of the Sanctum whenever you are ready to complete this chapter—or explore the Archive Side Quests in your Digital Book [Tab].\""
		sam_reply = "Samantha: \"Every layer of the Chronicle, Knowledge, and Archive now fits together.\""
		mig_reply = "Miguel: \"Onward to the Grand Archive Portal!\""

	var speech_lbl := UIThemeHelper.make_label(oron_speech, 15, UIThemeHelper.COLOR_TEXT_CREAM, true)
	v.add_child(speech_lbl)

	var persp_panel := PanelContainer.new()
	persp_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_panel(UIThemeHelper.COLOR_PARCHMENT, UIThemeHelper.COLOR_GOLD_TRIM, 1, 8))
	v.add_child(persp_panel)

	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 14)
	pm.add_theme_constant_override("margin_right", 14)
	pm.add_theme_constant_override("margin_top", 10)
	pm.add_theme_constant_override("margin_bottom", 10)
	persp_panel.add_child(pm)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pm.add_child(pv)
	pv.add_child(UIThemeHelper.make_label(sam_reply, 13, Color(0.14, 0.28, 0.48), true))
	pv.add_child(UIThemeHelper.make_label(mig_reply, 13, Color(0.45, 0.25, 0.08), true))

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	v.add_child(btn_row)

	if not GameManager.bridge_aligned:
		var b_stones := UIThemeHelper.make_gold_button("Open Proving Table: Floating Stones", 13)
		b_stones.pressed.connect(func() -> void:
			visible = false
			current_mode = Mode.NONE
			open_proving_table_from_dialogue.emit("encounter_floating_stones")
		)
		btn_row.add_child(b_stones)
	elif not GameManager.gate_opened:
		var b_gate := UIThemeHelper.make_gold_button("Open Proving Table: Patterned Gate", 13)
		b_gate.pressed.connect(func() -> void:
			visible = false
			current_mode = Mode.NONE
			open_proving_table_from_dialogue.emit("encounter_patterned_gate")
		)
		btn_row.add_child(b_gate)

	var b_book := UIThemeHelper.make_stylized_button("📖 Open Digital Book", 13, true)
	b_book.pressed.connect(func() -> void:
		visible = false
		current_mode = Mode.NONE
		open_book_from_dialogue.emit("CHRONICLE")
	)
	btn_row.add_child(b_book)

	var b_continue := UIThemeHelper.make_stylized_button("Continue Exploring", 13)
	b_continue.pressed.connect(close_modal)
	btn_row.add_child(b_continue)


func _build_pause_inventory_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 500)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.06, 0.11, 0.22, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 26)
	m.add_theme_constant_override("margin_right", 26)
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 22)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	var header := HBoxContainer.new()
	v.add_child(header)
	var title := UIThemeHelper.make_label("SATCHEL & SYSTEM MENU", 20, UIThemeHelper.COLOR_GOLD_BRIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var resume_btn := UIThemeHelper.make_stylized_button("✕ Resume [Esc]", 13)
	resume_btn.pressed.connect(close_modal)
	header.add_child(resume_btn)

	v.add_child(UIThemeHelper.make_label("EXPEDITION SATCHEL", 13, UIThemeHelper.COLOR_CYAN_GLOW))
	for item in GameManager.inventory:
		var item_card := PanelContainer.new()
		item_card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.09, 0.15, 0.28, 0.95), UIThemeHelper.COLOR_GOLD_TRIM, 1, 8))
		v.add_child(item_card)

		var im := MarginContainer.new()
		im.add_theme_constant_override("margin_left", 14)
		im.add_theme_constant_override("margin_right", 14)
		im.add_theme_constant_override("margin_top", 8)
		im.add_theme_constant_override("margin_bottom", 8)
		item_card.add_child(im)

		var ih := HBoxContainer.new()
		ih.add_theme_constant_override("separation", 12)
		im.add_child(ih)

		var iv := VBoxContainer.new()
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ih.add_child(iv)
		iv.add_child(UIThemeHelper.make_label("%s  (x%d)" % [String(item.get("name", "")), int(item.get("quantity", 1))], 14, UIThemeHelper.COLOR_TEXT_CREAM))
		iv.add_child(UIThemeHelper.make_label(String(item.get("description", "")), 11, UIThemeHelper.COLOR_TEXT_DIM, true))

		if String(item.get("type", "")) == "CONSUMABLE":
			var use_btn := UIThemeHelper.make_gold_button("Use Elixir", 12)
			use_btn.disabled = int(item.get("quantity", 0)) <= 0
			use_btn.pressed.connect(func() -> void:
				GameManager.use_consumable(String(item.get("id", "")))
				_rebuild()
			)
			ih.add_child(use_btn)

	v.add_child(UIThemeHelper.make_label("OPTIONS & ACCESSIBILITY", 13, UIThemeHelper.COLOR_CYAN_GLOW))
	var relax_chk := CheckButton.new()
	relax_chk.text = "Relaxed Story Mode (50% Reduced Incoming Damage)"
	relax_chk.button_pressed = bool(GameManager.settings.get("relaxed_mode", false))
	relax_chk.toggled.connect(func(on: bool) -> void:
		GameManager.settings["relaxed_mode"] = on
	)
	v.add_child(relax_chk)

	var shake_chk := CheckButton.new()
	shake_chk.text = "Screen Shake Effects Enabled"
	shake_chk.button_pressed = bool(GameManager.settings.get("screen_shake", true))
	shake_chk.toggled.connect(func(on: bool) -> void:
		GameManager.settings["screen_shake"] = on
	)
	v.add_child(shake_chk)

	var sound_chk := CheckButton.new()
	sound_chk.text = "Procedural Sound Effects Enabled"
	sound_chk.button_pressed = AudioManager.audio_enabled
	sound_chk.toggled.connect(func(on: bool) -> void:
		AudioManager.audio_enabled = on
	)
	v.add_child(sound_chk)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	v.add_child(footer)

	var save_btn := UIThemeHelper.make_stylized_button("💾 Save Progress", 13, true)
	save_btn.pressed.connect(func() -> void:
		GameManager.save_game()
		AudioManager.play_puzzle_success()
	)
	footer.add_child(save_btn)

	var title_btn := UIThemeHelper.make_stylized_button("Return to Starting Screen", 13)
	title_btn.pressed.connect(func() -> void:
		GameManager.save_game()
		show_start_screen()
		resume_world_requested.emit()
	)
	footer.add_child(title_btn)


func _build_defeat_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 320)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.14, 0.05, 0.08, 0.98), UIThemeHelper.COLOR_CRIMSON, 2, 12))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	v.add_child(UIThemeHelper.make_label("HARMONIC DISSONANCE // COHERENCE DEPLETED", 20, UIThemeHelper.COLOR_CRIMSON))
	v.add_child(UIThemeHelper.make_label(
		"Caretaker Oron recalls Samantha, Miguel, and Auri to the West Courtyard Anchor before the dissonance becomes permanent. All puzzle proofs, unlocked Sigils, and Codex spells remain intact.",
		14,
		UIThemeHelper.COLOR_TEXT_CREAM,
		true
	))

	var btn := UIThemeHelper.make_gold_button("Restore Full HP & Mana at West Courtyard", 14)
	btn.pressed.connect(func() -> void:
		GameManager.modify_hp(GameManager.player_max_hp)
		GameManager.modify_mana(GameManager.player_max_mana)
		AudioManager.play_puzzle_success()
		close_modal()
	)
	v.add_child(btn)


func _build_victory_screen() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 440)
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_navy_panel(Color(0.06, 0.13, 0.22, 0.98), UIThemeHelper.COLOR_GOLD_BRIGHT, 2, 14))
	center.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_top", 26)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	v.add_child(UIThemeHelper.make_label("CHAPTER I COMPLETE // THE OUTPOST PROVEN", 24, UIThemeHelper.COLOR_GOLD_BRIGHT))
	v.add_child(UIThemeHelper.make_label(
		"Samantha Yu, Miguel Perez, and Auri step across the threshold of the Grand Archive Portal.\n\n• You mastered the Two-Table Spellcraft System (Envision + Command).\n• You aligned the Floating Stones and unsealed the Requirement-Locked Patterned Gate (64).\n• You recorded your mathematical discoveries in the 3-Layer Digital Book and unlocked new spells in the Magical Codex!",
		15,
		UIThemeHelper.COLOR_TEXT_CREAM,
		true
	))

	var stats_box := PanelContainer.new()
	stats_box.add_theme_stylebox_override("panel", UIThemeHelper.make_parchment_panel(UIThemeHelper.COLOR_PARCHMENT, UIThemeHelper.COLOR_GOLD_TRIM, 1, 8))
	v.add_child(stats_box)

	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 16)
	sm.add_theme_constant_override("margin_right", 16)
	sm.add_theme_constant_override("margin_top", 10)
	sm.add_theme_constant_override("margin_bottom", 10)
	stats_box.add_child(sm)

	sm.add_child(UIThemeHelper.make_label(
		"Scholar Level: %d   |   Unlocked Spells: %d / 12   |   Sync Code Unlocked: CODEX-ALL" % [
			GameManager.player_level,
			CodexManager.get_unlocked_count()
		],
		14,
		UIThemeHelper.COLOR_INK_DARK
	))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)

	var cont_btn := UIThemeHelper.make_gold_button("Continue Exploring Outpost & Archive Quests", 14)
	cont_btn.pressed.connect(close_modal)
	row.add_child(cont_btn)

	var codex_unlock_btn := UIThemeHelper.make_stylized_button("Unlock All 12 Codex Spells (Sandbox Reward)", 13, true)
	codex_unlock_btn.pressed.connect(func() -> void:
		BookManager.apply_sync_code("CODEX-ALL")
		AudioManager.play_puzzle_success()
		_rebuild()
	)
	row.add_child(codex_unlock_btn)
