extends Node2D
## Root scene controller for MATHBOUND: Chronicles of the Infinite Knowledge.
## Coordinates the 5-stage startup sequence, the 2D Academy Outpost World, and the UI CanvasLayer modals.

const AcademyWorldViewScript = preload("res://scenes/academy_world.gd")
const ExplorationHUDScript = preload("res://ui/exploration_hud.gd")
const ProvingTableModalScript = preload("res://ui/proving_table_modal.gd")
const MagicalCodexModalScript = preload("res://ui/magical_codex_modal.gd")
const DigitalBookModalScript = preload("res://ui/digital_book_modal.gd")
const ChalkboardModalScript = preload("res://ui/chalkboard_modal.gd")
const StoryAndMenusModalScript = preload("res://ui/story_and_menus_modal.gd")

var world_view: AcademyWorldView
var ui_layer: CanvasLayer

var hud: ExplorationHUD
var proving_table_modal: ProvingTableModal
var magical_codex_modal: MagicalCodexModal
var digital_book_modal: DigitalBookModal
var chalkboard_modal: ChalkboardModal
var story_menus_modal: StoryAndMenusModal


func _ready() -> void:
	# 1. Instantiate the playable 2D Academy Outpost World
	world_view = AcademyWorldViewScript.new()
	world_view.name = "AcademyWorldView"
	add_child(world_view)

	# 2. Create the UI CanvasLayer
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	# 3. Instantiate HUD and Modals
	hud = ExplorationHUDScript.new()
	hud.name = "ExplorationHUD"
	hud.world_ref = world_view
	ui_layer.add_child(hud)

	proving_table_modal = ProvingTableModalScript.new()
	proving_table_modal.name = "ProvingTableModal"
	proving_table_modal.visible = false
	ui_layer.add_child(proving_table_modal)

	magical_codex_modal = MagicalCodexModalScript.new()
	magical_codex_modal.name = "MagicalCodexModal"
	magical_codex_modal.visible = false
	ui_layer.add_child(magical_codex_modal)

	digital_book_modal = DigitalBookModalScript.new()
	digital_book_modal.name = "DigitalBookModal"
	digital_book_modal.visible = false
	ui_layer.add_child(digital_book_modal)

	chalkboard_modal = ChalkboardModalScript.new()
	chalkboard_modal.name = "ChalkboardModal"
	chalkboard_modal.visible = false
	ui_layer.add_child(chalkboard_modal)

	story_menus_modal = StoryAndMenusModalScript.new()
	story_menus_modal.name = "StoryAndMenusModal"
	ui_layer.add_child(story_menus_modal)

	# 4. Wire World <-> UI Signals
	world_view.interact_prompt_changed.connect(hud.set_interact_prompt)
	world_view.sprite_message_changed.connect(hud.set_sprite_message)
	world_view.open_dialogue_requested.connect(func(_npc_id: String) -> void:
		_close_all_modals()
		story_menus_modal.show_oron_dialogue()
		_sync_world_input_lock()
	)
	world_view.open_proving_table_requested.connect(_open_proving_table)
	world_view.open_chalkboard_requested.connect(_open_chalkboard)
	world_view.open_digital_book_requested.connect(_open_digital_book)
	world_view.player_defeated.connect(_on_player_defeated)
	world_view.prototype_victory_triggered.connect(_on_prototype_victory)

	# HUD signals
	hud.open_proving_table_pressed.connect(func() -> void:
		_open_proving_table(_get_contextual_encounter_id())
	)
	hud.open_magical_codex_pressed.connect(_open_magical_codex)
	hud.open_digital_book_pressed.connect(func() -> void:
		_open_digital_book("CHRONICLE")
	)
	hud.open_chalkboard_pressed.connect(_open_chalkboard)
	hud.quick_spell_submitted.connect(_on_hud_quick_spell_submitted)

	# Modal close & cross-navigation signals
	proving_table_modal.closed.connect(func() -> void:
		proving_table_modal.visible = false
		_sync_world_input_lock()
	)
	proving_table_modal.encounter_solved.connect(_on_proving_table_encounter_solved)

	magical_codex_modal.closed.connect(func() -> void:
		magical_codex_modal.visible = false
		_sync_world_input_lock()
	)

	digital_book_modal.closed.connect(func() -> void:
		digital_book_modal.visible = false
		_sync_world_input_lock()
	)
	digital_book_modal.open_magical_codex_requested.connect(func() -> void:
		digital_book_modal.visible = false
		_open_magical_codex()
	)

	chalkboard_modal.closed.connect(func() -> void:
		chalkboard_modal.visible = false
		_sync_world_input_lock()
	)
	chalkboard_modal.open_proving_table_requested.connect(func() -> void:
		_open_proving_table("encounter_patterned_gate")
	)
	chalkboard_modal.open_digital_book_requested.connect(func() -> void:
		_open_digital_book("KNOWLEDGE")
	)

	story_menus_modal.enter_main_world_requested.connect(_on_enter_main_world_requested)
	story_menus_modal.open_proving_table_from_dialogue.connect(_open_proving_table)
	story_menus_modal.open_book_from_dialogue.connect(_open_digital_book)
	story_menus_modal.resume_world_requested.connect(_sync_world_input_lock)

	# Ensure the game opens across the whole screen (Fullscreen) and allows resizing if switched to windowed
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Launch Stage 1 of the 5-Stage Startup Flow: Initial Boot Loading Screen
	story_menus_modal.show_boot_loading_screen()
	_sync_world_input_lock()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event := event as InputEventKey

	# F11 toggles between Whole-Screen Fullscreen and Resizable Maximized Window anytime
	if key_event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return

	# Ignore in-world hotkeys while the 5-stage startup sequence is active
	if story_menus_modal.visible and story_menus_modal.is_startup_flow_active():
		return

	if key_event.keycode == KEY_ESCAPE:
		if _is_any_modal_open():
			_close_all_modals()
		else:
			_open_pause_inventory()
		get_viewport().set_input_as_handled()
		return

	# Number keys 1-7 select Sigils in the HUD dock when exploring
	if not _is_any_modal_open():
		var sigil_hotkeys := [
			"sigil_count",
			"sigil_add",
			"sigil_subtract",
			"sigil_multiply",
			"sigil_divide",
			"sigil_greater",
			"sigil_less"
		]
		if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_7:
			var slot_idx: int = key_event.keycode - KEY_1
			if slot_idx >= 0 and slot_idx < sigil_hotkeys.size():
				MagicManager.select_sigil(sigil_hotkeys[slot_idx])
				AudioManager.play_ui_click()
			get_viewport().set_input_as_handled()
			return

	match key_event.keycode:
		KEY_P:
			if proving_table_modal.visible:
				proving_table_modal.visible = false
				_sync_world_input_lock()
			else:
				_open_proving_table(_get_contextual_encounter_id())
			get_viewport().set_input_as_handled()
		KEY_C:
			if magical_codex_modal.visible:
				magical_codex_modal.visible = false
				_sync_world_input_lock()
			else:
				_open_magical_codex()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			if digital_book_modal.visible:
				digital_book_modal.visible = false
				_sync_world_input_lock()
			else:
				_open_digital_book("CHRONICLE")
			get_viewport().set_input_as_handled()
		KEY_I:
			if story_menus_modal.visible and story_menus_modal.current_mode == StoryAndMenusModal.Mode.PAUSE_INVENTORY:
				story_menus_modal.close_modal()
			else:
				_open_pause_inventory()
			get_viewport().set_input_as_handled()


func _get_contextual_encounter_id() -> String:
	if not GameManager.bridge_aligned:
		return "encounter_floating_stones"
	return "encounter_patterned_gate"


func _open_proving_table(encounter_id: String) -> void:
	_close_all_modals()
	proving_table_modal.load_encounter(encounter_id)
	proving_table_modal.visible = true
	AudioManager.play_ui_click()
	_sync_world_input_lock()


func _open_magical_codex() -> void:
	_close_all_modals()
	magical_codex_modal.visible = true
	AudioManager.play_ui_click()
	_sync_world_input_lock()


func _open_digital_book(layer_name: String = "CHRONICLE") -> void:
	_close_all_modals()
	digital_book_modal.switch_layer(layer_name)
	digital_book_modal.visible = true
	AudioManager.play_ui_click()
	_sync_world_input_lock()


func _open_chalkboard() -> void:
	_close_all_modals()
	chalkboard_modal.visible = true
	AudioManager.play_ui_click()
	_sync_world_input_lock()


func _open_pause_inventory() -> void:
	_close_all_modals()
	story_menus_modal.show_pause_inventory()
	_sync_world_input_lock()


func _close_all_modals() -> void:
	proving_table_modal.visible = false
	magical_codex_modal.visible = false
	digital_book_modal.visible = false
	chalkboard_modal.visible = false
	if not story_menus_modal.is_startup_flow_active():
		story_menus_modal.visible = false
		story_menus_modal.current_mode = StoryAndMenusModal.Mode.NONE
	_sync_world_input_lock()


func _is_any_modal_open() -> bool:
	return (
		proving_table_modal.visible
		or magical_codex_modal.visible
		or digital_book_modal.visible
		or chalkboard_modal.visible
		or story_menus_modal.visible
	)


func _sync_world_input_lock() -> void:
	var modal_open := _is_any_modal_open()
	world_view.gameplay_active = not modal_open
	hud.visible = not (story_menus_modal.visible and story_menus_modal.is_startup_flow_active())


func _on_enter_main_world_requested(protagonist_id: String, is_continued_game: bool) -> void:
	GameManager.set_protagonist(protagonist_id)
	if not is_continued_game or not GameManager.bridge_aligned or not world_view.is_valid_world_pos(GameManager.player_pos):
		GameManager.player_pos = world_view.get_default_spawn_pos()
	world_view.player_pos = GameManager.player_pos
	world_view.companion_pos = GameManager.player_pos + Vector2(65, -35)
	world_view.sprite_auri_pos = GameManager.player_pos + Vector2(-24, -58)
	story_menus_modal.visible = false
	story_menus_modal.current_mode = StoryAndMenusModal.Mode.NONE
	_sync_world_input_lock()
	hud.show_toast("Arrived at Book I: The Magical Academy Outpost")


func _on_proving_table_encounter_solved(encounter_id: String) -> void:
	if encounter_id == "encounter_floating_stones":
		GameManager.mark_bridge_aligned()
		hud.show_toast("Floating Stones Aligned! Bridge across the Chasm is now open.")
	elif encounter_id == "encounter_patterned_gate":
		GameManager.mark_gate_unsealed()
		hud.show_toast("Patterned Gate Unsealed (64)! The Sequence Sanctum is now open.")


func _on_player_defeated() -> void:
	_close_all_modals()
	world_view.player_pos = world_view.get_default_spawn_pos()
	world_view.companion_pos = world_view.player_pos + Vector2(-46, 20)
	story_menus_modal.show_defeat_modal()
	_sync_world_input_lock()


func _on_prototype_victory() -> void:
	_close_all_modals()
	story_menus_modal.show_victory_modal()
	_sync_world_input_lock()


func _on_hud_quick_spell_submitted(sigil_id: String, input_value: int) -> void:
	var enc_id := _get_contextual_encounter_id()
	var inputs: Array = [input_value]
	if MagicManager.sigils.has(sigil_id) and int(MagicManager.sigils[sigil_id].get("expected_inputs", 1)) == 2:
		if input_value == 64 and sigil_id == "sigil_multiply":
			inputs = [32, 2]
		else:
			inputs = [input_value, 1]

	var result: Dictionary = MagicManager.evaluate_proving_table_command(enc_id, sigil_id, inputs)
	if bool(result.get("success", false)):
		_on_proving_table_encounter_solved(enc_id)
		hud.set_sprite_message(String(result.get("diagnostic", "Spell succeeded!")))
	else:
		hud.show_toast(String(result.get("title", "Spell Failed")))
		hud.set_sprite_message(String(result.get("diagnostic", "Check your expression in the Proving Table [P].")))
