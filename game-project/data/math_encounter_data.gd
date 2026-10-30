extends Resource
class_name MathEncounterData

@export var id: String = ""
@export var title: String = ""
@export var is_temporary_example: bool = true
@export var curriculum_competency: String = ""
@export var sprite_name: String = "Auri (Counting Sprite)"
@export var sprite_dialogue: String = ""

# Table 1: Envision
@export var envision_summary: String = ""
@export var envision_target: String = "Floating Stones"
@export var envision_action: String = "Move / Arrange"
@export var envision_quantity: String = "6"

# Table 2: Command Validation
@export var required_sigil_id: String = "sigil_count"
@export var expected_values: Array[int] = [6]
@export var alternative_valid_expressions: PackedStringArray = ["Count(6)", "Add(3,3)", "Add(4,2)", "Multiply(2,3)"]
@export var hint_ladder: PackedStringArray = []

# Rewards & Progression
@export var reward_spell_id: String = ""
@export var reward_archive_id: String = ""
@export var unlocks_gate_id: String = ""
