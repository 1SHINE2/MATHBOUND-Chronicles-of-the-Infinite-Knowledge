extends Node
## Manages Quest Progression, Protagonist State (Samantha Yu vs. Miguel Perez),
## Inventory, Settings, and JSON Save/Load persistence.

signal protagonist_changed(protagonist_id: String)
signal player_stats_changed(hp: int, max_hp: int, mana: int, max_mana: int, level: int)
signal quest_updated(quest: Dictionary)
signal floating_stones_bridge_aligned()
signal patterned_gate_unsealed()
signal inventory_updated()
signal game_saved()

const SAVE_FILE_PATH := "user://mathbound_save_v1.json"

var protagonist_id: String = "SAMANTHA"
var player_level: int = 3
var player_hp: int = 100
var player_max_hp: int = 100
var player_mana: int = 100
var player_max_mana: int = 100
var player_pos: Vector2 = Vector2(360, 620)

var bridge_aligned: bool = false
var gate_opened: bool = false
var wisps_defeated: bool = false
var warden_defeated: bool = false

var settings: Dictionary = {
	"sfx_volume": 80.0,
	"music_volume": 45.0,
	"screen_shake": true,
	"relaxed_mode": false,
	"high_contrast": false
}

var protagonist_profiles: Dictionary = {
	"SAMANTHA": {
		"id": "SAMANTHA",
		"name": "Samantha Yu",
		"age": 10,
		"height": "4'11\"",
		"thinking_style": "Meditative Thinking",
		"guiding_question": "What does it mean?",
		"summary": "A 10-year-old childhood friend inclined to reflect on meaning, interpretation, implications, and underlying assumptions.",
		"specialty": "Meditative Insight & Pattern Resonance",
		"color": Color("38bdf8")
	},
	"MIGUEL": {
		"id": "MIGUEL",
		"name": "Miguel Perez",
		"age": 11,
		"height": "5'4\"",
		"thinking_style": "Calculative Thinking",
		"guiding_question": "How does it work?",
		"summary": "An 11-year-old childhood friend inclined to investigate mechanisms, relationships, procedures, and how parts contribute to a result.",
		"specialty": "Calculative Precision & Structural Analysis",
		"color": Color("fbbf24")
	}
}

var quest: Dictionary = {
	"id": "THE_FLOATING_PATH_AND_SILENT_GATE",
	"title": "The Floating Path & Silent Gate",
	"summary": "Explore the Academy Outpost with Auri, align the Floating Stones via the Two-Table system, unseal the Requirement-Locked Gate, and pass the Sequence Warden's Elite trial.",
	"stage": "COUNT_STONES",
	"objectives": [
		{"stage": "COUNT_STONES", "description": "Count the floating rocks (0/6) & align them via the Counting Sigil", "completed": false},
		{"stage": "TALK_TO_CARETAKER", "description": "Speak with Caretaker Oron & study the Courtyard Chalkboard", "completed": false},
		{"stage": "UNSEAL_GATE", "description": "Satisfy the Requirement Gate's doubling sequence (4, 8, 16, 32 -> 64)", "completed": false},
		{"stage": "DEFEAT_WISPS", "description": "Calm the agitated Pattern Wisps in the East Courtyard", "completed": false},
		{"stage": "DEFEAT_WARDEN", "description": "Overcome The Sequence Warden (Chapter Elite) in the Northern Sanctum", "completed": false},
		{"stage": "REPORT_TO_CARETAKER", "description": "Report your discovery to Caretaker Oron or enter the Grand Archive", "completed": false}
	]
}

var inventory: Array[Dictionary] = [
	{
		"id": "item_focus",
		"name": "Resonant Focus Wand",
		"type": "TOOL",
		"description": "A magical interface (not a mana battery) used to communicate formal mathematical commands to Magic Sprites.",
		"quantity": 1
	},
	{
		"id": "item_chronicle_book1",
		"name": "Chronicle I: The Magical Academy",
		"type": "KEY",
		"description": "Contains the 3 layers of recorded understanding: Chronicle, Knowledge, and Archive.",
		"quantity": 1
	},
	{
		"id": "item_elixir",
		"name": "Harmonic Dew Elixir",
		"type": "CONSUMABLE",
		"description": "Restores 45 HP and 35 Resonance Energy.",
		"quantity": 2
	}
]

func get_active_profile() -> Dictionary:
	return protagonist_profiles.get(protagonist_id, protagonist_profiles["SAMANTHA"])

func get_companion_profile() -> Dictionary:
	return protagonist_profiles["MIGUEL"] if protagonist_id == "SAMANTHA" else protagonist_profiles["SAMANTHA"]

func set_protagonist(new_id: String) -> void:
	if protagonist_profiles.has(new_id):
		protagonist_id = new_id
		protagonist_changed.emit(protagonist_id)

func swap_protagonist() -> void:
	set_protagonist("MIGUEL" if protagonist_id == "SAMANTHA" else "SAMANTHA")
	AudioManager.play_ui_click()

func modify_hp(delta: int) -> void:
	player_hp = clampi(player_hp + delta, 0, player_max_hp)
	player_stats_changed.emit(player_hp, player_max_hp, player_mana, player_max_mana, player_level)

func modify_mana(delta: int) -> void:
	player_mana = clampi(player_mana + delta, 0, player_max_mana)
	player_stats_changed.emit(player_hp, player_max_hp, player_mana, player_max_mana, player_level)

func advance_quest_stage(new_stage: String) -> void:
	for obj in quest["objectives"]:
		if obj["stage"] == quest["stage"]:
			obj["completed"] = true
	quest["stage"] = new_stage
	quest_updated.emit(quest)
	save_game()

func update_stone_count_objective(counted: int, total: int) -> void:
	for obj in quest["objectives"]:
		if obj["stage"] == "COUNT_STONES":
			obj["description"] = "Count the floating rocks (%d/%d) & cast Count(%d)" % [counted, total, total]
	quest_updated.emit(quest)

func mark_bridge_aligned() -> void:
	if not bridge_aligned:
		bridge_aligned = true
		player_level = max(player_level, 4)
		BookManager.unlock_chapter("chronicle_ch2")
		CodexManager.unlock_spell("spell_harmonic_bridge")
		if quest["stage"] == "COUNT_STONES":
			advance_quest_stage("TALK_TO_CARETAKER")
		player_stats_changed.emit(player_hp, player_max_hp, player_mana, player_max_mana, player_level)
		floating_stones_bridge_aligned.emit()

func mark_gate_unsealed() -> void:
	if not gate_opened:
		gate_opened = true
		player_level = max(player_level, 5)
		BookManager.unlock_chapter("chronicle_ch3")
		BookManager.unlock_archive_entry("objects_gate")
		BookManager.unlock_archive_entry("words_geometric")
		BookManager.unlock_archive_entry("documents_inscription")
		CodexManager.unlock_spell("spell_ice_prism")
		if quest["stage"] in ["COUNT_STONES", "TALK_TO_CARETAKER", "UNSEAL_GATE"]:
			advance_quest_stage("DEFEAT_WARDEN" if wisps_defeated else "DEFEAT_WISPS")
		player_stats_changed.emit(player_hp, player_max_hp, player_mana, player_max_mana, player_level)
		patterned_gate_unsealed.emit()

func use_consumable(item_id: String) -> bool:
	for i in range(inventory.size()):
		var item: Dictionary = inventory[i]
		if item["id"] == item_id and item["type"] == "CONSUMABLE" and item["quantity"] > 0:
			item["quantity"] -= 1
			modify_hp(45)
			modify_mana(35)
			AudioManager.play_puzzle_success()
			if item["quantity"] <= 0:
				inventory.remove_at(i)
			inventory_updated.emit()
			return true
	return false

func reset_for_new_game(selected_protagonist: String = "SAMANTHA") -> void:
	protagonist_id = selected_protagonist
	player_level = 3
	player_hp = 100
	player_mana = 100
	player_pos = Vector2(360, 620)
	bridge_aligned = false
	gate_opened = false
	wisps_defeated = false
	warden_defeated = false
	MagicManager.encounters["encounter_floating_stones"]["observed_count"] = 0
	MagicManager.encounters["encounter_floating_stones"]["solved"] = false
	MagicManager.encounters["encounter_patterned_gate"]["solved"] = false
	for obj in quest["objectives"]:
		obj["completed"] = false
	quest["objectives"][0]["description"] = "Count the floating rocks (0/6) & cast Count(6)"
	quest["stage"] = "COUNT_STONES"
	player_stats_changed.emit(player_hp, player_max_hp, player_mana, player_max_mana, player_level)
	quest_updated.emit(quest)

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func save_game() -> void:
	var unlocked_spells: Array = []
	for sid in CodexManager.spells:
		if CodexManager.spells[sid]["unlocked"]:
			unlocked_spells.append(sid)
	var discovered_archive: Array = []
	for entry in BookManager.archive_entries:
		if entry["discovered"]:
			discovered_archive.append(entry["id"])
	var unlocked_chapters: Array = []
	for ch in BookManager.chapters:
		if ch["unlocked"]:
			unlocked_chapters.append(ch["id"])

	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"protagonist_id": protagonist_id,
		"player_level": player_level,
		"player_hp": player_hp,
		"player_mana": player_mana,
		"player_x": player_pos.x,
		"player_y": player_pos.y,
		"bridge_aligned": bridge_aligned,
		"gate_opened": gate_opened,
		"wisps_defeated": wisps_defeated,
		"warden_defeated": warden_defeated,
		"quest_stage": quest["stage"],
		"equipped_spell_id": CodexManager.equipped_spell_id,
		"unlocked_spells": unlocked_spells,
		"discovered_archive": discovered_archive,
		"unlocked_chapters": unlocked_chapters,
		"settings": settings
	}
	var f := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
		game_saved.emit()

func load_game() -> bool:
	if not has_save_file():
		return false
	var f := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	protagonist_id = d.get("protagonist_id", "SAMANTHA")
	player_level = int(d.get("player_level", 3))
	player_hp = int(d.get("player_hp", 100))
	player_mana = int(d.get("player_mana", 100))
	player_pos = Vector2(float(d.get("player_x", 360.0)), float(d.get("player_y", 620.0)))
	bridge_aligned = bool(d.get("bridge_aligned", false))
	gate_opened = bool(d.get("gate_opened", false))
	wisps_defeated = bool(d.get("wisps_defeated", false))
	warden_defeated = bool(d.get("warden_defeated", false))
	quest["stage"] = str(d.get("quest_stage", "COUNT_STONES"))
	CodexManager.equipped_spell_id = str(d.get("equipped_spell_id", "spell_wind_current"))

	for sid in d.get("unlocked_spells", []):
		if CodexManager.spells.has(sid):
			CodexManager.spells[sid]["unlocked"] = true
	for aid in d.get("discovered_archive", []):
		BookManager.unlock_archive_entry(aid)
	for cid in d.get("unlocked_chapters", []):
		BookManager.unlock_chapter(cid)
	if d.has("settings") and typeof(d["settings"]) == TYPE_DICTIONARY:
		settings.merge(d["settings"], true)
		AudioManager.set_volumes(settings["sfx_volume"], settings["music_volume"])
	return true
