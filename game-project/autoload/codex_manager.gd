extends Node
## Stores all acquired and discoverable spells for the Magical Codex UI
## (matching Magical Codex_ Wind Current.png mockup).

signal spell_unlocked(spell_id: String)
signal equipped_spell_changed(spell_id: String)
signal cast_preview_requested(spell_id: String)

var equipped_spell_id: String = "spell_wind_current"

# Total planned spells in Book I Codex = 24 (12 shown in grid: 6 unlocked/discoverable in slice, 6 locked higher-tier)
var spells: Dictionary = {
	"spell_wind_current": {
		"id": "spell_wind_current",
		"name": "Wind Current",
		"level": 1,
		"category": "Utility",
		"tags": ["Movement", "Utility", "Environment"],
		"rarity": "Common",
		"description": "Creates a directional wind current that pushes lightweight objects, disperses hazards, and can carry the player across short distances.",
		"command_syntax": "push(wind, direction, magnitude)",
		"required_sigils": [
			{"name": "Wind Sigil", "symbol": "(W)", "color": Color("38bdf8")},
			{"name": "Direction Sigil", "symbol": "(→)", "color": Color("38bdf8")},
			{"name": "Power Sigil", "symbol": "(P)", "color": Color("38bdf8")}
		],
		"mana_cost": 15,
		"cooldown": "8s",
		"range": "Medium",
		"duration": "6s",
		"damage": 25,
		"unlocked": true,
		"icon_color": Color("38bdf8"),
		"envision": {
			"intent": "Channel a localized directional breeze along a chosen vector",
			"target_effect": "Push targets back, clear mist, or propel across gaps",
			"conceptual_shape": "Directed Linear Vector v = magnitude · [cos(θ), sin(θ)]"
		},
		"interpretation": "Zephyr and ambient wind sprites align with the vector direction and magnitude.",
		"response": "Projects a fast wind wave dealing 25 knockback damage and activating wind mechanisms."
	},
	"spell_stone_shield": {
		"id": "spell_stone_shield",
		"name": "Stone Shield",
		"level": 1,
		"category": "Defensive",
		"tags": ["Defensive", "Protection", "Earth"],
		"rarity": "Common",
		"description": "Anchored by polygonal symmetry, raises a resonant stone barrier that absorbs incoming projectile damage and stabilizes footing.",
		"command_syntax": "construct(stone, polygon=6, radius=48)",
		"required_sigils": [
			{"name": "Count Sigil", "symbol": "✦", "color": Color("fbbf24")},
			{"name": "Equal Sigil", "symbol": "=", "color": Color("38bdf8")}
		],
		"mana_cost": 20,
		"cooldown": "10s",
		"range": "Self",
		"duration": "5s",
		"damage": 0,
		"unlocked": true,
		"icon_color": Color("60a5fa"),
		"envision": {
			"intent": "Form a balanced hexagonal ward of solid stone around the caster",
			"target_effect": "Reduce incoming damage and block enemy telegraphed waves",
			"conceptual_shape": "Regular Hexagon (6 equal sides)"
		},
		"interpretation": "Earth and Stone Sprites interlock along the six symmetric vertices.",
		"response": "Grants a protective crystalline shield that absorbs 40 damage for 5 seconds."
	},
	"spell_light_beacon": {
		"id": "spell_light_beacon",
		"name": "Light Beacon",
		"level": 2,
		"category": "Exploration",
		"tags": ["Exploration", "Reveal", "Light"],
		"rarity": "Rare",
		"description": "Projects a radiant star of mathematical clarity that illuminates hidden inscriptions, invisible rune sockets, and enemy telegraph ratios.",
		"command_syntax": "illuminate(origin, radius=160, intensity=2)",
		"required_sigils": [
			{"name": "Count Sigil", "symbol": "✦", "color": Color("fbbf24")},
			{"name": "Multiply Sigil", "symbol": "×", "color": Color("fbbf24")}
		],
		"mana_cost": 12,
		"cooldown": "6s",
		"range": "Wide",
		"duration": "8s",
		"damage": 15,
		"unlocked": true,
		"icon_color": Color("fbbf24"),
		"envision": {
			"intent": "Expand a sphere of luminous clarity to reveal concealed patterns",
			"target_effect": "Highlight environmental clues and stun shadow/wisp entities",
			"conceptual_shape": "Radial Locus x² + y² ≤ r²"
		},
		"interpretation": "Light Sprites amplify visibility across the specified radial distance.",
		"response": "Reveals nearby hidden clues and briefly stuns Pattern Wisps in a 160px radius."
	},
	"spell_harmonic_bridge": {
		"id": "spell_harmonic_bridge",
		"name": "Water Bridge",
		"level": 2,
		"category": "Exploration",
		"tags": ["Exploration", "Bridge", "Environment"],
		"rarity": "Rare",
		"description": "Communicates cardinality and spacing to Courtyard & Water Sprites, aligning floating stones or frozen crests into a walkable bridge.",
		"command_syntax": "align(stones, Count(6), interval=equal)",
		"required_sigils": [
			{"name": "Count Sigil", "symbol": "✦", "color": Color("38bdf8")},
			{"name": "Add Sigil", "symbol": "+", "color": Color("fbbf24")}
		],
		"mana_cost": 18,
		"cooldown": "12s",
		"range": "Medium",
		"duration": "Permanent",
		"damage": 0,
		"unlocked": true,
		"icon_color": Color("22d3ee"),
		"envision": {
			"intent": "Arrange scattered floating stones or water crests into a continuous path",
			"target_effect": "Form a safe crossing over chasms or water",
			"conceptual_shape": "Collinear Sequence of N Discrete Stepping Nodes"
		},
		"interpretation": "Auri the Counting Sprite verifies the exact cardinality of stones and locks them into alignment.",
		"response": "Forms a permanent traversable stone/water bridge across the gap."
	},
	"spell_growth_pulse": {
		"id": "spell_growth_pulse",
		"name": "Growth Pulse",
		"level": 2,
		"category": "Utility",
		"tags": ["Recovery", "Nature", "Utility"],
		"rarity": "Rare",
		"description": "Harmonizes with botanical Fibonacci spirals to mend physical fatigue and restore the scholar's vitality.",
		"command_syntax": "restore(vitality, sum=Add(20, 15))",
		"required_sigils": [
			{"name": "Add Sigil", "symbol": "+", "color": Color("4ade80")},
			{"name": "Count Sigil", "symbol": "✦", "color": Color("4ade80")}
		],
		"mana_cost": 25,
		"cooldown": "14s",
		"range": "Self",
		"duration": "Instant",
		"damage": 0,
		"unlocked": true,
		"icon_color": Color("4ade80"),
		"envision": {
			"intent": "Accelerate natural cellular restoration through additive harmony",
			"target_effect": "Restore 35 HP to the active protagonist",
			"conceptual_shape": "Golden Spiral Approximation"
		},
		"interpretation": "Nature Sprites in the Academy grove channel restorative energy.",
		"response": "Heals the player for 35 HP with an emerald botanical burst."
	},
	"spell_fire_burst": {
		"id": "spell_fire_burst",
		"name": "Fire Burst",
		"level": 3,
		"category": "Offensive",
		"tags": ["Offensive", "AoE", "Fire"],
		"rarity": "Epic",
		"description": "Releases a concentrated thermal expansion wave that ignites hostile constructs in a 360-degree ring.",
		"command_syntax": "ignite(radius=110, factor=Multiply(2, 20))",
		"required_sigils": [
			{"name": "Multiply Sigil", "symbol": "×", "color": Color("f97316")},
			{"name": "Greater Sigil", "symbol": ">", "color": Color("f97316")}
		],
		"mana_cost": 22,
		"cooldown": "9s",
		"range": "Close AoE",
		"duration": "Instant",
		"damage": 40,
		"unlocked": true,
		"icon_color": Color("f97316"),
		"envision": {
			"intent": "Discharge a rapid thermal ring around the caster",
			"target_effect": "Deal 40 AoE damage to all nearby enemies",
			"conceptual_shape": "Expanding Thermal Sphere"
		},
		"interpretation": "Thermal Sprites rapidly multiply kinetic agitation within the specified radius.",
		"response": "Deals 40 Fire damage in an expanding ring around the player."
	},
	"spell_ice_prism": {
		"id": "spell_ice_prism",
		"name": "Ice Prism",
		"level": 3,
		"category": "Offensive",
		"tags": ["Offensive", "Ice", "Book I"],
		"rarity": "Epic",
		"description": "Crystallizes ambient Academy frost into a geometric prism lance that pierces enemies and slows their attack cadence.",
		"command_syntax": "project(ice_prism, ratio=2, range=240)",
		"required_sigils": [
			{"name": "Multiply Sigil", "symbol": "×", "color": Color("38bdf8")},
			{"name": "Equal Sigil", "symbol": "=", "color": Color("38bdf8")}
		],
		"mana_cost": 18,
		"cooldown": "5s",
		"range": "Long",
		"duration": "3s Slow",
		"damage": 45,
		"unlocked": true,
		"icon_color": Color("38bdf8"),
		"envision": {
			"intent": "Focus ambient frost into a crystalline geometric beam",
			"target_effect": "Deal 45 Ice damage and chill target movement",
			"conceptual_shape": "Symmetric Hexagonal Prism Lattice"
		},
		"interpretation": "Book I Frost Sprites condense along the doubling vector.",
		"response": "Fires a high-velocity crystalline beam dealing 45 damage."
	},
	"spell_gravity_push": {
		"id": "spell_gravity_push",
		"name": "Gravity Push",
		"level": 3,
		"category": "Offensive",
		"tags": ["Offensive", "Control", "Gravity"],
		"rarity": "Epic",
		"description": "Alters local gravitational mass ratios to repel heavy mechanisms and stagger elite guardians.",
		"command_syntax": "repel(mass, force=Multiply(16, 4))",
		"required_sigils": [
			{"name": "Multiply Sigil", "symbol": "×", "color": Color("c084fc")},
			{"name": "Divide Sigil", "symbol": "÷", "color": Color("c084fc")}
		],
		"mana_cost": 28,
		"cooldown": "12s",
		"range": "Medium",
		"duration": "2s Stun",
		"damage": 35,
		"unlocked": true,
		"icon_color": Color("c084fc"),
		"envision": {
			"intent": "Invert local gravitational attraction along a cone",
			"target_effect": "Repel enemies and expose Elite recovery states",
			"conceptual_shape": "Hyperbolic Field Gradient"
		},
		"interpretation": "Gravity Sprites shift equilibrium proportional to the product of inputs.",
		"response": "Unleashes a purple gravity wave that deals 35 damage and stuns enemies."
	},
	"spell_mirror_step": {
		"id": "spell_mirror_step",
		"name": "Mirror Step",
		"level": 4,
		"category": "Special",
		"tags": ["Movement", "Symmetry", "Special"],
		"rarity": "Legendary",
		"description": "Uses axial reflection across a line of symmetry to instantaneously reposition the caster to the mirrored coordinate.",
		"command_syntax": "reflect(position, axis=Y)",
		"required_sigils": [
			{"name": "Equal Sigil", "symbol": "=", "color": Color("a855f7")},
			{"name": "Subtract Sigil", "symbol": "−", "color": Color("a855f7")}
		],
		"mana_cost": 30,
		"cooldown": "15s",
		"range": "Symmetric",
		"duration": "Instant",
		"damage": 0,
		"unlocked": false,
		"icon_color": Color("a855f7"),
		"envision": {
			"intent": "Reflect coordinates across a chosen geometric axis",
			"target_effect": "Blink across barriers or hazards",
			"conceptual_shape": "Axial Reflection (x, y) -> (-x, y)"
		},
		"interpretation": "Requires advanced Geometric Symmetry mastery.",
		"response": "Teleports the player to the reflected coordinate."
	},
	"spell_time_knot": {
		"id": "spell_time_knot",
		"name": "Time Knot",
		"level": 4,
		"category": "Special",
		"tags": ["Control", "Sequence", "Special"],
		"rarity": "Legendary",
		"description": "Loops a short periodic interval, slowing enemy telegraph timers by half within the field.",
		"command_syntax": "dilate(interval, factor=Divide(1, 2))",
		"required_sigils": [
			{"name": "Divide Sigil", "symbol": "÷", "color": Color("fbbf24")}
		],
		"mana_cost": 35,
		"cooldown": "20s",
		"range": "Arena",
		"duration": "6s",
		"damage": 0,
		"unlocked": false,
		"icon_color": Color("fbbf24"),
		"envision": {
			"intent": "Halve the rate of local temporal progression",
			"target_effect": "Slow all enemy movement and telegraphs by 50%",
			"conceptual_shape": "Periodic Sine Modulation"
		},
		"interpretation": "Unlocked in advanced chapters of Book I.",
		"response": "Slows all active enemies for 6 seconds."
	},
	"spell_elemental_link": {
		"id": "spell_elemental_link",
		"name": "Elemental Link",
		"level": 5,
		"category": "Special",
		"tags": ["Combination", "Synergy", "Special"],
		"rarity": "Legendary",
		"description": "Intersects three mathematical sets to combine primary elemental domains into a unified harmonic triad.",
		"command_syntax": "intersect(Set_A, Set_B, Set_C)",
		"required_sigils": [
			{"name": "Add Sigil", "symbol": "+", "color": Color("4ade80")},
			{"name": "Equal Sigil", "symbol": "=", "color": Color("38bdf8")}
		],
		"mana_cost": 40,
		"cooldown": "25s",
		"range": "Wide",
		"duration": "10s",
		"damage": 65,
		"unlocked": false,
		"icon_color": Color("ec4899"),
		"envision": {
			"intent": "Unite overlapping elemental properties through set intersection",
			"target_effect": "Trigger multi-domain resonance",
			"conceptual_shape": "Tri-Circle Venn Intersection A ∩ B ∩ C"
		},
		"interpretation": "Requires Set Theory & Venn Relationships mastery.",
		"response": "Releases a tri-elemental convergence blast."
	},
	"spell_celestial_map": {
		"id": "spell_celestial_map",
		"name": "Celestial Map",
		"level": 5,
		"category": "Exploration",
		"tags": ["Cosmic", "Navigation", "Special"],
		"rarity": "Legendary",
		"description": "Projects a coordinate constellation chart across the sky, revealing all undiscovered Archive records and secret sanctums.",
		"command_syntax": "chart(coordinates, domain=Infinite)",
		"required_sigils": [
			{"name": "Count Sigil", "symbol": "✦", "color": Color("fbbf24")},
			{"name": "Greater Sigil", "symbol": ">", "color": Color("fbbf24")}
		],
		"mana_cost": 50,
		"cooldown": "30s",
		"range": "Global",
		"duration": "12s",
		"damage": 0,
		"unlocked": false,
		"icon_color": Color("fcd34d"),
		"envision": {
			"intent": "Map the angular coordinates of every anomaly in the region",
			"target_effect": "Reveal all hidden paths and lore obelisks",
			"conceptual_shape": "Celestial Polar Grid (r, θ)"
		},
		"interpretation": "Requires Coordinate Geometry mastery.",
		"response": "Illuminates the entire region map and secret thresholds."
	}
}

var spell_order: Array[String] = [
	"spell_wind_current",
	"spell_stone_shield",
	"spell_light_beacon",
	"spell_harmonic_bridge",
	"spell_growth_pulse",
	"spell_fire_burst",
	"spell_ice_prism",
	"spell_gravity_push",
	"spell_mirror_step",
	"spell_time_knot",
	"spell_elemental_link",
	"spell_celestial_map"
]

func get_all_spells() -> Array:
	var list: Array = []
	for id in spell_order:
		if spells.has(id):
			list.append(spells[id])
	return list

func get_unlocked_count() -> int:
	var count := 0
	for id in spells:
		if spells[id]["unlocked"]:
			count += 1
	return count

func unlock_spell(spell_id: String) -> void:
	if spells.has(spell_id) and not spells[spell_id]["unlocked"]:
		spells[spell_id]["unlocked"] = true
		AudioManager.play_archive_unlock()
		spell_unlocked.emit(spell_id)

func equip_spell(spell_id: String) -> void:
	if spells.has(spell_id) and spells[spell_id]["unlocked"]:
		equipped_spell_id = spell_id
		AudioManager.play_ui_click()
		equipped_spell_changed.emit(spell_id)

func get_equipped_spell() -> Dictionary:
	return spells.get(equipped_spell_id, spells["spell_wind_current"])
