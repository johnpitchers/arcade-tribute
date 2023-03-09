extends Area

signal barrierHit(obj)


func _ready() -> void:
# warning-ignore:return_value_discarded
	connect("barrierHit", get_node("/root/GameWorld/Formation/Barriers"), "barrierDestroy")

func _on_Brick_area_entered(area: Area) -> void:
	if area.get_groups().has("Invaders"):
		emit_signal("barrierHit", self)
