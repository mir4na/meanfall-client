extends Resource

class_name PowerUp

enum Type { NONE, TRIPLE_DAMAGE }

@export var type: Type = Type.NONE
@export var display_name: String = ""
@export var description: String = ""
@export var color: Color = Color.WHITE

static func create_triple_damage() -> PowerUp:
	var pu := PowerUp.new()
	pu.type = Type.TRIPLE_DAMAGE
	pu.display_name = "TRIPLE THREAT"
	pu.description = "This round, any non-winner loses 3 lives instead of 1 (affects everyone!)"
	pu.color = Color(1.0, 0.2, 0.2)
	return pu

static func from_string(type_string: String) -> PowerUp:
	match type_string:
		"triple_damage":
			return create_triple_damage()
		_:
			return PowerUp.new()
