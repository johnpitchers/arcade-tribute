extends Spatial


func _ready() -> void:
	$ExtraLife/PowerUp.remove_from_group("PowerUps")
	$ExtraLife/PowerUp/Meshes/powerup_extralife.visible = true
	$DoubleShot/PowerUp.remove_from_group("PowerUps")
	$DoubleShot/PowerUp/Meshes/powerup_doubleshot.visible = true
	$TripleShot/PowerUp.remove_from_group("PowerUps")
	$TripleShot/PowerUp/Meshes/powerup_tripleshot.visible = true
	$DoubleFireRate/PowerUp.remove_from_group("PowerUps")
	$DoubleFireRate/PowerUp/Meshes/powerup_firerateincrease.visible = true
