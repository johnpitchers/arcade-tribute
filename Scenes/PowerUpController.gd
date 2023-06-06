extends Node

var power_ups_this_level: int = 0

onready var power_up = preload("res://Scenes/PowerUp.tscn")
onready var gameWorld = get_node("/root/GameWorld")

enum TYPE {
	EXTRA_SHOT,
	FIRE_RATE,
	EXTRA_LIFE,
	SMART_BOMB,
	DOUBLE_SHOT,
	TRIPLE_SHOT,
	#INVINCIBILITY
}


func spawnByChance(trans: Vector3 = Vector3.ZERO):
	# Not on the first level.
	if State.gameLevel < 2:
		return

	# The spawn point needs to be high enough up the screen to give the player
	# time to collect it.
	if trans.y < 7:
		return

	# Max power ups generated each level
	if power_ups_this_level >= Config.maxPowerUpsPerLevel:
		return

	# Roll the dice
	if randf() > Config.powerUpChance:
		return
	spawn(trans)


func spawn(trans):
	var type: int = randomType()
	if type == -1:
		return
	power_ups_this_level += 1
	var pup = power_up.instance()
	pup.translation = trans
	pup.init(type)
	gameWorld.add_child(pup)


func randomType():
	var type: int = -1
	var tries = 0
	while type == TYPE.EXTRA_SHOT || type == -1:
		tries += 1
		if tries > 10:
			return -1
		type = randi() % (TYPE.size() - 2)
		if type == TYPE.EXTRA_SHOT:
			type = determineExtraShotType()
		# Firerate power up only if the player doesn't already have it.
		if type == TYPE.FIRE_RATE && State.player.fireRateIncreased:
			type = -1
		# Save smart bombs for later in the game
		if type == TYPE.SMART_BOMB && State.gameLevel < 10:
			type = -1
		# Ensure the power up isnt already in the scene
		var powerUpsInScene = get_tree().get_nodes_in_group("PowerUps")
		for pup in powerUpsInScene:
			if pup.type == type:
				type = -1
		# Only spawn extra lives if the player is low on lives.
		if type == TYPE.EXTRA_LIFE && State.player.lives > 1:
			type = -1
	return type


func determineExtraShotType():
	var type: int
	if State.player.lazerLevel == 1:
		type = TYPE.DOUBLE_SHOT
	if State.player.lazerLevel == 2:
		type = TYPE.TRIPLE_SHOT
	return type
