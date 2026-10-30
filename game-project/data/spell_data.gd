extends Resource
class_name SpellData

@export var id: String = ""
@export var name: String = ""
@export var level: int = 1
@export_enum("Offensive", "Defensive", "Utility", "Exploration", "Special") var category: String = "Utility"
@export var tags: PackedStringArray = []
@export var description: String = ""
@export var command_syntax: String = ""
@export var required_sigil_ids: PackedStringArray = []
@export var mana_cost: int = 15
@export var cooldown: float = 4.0
@export var spell_range: String = "Medium"
@export var duration: String = "Instant"
@export var damage: int = 0
@export var element: String = "Resonance"
@export var icon_color: Color = Color("38bdf8")
@export var unlocked: bool = false

# Two-Table Envision & Command Breakdown
@export var envision_intent: String = ""
@export var envision_target: String = ""
@export var envision_shape: String = ""
@export var mathematical_formula: String = ""
@export var sprite_interpretation: String = ""
@export var physical_response: String = ""
