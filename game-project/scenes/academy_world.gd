class_name AcademyWorldView
extends Node2D
## True 2.5D Isometric Magical Academy World (Strictly Matching the 3rd Reference Image)
## - Renders the high-detail character-free 2.5D Isometric Magical Academy Room texture
##   (`res://assets/world/magical_academy_room.jpg`) for the West Academy Study Hall & Checkered Foyer,
##   so the in-game screen looks directly like the 3rd reference image.
## - Playable characters (Samantha Yu, Miguel Perez), Caretaker Oron, and Magic Sprite Auri are drawn
##   in matching dark-outlined pixel-art isometric style with pointed witch/scholar hats.
## - Walking through the bottom-right Stone Archway leads seamlessly to the Isometric Chasm
##   (6 Floating Stones), East Isometric Courtyard, Requirement-Locked Patterned Gate, and Sequence Sanctum.

signal interact_prompt_changed(prompt_text: String)
signal open_dialogue_requested(npc_id: String)
signal open_proving_table_requested(encounter_id: String)
signal open_chalkboard_requested()
signal open_digital_book_requested(layer: String)
signal sprite_message_changed(message: String)
signal player_defeated()
signal prototype_victory_triggered()

const WORLD_W := 2650.0
const WORLD_H := 1450.0

# Exact bounding rect where the 1:1 Isometric Magical Academy Room artwork is rendered
const ROOM_RECT := Rect2(140.0, 30.0, 1060.0, 1060.0)

# Isometric projection helper for the East Chasm, Floating Stones, Courtyard & Sanctum
const ISO_ORIGIN := Vector2(1240.0, 360.0)
const TILE_W := 96.0
const TILE_H := 48.0

var _room_tex: Texture2D

var gameplay_active: bool = false
var player_pos: Vector2 = Vector2(780.0, 495.0)
var player_vel: Vector2 = Vector2.ZERO
var player_facing: Vector2 = Vector2(1, 0.5).normalized()
var walk_cycle: float = 0.0

var companion_pos: Vector2 = Vector2(860.0, 445.0)
var companion_thought: String = ""
var companion_thought_timer: float = 0.0

var sprite_auri_pos: Vector2 = Vector2(755.0, 430.0)
var time_sec: float = 0.0

# Combat & Dodge Timers
var attack_cooldown: float = 0.0
var attack_anim_timer: float = 0.0
var spell_cooldown: float = 0.0
var dodge_timer: float = 0.0
var dodge_cooldown: float = 0.0
var invuln_timer: float = 0.0
var shield_timer: float = 0.0
var screen_shake: float = 0.0

var camera: Camera2D

var floating_stones: Array[Dictionary] = []
var interactables: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var active_waves: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []
var current_interactable_id: String = ""


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


func iso_to_screen(u: float, v: float, z: float = 0.0) -> Vector2:
	return ISO_ORIGIN + Vector2((u - v) * (TILE_W * 0.5), (u + v) * (TILE_H * 0.5) - z)


func get_default_spawn_pos() -> Vector2:
	# Center of the Isometric Wooden Study Hall (right beside the bubbling Golden Cauldron & Workbenches)
	return Vector2(770.0, 490.0)


func is_valid_world_pos(pos: Vector2) -> bool:
	return pos.x >= 240.0 and pos.x <= 2450.0 and pos.y >= 160.0 and pos.y <= 1250.0


func _ready() -> void:
	_room_tex = _load_texture_safe("res://assets/world/magical_academy_room.jpg")
	if _room_tex == null:
		_room_tex = _load_texture_safe("res://assets/world/isometric_study_hall_ref.jpg")

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(1.0, 1.0)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_W)
	camera.limit_bottom = int(WORLD_H)
	add_child(camera)

	_init_landmarks()
	reset_enemies()

	player_pos = get_default_spawn_pos()
	GameManager.player_pos = player_pos
	companion_pos = Vector2(855.0, 440.0)
	sprite_auri_pos = player_pos + Vector2(-24, -58)

	GameManager.floating_stones_bridge_aligned.connect(_on_bridge_aligned)
	GameManager.patterned_gate_unsealed.connect(_on_gate_unsealed)


func _init_landmarks() -> void:
	# 6 Floating Stones in the Isometric Chasm just outside the bottom-right Stone Archway (x: 1230..1530)
	floating_stones = [
		{
			"id": 0,
			"base_pos": Vector2(1255.0, 680.0),
			"bridge_pos": Vector2(1240.0, 790.0),
			"counted": false
		},
		{
			"id": 1,
			"base_pos": Vector2(1345.0, 635.0),
			"bridge_pos": Vector2(1300.0, 790.0),
			"counted": false
		},
		{
			"id": 2,
			"base_pos": Vector2(1445.0, 670.0),
			"bridge_pos": Vector2(1360.0, 790.0),
			"counted": false
		},
		{
			"id": 3,
			"base_pos": Vector2(1275.0, 910.0),
			"bridge_pos": Vector2(1420.0, 790.0),
			"counted": false
		},
		{
			"id": 4,
			"base_pos": Vector2(1375.0, 945.0),
			"bridge_pos": Vector2(1480.0, 790.0),
			"counted": false
		},
		{
			"id": 5,
			"base_pos": Vector2(1475.0, 895.0),
			"bridge_pos": Vector2(1540.0, 790.0),
			"counted": false
		}
	]

	interactables = [
		{
			"id": "npc_oron",
			"name": "Caretaker Oron",
			"pos": Vector2(825.0, 865.0),
			"radius": 95.0,
			"prompt": "[E] Speak with Caretaker Oron"
		},
		{
			"id": "station_chalkboard",
			"name": "Scholastic Discovery Workbench",
			"pos": Vector2(615.0, 625.0),
			"radius": 98.0,
			"prompt": "[E] Study Hypotheses at Scholastic Workbench"
		},
		{
			"id": "encounter_floating_stones",
			"name": "The Floating Path Chasm",
			"pos": Vector2(1155.0, 790.0),
			"radius": 115.0,
			"prompt": "[E] Open Proving Table: Align Floating Stones"
		},
		{
			"id": "obelisk_inscription",
			"name": "The Inscription of Rhythms",
			"pos": Vector2(1740.0, 720.0),
			"radius": 95.0,
			"prompt": "[E] Inspect Ancient Inscription Obelisk"
		},
		{
			"id": "gate_patterned",
			"name": "Requirement Gate: The Patterned Gate",
			"pos": Vector2(1940.0, 560.0),
			"radius": 110.0,
			"prompt": "[E] Inspect Requirement Gate (Forbidden Sanctum)"
		},
		{
			"id": "grand_archive_portal",
			"name": "Portal to the Grand Infinite Library",
			"pos": Vector2(1940.0, 220.0),
			"radius": 105.0,
			"prompt": "[E] Enter Grand Infinite Archive"
		}
	]


func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_E, KEY_ENTER:
				trigger_interact()
				get_viewport().set_input_as_handled()
			KEY_J:
				trigger_basic_attack()
				get_viewport().set_input_as_handled()
			KEY_K:
				trigger_equipped_spell()
				get_viewport().set_input_as_handled()
			KEY_SPACE, KEY_SHIFT:
				trigger_dodge()
				get_viewport().set_input_as_handled()


func reset_enemies() -> void:
	var w1 := Vector2(1820.0, 860.0)
	var w2 := Vector2(2080.0, 780.0)
	var warden := Vector2(1940.0, 370.0)
	enemies = [
		{
			"id": "wisp_alpha",
			"type": "PATTERN_WISP",
			"name": "Pattern Wisp α",
			"pos": w1,
			"home": w1,
			"hp": 60,
			"max_hp": 60,
			"state": "PATROL",
			"timer": 0.0,
			"telegraph_pos": Vector2.ZERO,
			"telegraph_radius": 82.0,
			"vulnerable": false,
			"hit_flash": 0.0
		},
		{
			"id": "wisp_beta",
			"type": "PATTERN_WISP",
			"name": "Pattern Wisp β",
			"pos": w2,
			"home": w2,
			"hp": 60,
			"max_hp": 60,
			"state": "PATROL",
			"timer": 1.1,
			"telegraph_pos": Vector2.ZERO,
			"telegraph_radius": 82.0,
			"vulnerable": false,
			"hit_flash": 0.0
		},
		{
			"id": "sequence_warden",
			"type": "SEQUENCE_WARDEN",
			"name": "The Sequence Warden (Chapter Elite)",
			"pos": warden,
			"home": warden,
			"hp": 220,
			"max_hp": 220,
			"state": "PATROL",
			"timer": 0.0,
			"telegraph_pos": Vector2.ZERO,
			"telegraph_radius": 125.0,
			"vulnerable": false,
			"hit_flash": 0.0
		}
	]


func sync_from_game_manager() -> void:
	if is_valid_world_pos(GameManager.player_pos):
		player_pos = GameManager.player_pos
	else:
		player_pos = get_default_spawn_pos()
		GameManager.player_pos = player_pos
	companion_pos = player_pos + Vector2(65, -35)


func _process(delta: float) -> void:
	time_sec += delta
	if screen_shake > 0.0:
		screen_shake = maxf(0.0, screen_shake - delta * 20.0)
		camera.offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	else:
		camera.offset = Vector2.ZERO

	# Keep camera smoothly framing the isometric room when inside West Wing, and following eastward into Courtyard
	var cam_target := player_pos
	if player_pos.x < 1120.0:
		cam_target = player_pos.lerp(Vector2(690.0, 560.0), 0.55)
	camera.position = cam_target

	if not gameplay_active:
		queue_redraw()
		return

	_update_timers(delta)
	_handle_movement(delta)
	_update_companion_and_sprite(delta)
	_check_floating_stone_observation()
	_check_interactables()
	_update_enemies(delta)
	_update_effects(delta)
	queue_redraw()


func _update_timers(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
	if spell_cooldown > 0.0:
		spell_cooldown -= delta
	if dodge_timer > 0.0:
		dodge_timer -= delta
	if dodge_cooldown > 0.0:
		dodge_cooldown -= delta
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if shield_timer > 0.0:
		shield_timer -= delta
	if companion_thought_timer > 0.0:
		companion_thought_timer -= delta
		if companion_thought_timer <= 0.0:
			companion_thought = ""

	if int(time_sec * 10.0) % 15 == 0 and GameManager.player_mana < GameManager.player_max_mana:
		GameManager.modify_mana(1)


func _handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		player_facing = input_dir
		walk_cycle += delta * 10.5
	else:
		walk_cycle = 0.0

	var move_speed := 255.0
	if dodge_timer > 0.0:
		move_speed = 520.0
		input_dir = player_facing

	var next_pos := player_pos + input_dir * move_speed * delta
	next_pos.x = clampf(next_pos.x, 230.0, 2380.0)
	next_pos.y = clampf(next_pos.y, 185.0, 1020.0)

	# 1. Isometric Cutaway Walls of the West Academy Study Hall (x < 1180)
	if next_pos.x < 1180.0:
		# Top-left angled cutaway wall boundary: y >= 560 - (x - 230) * 0.62
		var min_y_left := 555.0 - (next_pos.x - 230.0) * 0.62
		# Top-right angled cutaway wall boundary: y >= 245 + (x - 730) * 0.48
		var min_y_right := 245.0 + (next_pos.x - 730.0) * 0.48
		next_pos.y = maxf(next_pos.y, maxf(min_y_left, min_y_right))

		# Bottom-left & bottom-right exterior balustrade boundaries
		var max_y_left := 760.0 + (next_pos.x - 230.0) * 0.62
		var max_y_right := 1030.0 - (next_pos.x - 660.0) * 0.36
		if next_pos.x < 1040.0:
			next_pos.y = minf(next_pos.y, minf(max_y_left, max_y_right))

	# 2. Isometric Chasm Gap between Stone Archway (x = 1180) and East Courtyard (x = 1580)
	if not GameManager.bridge_aligned:
		if next_pos.x > 1180.0 and player_pos.x <= 1185.0:
			next_pos.x = 1180.0
	else:
		if next_pos.x > 1180.0 and next_pos.x < 1580.0:
			next_pos.y = clampf(next_pos.y, 735.0, 845.0)

	# 3. Requirement-Locked Patterned Gate Threshold in East Courtyard (y = 560 when x > 1560)
	if next_pos.x > 1560.0 and next_pos.y < 575.0:
		if not GameManager.gate_opened:
			next_pos.y = 575.0
		elif absf(next_pos.x - 1940.0) > 110.0 and next_pos.y > 515.0:
			next_pos.y = 575.0

	player_pos = next_pos
	GameManager.player_pos = player_pos


func _update_companion_and_sprite(delta: float) -> void:
	var target_comp := player_pos - player_facing * 52.0 + Vector2(28.0, -14.0)
	companion_pos = companion_pos.lerp(target_comp, clampf(delta * 5.5, 0.0, 1.0))

	var orbit := Vector2(cos(time_sec * 2.2) * 32.0, sin(time_sec * 3.1) * 14.0 - 54.0)
	sprite_auri_pos = sprite_auri_pos.lerp(player_pos + orbit, clampf(delta * 6.0, 0.0, 1.0))


func _check_floating_stone_observation() -> void:
	if GameManager.bridge_aligned:
		return
	var changed := false
	for stone in floating_stones:
		if not stone["counted"] and player_pos.distance_to(stone["base_pos"]) < 275.0:
			stone["counted"] = true
			changed = true
	if changed:
		var count := get_counted_stones_total()
		MagicManager.encounters["encounter_floating_stones"]["observed_count"] = count
		AudioManager.play_sigil_place()
		GameManager.update_stone_count_objective(count, 6)
		MagicManager.floating_stones_counted_changed.emit(count, 6)
		spawn_floating_text(player_pos + Vector2(0, -54), "Counted Rock %d/6!" % count, UIThemeHelper.COLOR_CYAN_GLOW)
		if count == 6:
			sprite_message_changed.emit("You counted all 6 floating rocks! Use Count(6) in the spell box or Proving Table [E]!")


func count_all_stones_immediately() -> void:
	for stone in floating_stones:
		stone["counted"] = true
	MagicManager.encounters["encounter_floating_stones"]["observed_count"] = 6
	GameManager.update_stone_count_objective(6, 6)
	MagicManager.floating_stones_counted_changed.emit(6, 6)


func get_counted_stones_total() -> int:
	var c := 0
	for s in floating_stones:
		if s["counted"]:
			c += 1
	return c


func _check_interactables() -> void:
	var nearest_id := ""
	var nearest_prompt := ""
	var best_dist := 99999.0

	for item in interactables:
		var d := player_pos.distance_to(item["pos"])
		if d <= float(item["radius"]) and d < best_dist:
			best_dist = d
			nearest_id = item["id"]
			nearest_prompt = item["prompt"]

	if nearest_id == "encounter_floating_stones" and GameManager.bridge_aligned:
		nearest_prompt = "[E] Review Floating Stones Bridge at Proving Table"
	elif nearest_id == "gate_patterned" and GameManager.gate_opened:
		nearest_prompt = "[E] Inspect Unsealed Patterned Gate (64)"

	if nearest_id != current_interactable_id:
		current_interactable_id = nearest_id
		interact_prompt_changed.emit(nearest_prompt)


func trigger_interact() -> void:
	if current_interactable_id.is_empty():
		return
	AudioManager.play_ui_click()
	match current_interactable_id:
		"npc_oron":
			BookManager.unlock_archive_entry("people_oron")
			open_dialogue_requested.emit("npc_oron")
		"station_chalkboard":
			BookManager.unlock_archive_entry("words_geometric")
			open_chalkboard_requested.emit()
		"encounter_floating_stones":
			count_all_stones_immediately()
			open_proving_table_requested.emit("encounter_floating_stones")
		"obelisk_inscription":
			BookManager.unlock_archive_entry("documents_inscription")
			BookManager.unlock_archive_entry("words_geometric")
			spawn_floating_text(player_pos + Vector2(0, -48), "Archive Updated: Inscription of Rhythms!", UIThemeHelper.COLOR_GOLD_BRIGHT)
			open_digital_book_requested.emit("ARCHIVE")
		"gate_patterned":
			if not GameManager.bridge_aligned:
				spawn_floating_text(player_pos + Vector2(0, -48), "Requirement Locked: Align the Floating Path first!", UIThemeHelper.COLOR_DANGER)
				return
			open_proving_table_requested.emit("encounter_patterned_gate")
		"grand_archive_portal":
			if GameManager.warden_defeated:
				prototype_victory_triggered.emit()
			else:
				spawn_floating_text(player_pos + Vector2(0, -48), "Requirement Locked: Overcome the Sequence Warden Elite first!", UIThemeHelper.COLOR_DANGER)


func trigger_basic_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.32
	attack_anim_timer = 0.22
	AudioManager.play_attack()

	var hit_center := player_pos + player_facing * 54.0
	active_waves.append({
		"pos": hit_center,
		"radius": 14.0,
		"max_radius": 58.0,
		"color": UIThemeHelper.COLOR_CYAN_GLOW,
		"life": 0.2
	})

	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if enemy["pos"].distance_to(hit_center) <= 82.0:
			var dmg := 30 if enemy["vulnerable"] else 20
			_damage_enemy(enemy, dmg, "Resonant Strike")


func trigger_equipped_spell() -> void:
	if spell_cooldown > 0.0:
		return
	var spell := CodexManager.get_equipped_spell()
	var cost := int(spell.get("mana_cost", 15))
	if GameManager.player_mana < cost:
		AudioManager.play_error()
		spawn_floating_text(player_pos + Vector2(0, -48), "Low Resonance Energy!", UIThemeHelper.COLOR_DANGER)
		return

	GameManager.modify_mana(-cost)
	spell_cooldown = 0.8
	AudioManager.play_spell_cast()

	var spell_id: String = spell["id"]
	var spell_col: Color = spell.get("icon_color", UIThemeHelper.COLOR_CYAN_GLOW)
	spawn_floating_text(player_pos + Vector2(0, -56), "%s!" % spell["name"], spell_col)

	match spell_id:
		"spell_stone_shield":
			shield_timer = 5.0
			active_waves.append({"pos": player_pos, "radius": 20.0, "max_radius": 72.0, "color": spell_col, "life": 0.4})
		"spell_growth_pulse":
			GameManager.modify_hp(35)
			spawn_floating_text(player_pos + Vector2(0, -38), "+35 HP", UIThemeHelper.COLOR_SUCCESS)
			active_waves.append({"pos": player_pos, "radius": 18.0, "max_radius": 96.0, "color": spell_col, "life": 0.45})
		"spell_harmonic_bridge":
			if not GameManager.bridge_aligned and player_pos.distance_to(Vector2(1155.0, 790.0)) < 310.0:
				GameManager.mark_bridge_aligned()
			active_waves.append({"pos": player_pos, "radius": 22.0, "max_radius": 135.0, "color": spell_col, "life": 0.4})
		_:
			var dmg := maxi(25, int(spell.get("damage", 35)))
			active_waves.append({"pos": player_pos, "radius": 22.0, "max_radius": 165.0, "color": spell_col, "life": 0.42})
			for enemy in enemies:
				if enemy["hp"] <= 0:
					continue
				if enemy["pos"].distance_to(player_pos) <= 185.0:
					enemy["vulnerable"] = true
					_damage_enemy(enemy, dmg, spell["name"])


func trigger_dodge() -> void:
	if dodge_cooldown > 0.0:
		return
	dodge_timer = 0.18
	invuln_timer = 0.35
	dodge_cooldown = 0.65
	AudioManager.play_ui_click()
	active_waves.append({"pos": player_pos, "radius": 10.0, "max_radius": 42.0, "color": Color.WHITE, "life": 0.2})


func _damage_enemy(enemy: Dictionary, amount: int, label: String) -> void:
	enemy["hp"] = maxi(0, int(enemy["hp"]) - amount)
	enemy["hit_flash"] = 0.2
	if GameManager.settings.get("screen_shake", true):
		screen_shake = 5.0
	spawn_floating_text(enemy["pos"] + Vector2(0, -44), "-%d (%s)" % [amount, label], UIThemeHelper.COLOR_GOLD_BRIGHT)

	if enemy["hp"] <= 0:
		AudioManager.play_puzzle_success()
		spawn_floating_text(enemy["pos"] + Vector2(0, -62), "%s Calmed!" % enemy["name"], UIThemeHelper.COLOR_SUCCESS)
		_check_enemy_progression(enemy)


func _check_enemy_progression(defeated_enemy: Dictionary) -> void:
	if defeated_enemy["type"] == "PATTERN_WISP":
		var all_wisps_done := true
		for e in enemies:
			if e["type"] == "PATTERN_WISP" and e["hp"] > 0:
				all_wisps_done = false
		if all_wisps_done:
			GameManager.wisps_defeated = true
			if GameManager.gate_opened:
				GameManager.advance_quest_stage("DEFEAT_WARDEN")
			sprite_message_changed.emit("The Pattern Wisps are calm! Now we can face the Sequence Warden in the Northern Sanctum!")
	elif defeated_enemy["type"] == "SEQUENCE_WARDEN":
		GameManager.warden_defeated = true
		GameManager.player_level = 7
		BookManager.unlock_chapter("chronicle_ch4")
		BookManager.unlock_archive_entry("people_warden")
		BookManager.unlock_archive_entry("places_sanctum")
		BookManager.unlock_archive_entry("documents_creator_mystery")
		CodexManager.unlock_spell("spell_gravity_push")
		CodexManager.unlock_spell("spell_celestial_map")
		GameManager.advance_quest_stage("REPORT_TO_CARETAKER")
		sprite_message_changed.emit("Incredible! You overcame the Sequence Warden Elite and unlocked new Codex Spells!")


func _update_enemies(delta: float) -> void:
	var relaxed := bool(GameManager.settings.get("relaxed_mode", false))
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if enemy["hit_flash"] > 0.0:
			enemy["hit_flash"] -= delta

		if enemy["type"] == "SEQUENCE_WARDEN" and player_pos.y > 575.0:
			continue
		if enemy["type"] == "PATTERN_WISP" and player_pos.x < 1540.0:
			continue

		enemy["timer"] += delta
		match enemy["state"]:
			"PATROL":
				enemy["vulnerable"] = false
				var offset := Vector2(cos(time_sec * 1.6 + float(enemy["pos"].x)), sin(time_sec * 2.0) * 0.5) * 54.0
				var target: Vector2 = enemy["home"] + offset
				enemy["pos"] = enemy["pos"].lerp(target, clampf(delta * 2.0, 0.0, 1.0))
				if enemy["timer"] >= (2.6 if relaxed else 1.9) and enemy["pos"].distance_to(player_pos) < 330.0:
					enemy["state"] = "TELEGRAPH"
					enemy["timer"] = 0.0
					enemy["telegraph_pos"] = player_pos
			"TELEGRAPH":
				var tele_duration := 1.45 if relaxed else 1.05
				if enemy["timer"] >= tele_duration:
					enemy["state"] = "ATTACK"
					enemy["timer"] = 0.0
					_execute_enemy_strike(enemy)
			"ATTACK":
				if enemy["timer"] >= 0.3:
					enemy["state"] = "RECOVERY"
					enemy["timer"] = 0.0
					enemy["vulnerable"] = true
			"RECOVERY":
				if enemy["timer"] >= (2.4 if relaxed else 1.75):
					enemy["state"] = "PATROL"
					enemy["timer"] = 0.0
					enemy["vulnerable"] = false


func _execute_enemy_strike(enemy: Dictionary) -> void:
	var t_pos: Vector2 = enemy["telegraph_pos"]
	var t_rad: float = float(enemy["telegraph_radius"])
	active_waves.append({
		"pos": t_pos,
		"radius": 12.0,
		"max_radius": t_rad,
		"color": UIThemeHelper.COLOR_DANGER,
		"life": 0.35
	})
	if player_pos.distance_to(t_pos) <= t_rad and invuln_timer <= 0.0:
		if shield_timer > 0.0:
			spawn_floating_text(player_pos + Vector2(0, -44), "Blocked by Stone Shield!", UIThemeHelper.COLOR_CYAN_GLOW)
			return
		var dmg := 10 if bool(GameManager.settings.get("relaxed_mode", false)) else 18
		if enemy["type"] == "SEQUENCE_WARDEN":
			dmg += 6
		invuln_timer = 0.8
		GameManager.modify_hp(-dmg)
		AudioManager.play_error()
		spawn_floating_text(player_pos + Vector2(0, -44), "-%d HP" % dmg, UIThemeHelper.COLOR_DANGER)
		if GameManager.player_hp <= 0:
			player_defeated.emit()


func _update_effects(delta: float) -> void:
	for i in range(active_waves.size() - 1, -1, -1):
		var w: Dictionary = active_waves[i]
		w["life"] -= delta
		w["radius"] = lerpf(float(w["radius"]), float(w["max_radius"]), clampf(delta * 10.0, 0.0, 1.0))
		if w["life"] <= 0.0:
			active_waves.remove_at(i)

	for i in range(floating_texts.size() - 1, -1, -1):
		var ft: Dictionary = floating_texts[i]
		ft["life"] -= delta
		ft["pos"] += Vector2(0, -30.0 * delta)
		if ft["life"] <= 0.0:
			floating_texts.remove_at(i)


func spawn_floating_text(pos: Vector2, text: String, col: Color) -> void:
	floating_texts.append({
		"pos": pos,
		"text": text,
		"color": col,
		"life": 1.35
	})


func _on_bridge_aligned() -> void:
	for stone in floating_stones:
		stone["counted"] = true
	spawn_floating_text(Vector2(1380.0, 740.0), "Floating Stones Aligned into an Isometric Bridge!", UIThemeHelper.COLOR_SUCCESS)
	sprite_message_changed.emit("Wonderful! Your Count(6) expression aligned the stones! Cross the bridge to the East Courtyard!")


func _on_gate_unsealed() -> void:
	spawn_floating_text(Vector2(1940.0, 510.0), "Requirement Gate Unsealed (64)!", UIThemeHelper.COLOR_GOLD_BRIGHT)
	sprite_message_changed.emit("The Patterned Gate is open! Enter the Sequence Sanctum in the north!")


# ==============================================================================
# MAIN WORLD RENDERER (1:1 Isometric Pixel-Art Academy Room + East Courtyard)
# ==============================================================================
func _draw() -> void:
	var font := ThemeDB.fallback_font

	# 1. Matching Starry Night & Twilight Clouds Backdrop (Exact palette of 3rd image corners: #232034 / #36334d)
	draw_rect(Rect2(-400, -400, WORLD_W + 800, WORLD_H + 800), Color("232034"))
	for i in range(36):
		var sx := fmod(float(i * 211 + 45), WORLD_W)
		var sy := fmod(float(i * 149 + 30), WORLD_H)
		draw_circle(Vector2(sx, sy), 2.0, Color(0.95, 0.90, 0.80, 0.35 + 0.25 * sin(time_sec * 2.0 + float(i))))
	for c_i in range(14):
		var cpos := Vector2(100.0 + float(c_i * 210), 140.0 + float((c_i % 4) * 340))
		draw_circle(cpos, 110.0, Color("2e2b44"))
		draw_circle(cpos + Vector2(42, 16), 84.0, Color("3c3856"))

	# 2. Render the 2.5D Isometric Magical Academy Room Texture (`magical_academy_room.jpg` — Exact 3rd Image!)
	if _room_tex != null:
		draw_texture_rect(_room_tex, ROOM_RECT, false)

	# Subtle animated magical glow & rising steam over the Cauldron and Scholastic Workbench inside the room
	var cauldron_glow := Vector2(808.0, 360.0)
	draw_circle(cauldron_glow, 42.0, Color(1.0, 0.72, 0.18, 0.14 + 0.06 * sin(time_sec * 5.0)))
	for p in range(3):
		var py := fmod(time_sec * 20.0 + float(p) * 14.0, 40.0)
		var alpha := (1.0 - py / 40.0) * 0.42
		draw_circle(Vector2(808.0 + sin(time_sec * 2.5 + float(p)) * 9.0, 315.0 - py), 6.5 + py * 0.15, Color(1, 1, 1, alpha))

	# Interactive highlight ring on the Scholastic Workbench & Stone Archway Chasm Threshold
	_draw_iso_ellipse_ring(Vector2(615.0, 625.0), 36.0, 18.0, Color(0.98, 0.85, 0.25, 0.45 + 0.25 * sin(time_sec * 3.5)), 2.2)
	draw_string(font, Vector2(540.0, 585.0), "[E] Scholastic Slate", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIThemeHelper.COLOR_GOLD_BRIGHT)

	# 3. ISOMETRIC CHASM & 6 FLOATING STONES (Outside the bottom-right Stone Archway: x = 1200..1580)
	_draw_east_chasm_and_floating_stones(font)

	# 4. ISOMETRIC EAST COURTYARD, PATTERNED GATE & SEQUENCE SANCTUM (x = 1580..2400)
	_draw_east_isometric_courtyard_and_sanctum(font)

	# 5. Y-SORTED PIXEL-STYLIZED ISOMETRIC CHARACTERS (Samantha, Miguel, Caretaker Oron) & ENEMIES
	var render_queue: Array[Dictionary] = []

	# Caretaker Oron standing on the Checkered Foyer Red Carpet (Vector2(825, 865))
	render_queue.append({"y": 865.0, "type": "NPC_ORON", "pos": Vector2(825.0, 865.0)})
	render_queue.append({"y": companion_pos.y, "type": "COMPANION", "pos": companion_pos})
	render_queue.append({"y": player_pos.y, "type": "PLAYER", "pos": player_pos})

	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			render_queue.append({"y": float(enemy["pos"].y), "type": "ENEMY", "enemy": enemy})

	render_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["y"]) < float(b["y"])
	)

	for item in render_queue:
		match String(item["type"]):
			"NPC_ORON":
				_draw_witchbrook_iso_character(
					item["pos"],
					"Caretaker Oron",
					Color("1e3a5f"),
					Color("fde047"),
					Color("4c1d95"),
					Color("a3e635"),
					true,
					0.0,
					false,
					font
				)
			"COMPANION":
				var comp_p := GameManager.get_companion_profile()
				var is_sam := (String(comp_p["id"]) == "SAMANTHA")
				_draw_witchbrook_iso_character(
					item["pos"],
					String(comp_p["name"]).split(" ")[0],
					Color("1d4ed8") if is_sam else Color("b45309"),
					Color("38bdf8") if is_sam else Color("fbbf24"),
					Color("312e81") if is_sam else Color("4c1d95"),
					Color("e2e8f0") if is_sam else Color("78350f"),
					true,
					walk_cycle * 0.85,
					false,
					font
				)
			"PLAYER":
				var lead_p := GameManager.get_active_profile()
				var is_sam := (String(lead_p["id"]) == "SAMANTHA")
				_draw_witchbrook_iso_character(
					item["pos"],
					String(lead_p["name"]).split(" ")[0],
					Color("1d4ed8") if is_sam else Color("b91c1c"),
					Color("38bdf8") if is_sam else Color("fbbf24"),
					Color("312e81") if is_sam else Color("3b215d"),
					Color("e2e8f0") if is_sam else Color("78350f"),
					true,
					walk_cycle,
					true,
					font
				)
			"ENEMY":
				_draw_iso_enemy(item["enemy"], font)

	# 6. Floating Magic Sprite Auri & Active Spell Waves
	_draw_iso_sprite_auri(sprite_auri_pos)

	for w in active_waves:
		var c: Color = w["color"]
		var r: float = float(w["radius"])
		var alpha := clampf(float(w["life"]) * 2.5, 0.0, 1.0)
		_draw_iso_ellipse_ring(w["pos"], r, r * 0.5, Color(c.r, c.g, c.b, alpha), 3.5)

	for ft in floating_texts:
		draw_string(font, ft["pos"] + Vector2(1, 1), String(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(0, 0, 0, 0.85))
		draw_string(font, ft["pos"], String(ft["text"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, ft["color"])


# ------------------------------------------------------------------------------
# EAST ISOMETRIC CHASM, 6 FLOATING STONES & COURTYARD (Warm Witchbrook Palette)
# ------------------------------------------------------------------------------
func _draw_east_chasm_and_floating_stones(font: Font) -> void:
	# Stone Ledge extending from the bottom-right Stone Archway (x: 1120..1210, y: 720..860)
	_draw_iso_prism_screen(Vector2(1165.0, 815.0), 54.0, 32.0, 28.0, Color("d8d3c3"), Color("6e6878"), Color("4a4556"))
	draw_string(font, Vector2(1070.0, 725.0), "[E] Floating Path Chasm", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIThemeHelper.COLOR_CYAN_GLOW)

	# 6 3D Isometric Floating Stones with Warm Pixel-Art Stone Outlines
	for i in range(floating_stones.size()):
		var stone: Dictionary = floating_stones[i]
		var bob := Vector2(0, sin(time_sec * 2.8 + float(i)) * 7.0)
		var pos: Vector2 = stone["bridge_pos"] if GameManager.bridge_aligned else (stone["base_pos"] + bob)
		var glow_col := UIThemeHelper.COLOR_SUCCESS if GameManager.bridge_aligned else (UIThemeHelper.COLOR_CYAN_GLOW if stone["counted"] else Color("60a5fa"))

		_draw_iso_ellipse_filled(pos + Vector2(0, 28), 28.0, 14.0, Color(0, 0, 0, 0.42))
		_draw_iso_prism_screen(
			pos + Vector2(0, 12),
			30.0,
			17.0,
			22.0,
			Color("d6d1c2") if stone["counted"] else Color("8b8596"),
			Color("635d70"),
			Color("433e4f")
		)
		_draw_iso_ellipse_ring(pos + Vector2(0, -10), 20.0, 10.0, glow_col, 2.4)
		draw_string(font, pos + Vector2(-5, -5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color.WHITE)


func _draw_east_isometric_courtyard_and_sanctum(font: Font) -> void:
	# East Isometric Checkered Courtyard Platform (x: 1580..2360, y: 560..980)
	var c_top := Vector2(1960.0, 540.0)
	var c_right := Vector2(2380.0, 750.0)
	var c_bot := Vector2(1960.0, 960.0)
	var c_left := Vector2(1540.0, 750.0)

	# 3D Stone Cliff Skirt
	draw_colored_polygon(PackedVector2Array([c_left, c_bot, c_bot + Vector2(0, 48), c_left + Vector2(0, 48)]), Color("5c566b"))
	draw_colored_polygon(PackedVector2Array([c_bot, c_right, c_right + Vector2(0, 48), c_bot + Vector2(0, 48)]), Color("3e394a"))
	draw_colored_polygon(PackedVector2Array([c_top, c_right, c_bot, c_left]), Color("dfd9c8"))

	# Isometric Checkered Diamond Tiles matching the West Foyer
	for u_i in range(8):
		for v_i in range(8):
			var u0 := float(u_i) / 8.0
			var u1 := float(u_i + 1) / 8.0
			var v0 := float(v_i) / 8.0
			var v1 := float(v_i + 1) / 8.0
			var p00 := c_top + (c_right - c_top) * u0 + (c_left - c_top) * v0
			var p10 := c_top + (c_right - c_top) * u1 + (c_left - c_top) * v0
			var p11 := c_top + (c_right - c_top) * u1 + (c_left - c_top) * v1
			var p01 := c_top + (c_right - c_top) * u0 + (c_left - c_top) * v1
			var col := Color("e2ddd0") if ((u_i + v_i) % 2 == 0) else Color("98aab8")
			draw_colored_polygon(PackedVector2Array([p00, p10, p11, p01]), col)

	# Crimson & Gold Isometric Runner Rug across East Courtyard
	draw_colored_polygon(PackedVector2Array([
		Vector2(1890, 600), Vector2(2010, 600), Vector2(1960, 880), Vector2(1840, 880)
	]), Color("8c242e"))

	# Inscription Obelisk (Vector2(1740, 720))
	_draw_iso_prism_screen(Vector2(1740.0, 720.0), 24.0, 14.0, 68.0, Color("cbd5e1"), Color("64748b"), Color("334155"))
	draw_circle(Vector2(1740.0, 642.0), 9.0, UIThemeHelper.COLOR_CYAN_GLOW)
	draw_string(font, Vector2(1685.0, 624.0), "Inscription Obelisk", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIThemeHelper.COLOR_CYAN_GLOW)

	# Northern Sequence Sanctum Platform (x: 1620..2280, y: 170..540)
	var s_top := Vector2(1940.0, 160.0)
	var s_right := Vector2(2280.0, 350.0)
	var s_bot := Vector2(1940.0, 540.0)
	var s_left := Vector2(1600.0, 350.0)
	draw_colored_polygon(PackedVector2Array([s_top, s_right, s_bot, s_left]), Color("252238"))
	draw_polyline(PackedVector2Array([s_top, s_right, s_bot, s_left, s_top]), Color("9a6b3e"), 4.0)

	# Requirement-Locked Patterned Gate Pillars along y = 555
	var seq_vals: Array[String] = ["4", "8", "16", "32", "64" if GameManager.gate_opened else "?"]
	var px_list: Array[float] = [1720.0, 1810.0, 1880.0, 2000.0, 2090.0]
	for p_i in range(5):
		var px: float = px_list[p_i]
		var solved := (p_i < 4) or GameManager.gate_opened
		var orb_col := Color("fde047") if solved else Color("f43f5e")
		_draw_iso_prism_screen(Vector2(px, 565.0), 18.0, 10.0, 64.0, Color("cbd5e1"), Color("64748b"), Color("334155"))
		draw_circle(Vector2(px, 492.0), 8.5, orb_col)
		draw_string(font, Vector2(px - 10.0, 476.0), seq_vals[p_i], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, orb_col)

	if not GameManager.gate_opened:
		draw_colored_polygon(PackedVector2Array([
			Vector2(1890, 560), Vector2(1990, 560), Vector2(1990, 495), Vector2(1890, 495)
		]), Color(0.88, 0.22, 0.28, 0.50))
		draw_string(font, Vector2(1810.0, 455.0), "REQUIREMENT GATE [4 · 8 · 16 · 32 · ?]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIThemeHelper.COLOR_GOLD_BRIGHT)
	else:
		draw_string(font, Vector2(1830.0, 455.0), "GATE UNSEALED (Ratio ×2 = 64)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIThemeHelper.COLOR_SUCCESS)

	# Grand Archive Portal at Northern Sanctum Apex (Vector2(1940, 220))
	var p_col := UIThemeHelper.COLOR_GOLD_BRIGHT if GameManager.warden_defeated else UIThemeHelper.COLOR_CYAN_GLOW
	_draw_iso_prism_screen(Vector2(1885.0, 235.0), 16.0, 10.0, 62.0, Color("cbd5e1"), Color("64748b"), Color("334155"))
	_draw_iso_prism_screen(Vector2(1995.0, 235.0), 16.0, 10.0, 62.0, Color("cbd5e1"), Color("64748b"), Color("334155"))
	draw_circle(Vector2(1940.0, 195.0), 28.0, Color(p_col.r, p_col.g, p_col.b, 0.32))
	draw_arc(Vector2(1940.0, 195.0), 30.0, 0, TAU, 28, p_col, 3.5)
	draw_string(font, Vector2(1845.0, 148.0), "GRAND INFINITE ARCHIVE PORTAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, p_col)


# ------------------------------------------------------------------------------
# WITCHBROOK PIXEL-STYLIZED ISOMETRIC CHARACTERS (Matching 3rd Reference Image!)
# ------------------------------------------------------------------------------
func _draw_witchbrook_iso_character(
	pos: Vector2,
	label_text: String,
	jacket_col: Color,
	trim_col: Color,
	hat_col: Color,
	hair_col: Color,
	wears_witch_hat: bool,
	walk_phase: float,
	is_active_player: bool,
	font: Font
) -> void:
	var outline := Color("1e1424")
	var bounce := absf(sin(walk_phase)) * 4.5
	var leg_swing := sin(walk_phase) * 5.5

	# Soft isometric ground shadow
	_draw_iso_ellipse_filled(pos + Vector2(0, 6), 22.0, 11.0, Color(0, 0, 0, 0.38))

	if is_active_player and shield_timer > 0.0:
		_draw_iso_ellipse_ring(pos + Vector2(0, -22), 38.0, 20.0, UIThemeHelper.COLOR_CYAN_GLOW, 3.0)

	# Boots & Trousers with crisp dark pixel-art outline
	draw_rect(Rect2(pos.x - 10, pos.y - 16 + leg_swing * 0.5, 8, 17), outline)
	draw_rect(Rect2(pos.x - 9, pos.y - 15 + leg_swing * 0.5, 6, 15), Color("334155"))
	draw_rect(Rect2(pos.x + 2, pos.y - 16 - leg_swing * 0.5, 8, 17), outline)
	draw_rect(Rect2(pos.x + 3, pos.y - 15 - leg_swing * 0.5, 6, 15), Color("334155"))

	# Academy Jacket / Skirt Torso with Dark Outline
	var body_top := pos.y - 42.0 - bounce
	var outer_body := PackedVector2Array([
		Vector2(pos.x - 15, body_top - 2),
		Vector2(pos.x + 15, body_top - 2),
		Vector2(pos.x + 19, pos.y - 11 - bounce),
		Vector2(pos.x - 19, pos.y - 11 - bounce)
	])
	draw_colored_polygon(outer_body, outline)

	var inner_body := PackedVector2Array([
		Vector2(pos.x - 13, body_top),
		Vector2(pos.x + 13, body_top),
		Vector2(pos.x + 16, pos.y - 13 - bounce),
		Vector2(pos.x - 16, pos.y - 13 - bounce)
	])
	draw_colored_polygon(inner_body, jacket_col)
	# Inner white shirt & collar tie
	draw_rect(Rect2(pos.x - 4, body_top, 8, 16), Color("f8fafc"))
	draw_line(Vector2(pos.x, body_top + 2), Vector2(pos.x, body_top + 18), trim_col, 3.0)

	# Head & Hair with Dark Outline
	var head_c := Vector2(pos.x, body_top - 13.0)
	draw_circle(head_c, 15.5, outline)
	draw_circle(head_c, 13.5, Color("f7d6bd"))
	# Side hair locks
	draw_circle(head_c + Vector2(-11, -2), 6.0, hair_col)
	draw_circle(head_c + Vector2(11, -2), 6.0, hair_col)
	draw_arc(head_c + Vector2(0, -3), 12.5, PI * 1.1, PI * 1.9, 12, hair_col, 5.0)

	# Crisp vertical pixel-art eyes (Matches 3rd reference image characters!)
	var eye_x := clampf(player_facing.x * 3.0, -3.0, 3.0) if is_active_player else 0.0
	draw_rect(Rect2(head_c.x - 5.5 + eye_x, head_c.y - 1.0, 2.8, 5.5), outline)
	draw_rect(Rect2(head_c.x + 2.8 + eye_x, head_c.y - 1.0, 2.8, 5.5), outline)

	# Iconic Oversized Curved Witch / Scholar Hat (Exact match to the hats in the 3rd reference image!)
	if wears_witch_hat:
		var brim_c := head_c + Vector2(0, -10)
		_draw_iso_ellipse_filled(brim_c, 26.0, 10.5, outline)
		_draw_iso_ellipse_filled(brim_c, 24.0, 8.8, hat_col)
		var cone_outer := PackedVector2Array([
			brim_c + Vector2(-15, -1),
			brim_c + Vector2(15, -1),
			brim_c + Vector2(6, -30)
		])
		draw_colored_polygon(cone_outer, outline)
		var cone_inner := PackedVector2Array([
			brim_c + Vector2(-13, -2),
			brim_c + Vector2(13, -2),
			brim_c + Vector2(5, -27)
		])
		draw_colored_polygon(cone_inner, hat_col.lightened(0.15))
		draw_line(brim_c + Vector2(-12, -2), brim_c + Vector2(12, -2), trim_col, 3.0)

	# Nameplate badge above character
	var name_y := head_c.y - (45.0 if wears_witch_hat else 24.0)
	draw_string(font, Vector2(pos.x - 55 + 1, name_y + 1), label_text, HORIZONTAL_ALIGNMENT_CENTER, 110.0, 13, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(pos.x - 55, name_y), label_text, HORIZONTAL_ALIGNMENT_CENTER, 110.0, 13, trim_col if is_active_player else Color.WHITE)


func _draw_iso_sprite_auri(pos: Vector2) -> void:
	_draw_iso_ellipse_filled(pos + Vector2(0, 44), 11.0, 5.5, Color(0.22, 0.74, 0.97, 0.22))
	draw_circle(pos, 15.0, Color(0.22, 0.82, 0.98, 0.32))
	var diamond := PackedVector2Array([
		pos + Vector2(0, -13),
		pos + Vector2(9, 0),
		pos + Vector2(0, 13),
		pos + Vector2(-9, 0)
	])
	draw_colored_polygon(diamond, UIThemeHelper.COLOR_CYAN_GLOW)
	draw_arc(pos, 14.0, 0.2, PI - 0.2, 12, UIThemeHelper.COLOR_GOLD_BRIGHT, 1.8)


func _draw_iso_enemy(enemy: Dictionary, font: Font) -> void:
	var epos: Vector2 = enemy["pos"]
	if enemy["state"] == "TELEGRAPH":
		var tpos: Vector2 = enemy["telegraph_pos"]
		var trad: float = float(enemy["telegraph_radius"])
		_draw_iso_ellipse_filled(tpos, trad, trad * 0.5, Color(0.95, 0.24, 0.36, 0.22))
		_draw_iso_ellipse_ring(tpos, trad, trad * 0.5, UIThemeHelper.COLOR_DANGER, 2.5)

	var is_warden := (String(enemy["type"]) == "SEQUENCE_WARDEN")
	var body_col := Color.WHITE if float(enemy["hit_flash"]) > 0.0 else (Color("22c55e") if bool(enemy["vulnerable"]) else (Color("f43f5e") if is_warden else Color("a855f7")))

	_draw_iso_ellipse_filled(epos + Vector2(0, 12), 28.0 if is_warden else 18.0, 14.0 if is_warden else 9.0, Color(0, 0, 0, 0.35))
	var bob := sin(time_sec * 3.5) * 6.0
	var h := 54.0 if is_warden else 30.0
	_draw_iso_prism_screen(epos + Vector2(0, bob), 24.0 if is_warden else 16.0, 13.0 if is_warden else 9.0, h, body_col.lightened(0.2), body_col, body_col.darkened(0.25))

	var hp_pct := float(enemy["hp"]) / float(enemy["max_hp"])
	var bar_y := epos.y - h - 26.0
	draw_rect(Rect2(epos.x - 30, bar_y, 60, 6), Color("0f172a"))
	draw_rect(Rect2(epos.x - 30, bar_y, 60.0 * hp_pct, 6), UIThemeHelper.COLOR_HP_RED)
	var status_tag := " [VULNERABLE!]" if bool(enemy["vulnerable"]) else ""
	draw_string(font, Vector2(epos.x - 65, bar_y - 6), String(enemy["name"]) + status_tag, HORIZONTAL_ALIGNMENT_CENTER, 130.0, 12, Color.WHITE)


func _draw_iso_prism_screen(base_center: Vector2, half_w: float, half_d: float, height: float, top_col: Color, left_col: Color, right_col: Color) -> void:
	var top_c := base_center + Vector2(0, -height)
	var p_north := top_c + Vector2(0, -half_d)
	var p_east := top_c + Vector2(half_w, 0)
	var p_south := top_c + Vector2(0, half_d)
	var p_west := top_c + Vector2(-half_w, 0)

	var b_east := p_east + Vector2(0, height)
	var b_south := p_south + Vector2(0, height)
	var b_west := p_west + Vector2(0, height)

	draw_colored_polygon(PackedVector2Array([p_west, p_south, b_south, b_west]), left_col)
	draw_colored_polygon(PackedVector2Array([p_south, p_east, b_east, b_south]), right_col)
	draw_colored_polygon(PackedVector2Array([p_north, p_east, p_south, p_west]), top_col)


func _draw_iso_ellipse_filled(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var ang := (float(i) / float(steps)) * TAU
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, col)


func _draw_iso_ellipse_ring(center: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var steps := 28
	for i in range(steps + 1):
		var ang := (float(i) / float(steps)) * TAU
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_polyline(pts, col, width)
