extends Node
## Manages Sigils (strict mathematical equivalence), The Proving Table expression builder,
## Magic Sprite interpretation, and the 4-type diagnostic feedback (v0.10.01).

signal sigil_unlocked(sigil_id: String)
signal active_sigil_changed(sigil_id: String)
signal spell_evaluated(result: Dictionary)
signal floating_stones_counted_changed(current_count: int, target_count: int)

enum FailureType {
	NONE,
	MATH_OR_STRUCTURAL,
	SPRITE_CAPABILITY,
	COMMUNICATION_FAILURE,
	ENVIRONMENTAL_LIMITATION
}

# Canonical Sigil Registry (matches Floating Path & Proving Table mockups)
var sigils: Dictionary = {
	"sigil_count": {
		"id": "sigil_count",
		"name": "Count",
		"symbol": "✦",
		"unit_category": "Number",
		"math_meaning": "Cardinality / Determining the exact quantity of a collection.",
		"syntax_prefix": "Count",
		"expected_inputs": 1,
		"unlocked": true,
		"color": Color("38bdf8")
	},
	"sigil_add": {
		"id": "sigil_add",
		"name": "Add",
		"symbol": "+",
		"unit_category": "Operation",
		"math_meaning": "Addition / Combining two or more quantities into a total sum.",
		"syntax_prefix": "Add",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("fbbf24")
	},
	"sigil_subtract": {
		"id": "sigil_subtract",
		"name": "Subtract",
		"symbol": "−",
		"unit_category": "Operation",
		"math_meaning": "Subtraction / Finding the difference or remaining quantity.",
		"syntax_prefix": "Subtract",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("fbbf24")
	},
	"sigil_multiply": {
		"id": "sigil_multiply",
		"name": "Multiply",
		"symbol": "×",
		"unit_category": "Operation",
		"math_meaning": "Multiplication / Scaling a quantity by a constant factor or ratio.",
		"syntax_prefix": "Multiply",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("fbbf24")
	},
	"sigil_divide": {
		"id": "sigil_divide",
		"name": "Divide",
		"symbol": "÷",
		"unit_category": "Operation",
		"math_meaning": "Division / Partitioning a quantity into equal groups or ratios.",
		"syntax_prefix": "Divide",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("fbbf24")
	},
	"sigil_greater": {
		"id": "sigil_greater",
		"name": "Greater Than",
		"symbol": ">",
		"unit_category": "Relation",
		"math_meaning": "Inequality / Verifying the first quantity exceeds the second.",
		"syntax_prefix": "Greater",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("a855f7")
	},
	"sigil_less": {
		"id": "sigil_less",
		"name": "Less Than",
		"symbol": "<",
		"unit_category": "Relation",
		"math_meaning": "Inequality / Verifying the first quantity is smaller than the second.",
		"syntax_prefix": "Less",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("a855f7")
	},
	"sigil_equal": {
		"id": "sigil_equal",
		"name": "Equal",
		"symbol": "=",
		"unit_category": "Relation",
		"math_meaning": "Equivalence / Asserting two mathematical expressions have identical value.",
		"syntax_prefix": "Equal",
		"expected_inputs": 2,
		"unlocked": true,
		"color": Color("38bdf8")
	}
}

var selected_sigil_id: String = "sigil_count"

# Magic Sprites Registry (v0.10.01: living manifestations with affinity, capability, & bond)
var magic_sprites: Dictionary = {
	"sprite_auri": {
		"id": "sprite_auri",
		"name": "Auri, the Courtyard Counting Sprite",
		"domain": "Stone & Spatial Order",
		"max_magnitude": 100,
		"bond_level": 1,
		"environment_affinity": "Academy Courtyard",
		"current_message": "Look at the floating rocks. Count them, then use the counting sigil to cast a spell!"
	},
	"sprite_zephyr": {
		"id": "sprite_zephyr",
		"name": "Zephyr, the Breeze Sprite",
		"domain": "Wind & Vector Motion",
		"max_magnitude": 64,
		"bond_level": 2,
		"environment_affinity": "Elevated Bridges",
		"current_message": "I sense a strong directional current here!"
	}
}

# Modular Encounter Registry (Floating Stones is flagged as a swappable temporary example)
var encounters: Dictionary = {
	"encounter_floating_stones": {
		"id": "encounter_floating_stones",
		"title": "The Floating Path (Temporary Example)",
		"is_temporary_example": true,
		"competency": "Book I — Counting & Cardinality / Basic Operations",
		"sprite_id": "sprite_auri",
		"envision_description": "Make the 6 floating stones move and form a traversable bridge across the courtyard gap.",
		"envision_target": "Floating Stones",
		"envision_action": "Move / Arrange",
		"envision_quantity": 6,
		"observed_count": 0,
		"target_count": 6,
		"solved": false,
		"reward_spell_id": "spell_harmonic_bridge",
		"reward_archive_id": "words_two_table_magic",
		"hint_ladder": [
			"Hint 1 (Observation): Walk near or click the glowing floating stones in the courtyard to count how many exist in the collection.",
			"Hint 2 (Representation): There are 6 floating stones total (3 on the left arc, 3 on the right arc).",
			"Hint 3 (Command): Select the 'Count' sigil with input '6' -> Count(6), or 'Add' with '3' and '3' -> Add(3, 3), then click Submit Command!"
		]
	},
	"encounter_patterned_gate": {
		"id": "encounter_patterned_gate",
		"title": "The Patterned Gate: Harmonic Doubling",
		"is_temporary_example": false,
		"competency": "Book I — Pattern Recognition & Geometric Sequences (r = 2)",
		"sprite_id": "sprite_auri",
		"envision_description": "Restore the fifth harmonic socket of the Great Patterned Gate (4, 8, 16, 32 -> 64) to unseal the forbidden Sequence Sanctum.",
		"envision_target": "Patterned Gate Socket V",
		"envision_action": "Resonate / Unseal",
		"envision_quantity": 64,
		"observed_count": 4,
		"target_count": 4,
		"solved": false,
		"reward_spell_id": "spell_ice_prism",
		"reward_archive_id": "words_geometric",
		"hint_ladder": [
			"Hint 1 (Observation): Look at the numbers in the active gate sockets: 4, 8, 16, 32. Does each step add a fixed number or multiply?",
			"Hint 2 (Relationship): Test the ratio between consecutive terms: 8 ÷ 4 = 2, 16 ÷ 8 = 2, 32 ÷ 16 = 2. Each socket doubles the previous value (×2).",
			"Hint 3 (Guided Step): Multiply the 4th socket (32) by the common ratio (2): 32 × 2 = 64. Use Count(64) or Multiply(32, 2)!"
		]
	}
}

func select_sigil(sigil_id: String) -> void:
	if sigils.has(sigil_id):
		selected_sigil_id = sigil_id
		AudioManager.play_sigil_place()
		active_sigil_changed.emit(sigil_id)

func get_sigil_list() -> Array:
	var list: Array = []
	var order := ["sigil_count", "sigil_add", "sigil_subtract", "sigil_multiply", "sigil_divide", "sigil_greater", "sigil_less", "sigil_equal"]
	for id in order:
		if sigils.has(id):
			list.append(sigils[id])
	return list

func format_expression(sigil_id: String, inputs: Array) -> Dictionary:
	if not sigils.has(sigil_id):
		return {"structure": "Empty()", "display": "—", "meaning": "Select a sigil and input values.", "evaluated_value": null}
	var s: Dictionary = sigils[sigil_id]
	var prefix: String = s["syntax_prefix"]
	var sym: String = s["symbol"]
	if inputs.is_empty():
		return {
			"structure": "%s(?)" % prefix,
			"display": "%s ( ? )" % sym,
			"meaning": s["math_meaning"],
			"evaluated_value": null
		}
	if sigil_id == "sigil_count":
		var v := int(inputs[0])
		return {
			"structure": "Count(%d)" % v,
			"display": "✦ ( %d )" % v,
			"meaning": "Represents a counted collection of %d objects." % v,
			"evaluated_value": v
		}
	if inputs.size() == 1:
		var v1 := int(inputs[0])
		return {
			"structure": "%s(%d, ?)" % [prefix, v1],
			"display": "%d %s ?" % [v1, sym],
			"meaning": "Requires a second mathematical input to complete the %s operation." % s["name"],
			"evaluated_value": null
		}
	var a := int(inputs[0])
	var b := int(inputs[1])
	var result_val: Variant = null
	var explanation := ""
	match sigil_id:
		"sigil_add":
			result_val = a + b
			explanation = "Combines quantities %d and %d into a sum of %d." % [a, b, result_val]
		"sigil_subtract":
			result_val = a - b
			explanation = "Finds the difference between %d and %d (= %d)." % [a, b, result_val]
		"sigil_multiply":
			result_val = a * b
			explanation = "Scales quantity %d by factor %d (= %d)." % [a, b, result_val]
		"sigil_divide":
			if b != 0:
				result_val = int(float(a) / float(b))
				explanation = "Partitions %d into groups of %d (= %d)." % [a, b, result_val]
			else:
				explanation = "Division by zero is undefined in mathematical reality!"
		"sigil_greater":
			result_val = a if a > b else -1
			explanation = "Asserts %d > %d (%s)." % [a, b, "True" if a > b else "False"]
		"sigil_less":
			result_val = a if a < b else -1
			explanation = "Asserts %d < %d (%s)." % [a, b, "True" if a < b else "False"]
		"sigil_equal":
			result_val = a if a == b else -1
			explanation = "Asserts %d = %d (%s)." % [a, b, "True" if a == b else "False"]
	return {
		"structure": "%s(%d, %d)" % [prefix, a, b],
		"display": "%d %s %d = %s" % [a, sym, b, str(result_val) if result_val != null else "Undefined"],
		"meaning": explanation,
		"evaluated_value": result_val
	}

## Evaluates a Two-Table command against an encounter, distinguishing the 4 canonical failure causes (v0.10.01 Section 14)
func evaluate_proving_table_command(encounter_id: String, sigil_id: String, inputs: Array) -> Dictionary:
	var formatted := format_expression(sigil_id, inputs)
	if not encounters.has(encounter_id):
		return {
			"success": false,
			"failure_type": FailureType.COMMUNICATION_FAILURE,
			"title": "No Target Phenomenon",
			"diagnostic": "There is no magical phenomenon connected to the Proving Table right now."
		}
	var enc: Dictionary = encounters[encounter_id]
	var sprite: Dictionary = magic_sprites.get(enc["sprite_id"], {})
	var eval_val: Variant = formatted["evaluated_value"]

	# 1. Structural / Grammatical Failure (Incomplete inputs or division by zero)
	if eval_val == null:
		AudioManager.play_error()
		var res := {
			"success": false,
			"failure_type": FailureType.MATH_OR_STRUCTURAL,
			"title": "Structural Expression Failure",
			"expression": formatted["structure"],
			"diagnostic": "Your mathematical expression (%s) is incomplete or undefined. Ensure all required input slots for the %s sigil are filled." % [formatted["structure"], sigils[sigil_id]["name"]]
		}
		spell_evaluated.emit(res)
		return res

	var num_val := int(eval_val)
	var target_qty := int(enc["envision_quantity"])

	# 2. Sprite Capability Failure (Math expression is valid, but exceeds the Sprite's magnitude limit)
	var max_mag := int(sprite.get("max_magnitude", 100))
	if num_val > max_mag:
		AudioManager.play_error()
		var res := {
			"success": false,
			"failure_type": FailureType.SPRITE_CAPABILITY,
			"title": "Sprite Capability Limitation",
			"expression": formatted["structure"],
			"diagnostic": "Your mathematical expression (%s = %d) is mathematically valid! However, %s can only influence quantities up to %d. Reality constrains magical intention." % [formatted["structure"], num_val, sprite.get("name", "the Sprite"), max_mag]
		}
		spell_evaluated.emit(res)
		return res

	# 3. Mathematical Value Mismatch against Envisioned Reality
	if num_val != target_qty:
		AudioManager.play_error()
		var diff_hint := "too small" if num_val < target_qty else "too large"
		var res := {
			"success": false,
			"failure_type": FailureType.MATH_OR_STRUCTURAL,
			"title": "Mathematical Mismatch with Reality",
			"expression": formatted["structure"],
			"diagnostic": "Your expression evaluates to %d, which is %s for the envisioned outcome (requires %d for %s). Observe the phenomenon again and adjust your inputs!" % [num_val, diff_hint, target_qty, enc["envision_target"]]
		}
		spell_evaluated.emit(res)
		return res

	# 4. Success! Envision -> Command -> Sprite Interpretation -> Physical Response
	enc["solved"] = true
	AudioManager.play_puzzle_success()
	if not str(enc.get("reward_spell_id", "")).is_empty():
		CodexManager.unlock_spell(enc["reward_spell_id"])
	if not str(enc.get("reward_archive_id", "")).is_empty():
		BookManager.unlock_archive_entry(enc["reward_archive_id"])

	var success_res := {
		"success": true,
		"failure_type": FailureType.NONE,
		"title": "Magical Resonance Achieved!",
		"expression": formatted["structure"],
		"diagnostic": "%s interpreted your formal command %s (= %d) and enacted your envisioned outcome: %s!" % [sprite.get("name", "The Magic Sprite"), formatted["structure"], num_val, enc["envision_description"]]
	}
	spell_evaluated.emit(success_res)
	return success_res
