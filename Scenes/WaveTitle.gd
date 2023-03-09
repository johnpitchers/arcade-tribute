extends Label3D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

var startTimer:Timer

func _ready() -> void:
	startTimer = get_node("/root/GameWorld/Formation/MovementStartTimer")

func _process(delta: float) -> void:
	pass

func setText():
	if State.is_bonus_level:
		text = "CHALLENGE STAGE"
	else:
		text = "STAGE " + str(State.gameLevel)
