extends Resource
class_name SigilData

@export var id: String = ""
@export var name: String = ""
@export var symbol: String = ""
@export_enum("Number", "Operation", "Relation", "Variable", "Function", "Other") var unit_category: String = "Operation"
@export var math_meaning: String = ""
@export var description: String = ""
@export var expected_inputs: int = 1
@export var icon_color: Color = Color("38bdf8")
@export var unlocked_by_default: bool = true
