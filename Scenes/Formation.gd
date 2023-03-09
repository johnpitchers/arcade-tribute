extends Spatial

const TIME_BETWEEN_ROWS = 2.0
const TIME_BETWEEN_ALIENS = 0.1

const BIG_INVADER = 7
const MEDIUM_INVADER = 6
const SMALL_INVADER = 5
const BOSS_ALIEN = 4
const BIG_ALIEN = 3
const MEDIUM_ALIEN = 2
const SMALL_ALIEN = 1

var levelParams
var position = Config.formation.startPosition
var direction: String = "left"
var invaders: Array = []
var bosses: Array=[]
var invader = preload("res://Scenes/Invader.tscn")
var mother_ship = preload("res://Scenes/MotherShip.tscn")
var totalSpawned: int = 0
var spawnComplete: bool = false
var is_space_invader_level = false
var nextDirection = "left"
var oddEven:int = 0

func init() -> void:
	is_space_invader_level = isSpaceInvaderLevel()
	invaders = []
	spawnComplete = false
	totalSpawned = 0
	self.visible = true
	loadFormation()


func isSpaceInvaderLevel():
	if State.gameLevel % 8 == 3:
		$SpaceInvadersMovementTimer.wait_time = 1.5
		return true
	return false
	
func _process(delta: float) -> void:
	if State.gameState != State.STATE_PLAYING && !is_space_invader_level:
		return
	moveFormation(delta)
	if !is_space_invader_level:
		alwaysAttacking()


func alwaysAttacking():
	var aliensInFormation = get_tree().get_nodes_in_group("AliensInFormation")
	if aliensInFormation.size() && !get_tree().get_nodes_in_group("AliensAttacking"):
		aliensInFormation[randi() % aliensInFormation.size()].get_parent().enterAttackState()


func moveFormation(delta) -> void:
	if is_space_invader_level:
		moveSpaceInvaderFormation(delta)
	else:
		moveGalagaFormation(delta)

func moveSpaceInvaderFormation(delta):
	if !$MovementStartTimer.is_stopped(): return
	if $SpaceInvadersMovementTimer.is_stopped():
		if direction == "left":
			position.x = translation.x - Config.formation.spacing.x / 1.5
		if direction == "right":
			position.x = translation.x + Config.formation.spacing.x / 1.5
		
		#for inv in get_tree().get_nodes_in_group('Invaders'):
		#	inv.animate(direction)
		
		if direction == "down":
			position.y = translation.y - Config.formation.spacing.y / 1.5
			direction = nextDirection
		if State.gameState == State.STATE_PLAYING:
			var nextTick = lerp($SpaceInvadersMovementTimer.wait_time, 0.05, 0.02)
			$SpaceInvadersMovementTimer.wait_time = nextTick
			$SpaceInvadersMovementTimer.start()
			$SpaceInvaderFormationMoveAudio.play()
		oddEven = 1-oddEven # Used by space invader node for the mesh animation.
	
	translation.x = lerp(translation.x, position.x, Config.formation.spaceInvaderMovementLerpSpeed)
	translation.y = lerp(translation.y, position.y, Config.formation.spaceInvaderMovementLerpSpeed)
	for invader in get_tree().get_nodes_in_group("Invaders"):
		#var i = invader.get_node("Spatial")
		invader.translation = lerp(invader.translation, Vector3.ZERO, 2.5 * delta)
		changeDirectionIfAtEdge(invader)
		checkCollisionWithGround(invader)


func checkCollisionWithGround(invader):
	if invader.global_translation.y < 0 && State.gameState == State.STATE_PLAYING:
		get_node("/root/GameWorld/Player").playerHit()
		State.gameState = State.STATE_GAMEOVER


func changeDirectionIfAtEdge(invader):
	if invader.global_translation.x > Config.formation.maxX*4 && direction == "right":
		direction = "down"
		nextDirection = "left"

	if invader.global_translation.x < Config.formation.minX*4 && direction == "left":
		direction = "down"
		nextDirection = "right"
	if direction == "down" && State.gameState != State.STATE_PLAYING:
		direction = nextDirection


func moveGalagaFormation(delta):
	if !$MovementStartTimer.is_stopped():
		return
	match direction:
		"left":
			translation.x = translation.x - Config.formation.movementSpeed *delta
		"right":
			translation.x = translation.x + Config.formation.movementSpeed *delta
	if translation.x < Config.formation.minX:
		direction = "right"
	if translation.x > Config.formation.maxX:
		direction = "left"
		

func loadFormation():
	levelFormationAlgorithm()
	$"%MovementStartTimer".wait_time = Config.formation.movementTimerStartTime
	$"%MovementStartTimer".start()
	get_node("/root/GameWorld/MainViewportContainer/Viewport/Camera/GameUI/WaveTitleLabel").visible = true
	position = {"x": Config.formation.startPosition.x, "y": Config.formation.startPosition.y}
	if is_space_invader_level:
		position.y = position.y + 2
	self.translation = Vector3(position.x, position.y, 0)
	$MotherShipSpawnTimer.wait_time = Config.motherShip.first_interval
	$MotherShipSpawnTimer.start()
	
	if is_space_invader_level:
		buildFormation()
		$Barriers.buildBarriers(5)


func buildFormation():
	direction = "left" if (randf() < 0.5) else "right"
	for row in levelParams.rows:
		for col in levelParams.columns:
			var obj: Dictionary
			var x: float = (
				(col * Config.formation.spacing.x)
				- ((levelParams.columns - 1.01) / 2 * Config.formation.spacing.x)
			)
			var y: float = (
				(row * Config.formation.spacing.y)
				- ((levelParams.rows - 1.01) / 2 * Config.formation.spacing.y)
			)
			if !is_space_invader_level:
				if row < (levelParams.rows - ((levelParams.rows) / 3) * 2)-1:
					obj.type = SMALL_ALIEN
					obj.lives = levelParams.alien1Lives
					obj.scale = 0.25
				else:
					if row < (levelParams.rows - ((levelParams.rows) / 3))-1:
						obj.type = MEDIUM_ALIEN
						obj.lives = levelParams.alien2Lives
						obj.scale = 0.25
					else:
						if row< levelParams.rows - 1:
							obj.type = BIG_ALIEN
							obj.lives = levelParams.alien3Lives
							obj.scale = 0.25
						else:
							obj.type = BOSS_ALIEN
							obj.lives = max((levelParams.alien3Lives*2), 1)
							obj.scale = 0.25
			else:
				if row <(levelParams.rows - ((levelParams.rows) / 3) * 2):
					obj.type = BIG_INVADER
					obj.lives = levelParams.alien3Lives
					obj.scale = 0.4
				elif row < levelParams.rows - ((levelParams.rows) / 3):
					obj.type = MEDIUM_INVADER
					obj.lives = levelParams.alien2Lives
					obj.scale = 0.35
				else:
					obj.type = SMALL_INVADER
					obj.lives = levelParams.alien1Lives
					obj.scale = 0.3
			
			obj.rand = randf()
			obj.x = x
			obj.y = y
			obj.row = row
			obj.col = col
			invaders.append([])
			invaders[row].append([])
			invaders[row][col] = obj
	spawnAliens()


func spawnAliens():
	var patternNum = State.gameLevel % 4
	var randomArr = []
	var spawnArray: Array
	# Each value in the spawnArray represents an invade path
	# assigned to the next row in the alien formation
	# Each row in the spawnArray will be separated by TIME_BETWEEN_ROWS

	# 1: From top right to bottom left than across the middle
	# 2: From top left to bottom left then across the middle
	# 3: From top right to middle left then swoops back to exit middle right.
	# 4: From top left to middle left then swoops back to exit middle left.
	# 5: From top left flies in circle in middle of screen. Exit right.
	# 6: From top right flies in circle in middle of screen. Exit left.
	# 7: Same as 5 1.3x larger. Fly in parallel to 5.
	# 8: Same as 6 1.3x larger. Fly in parallel to 6
	# 9: From top right to center, down the middle then out top right
	# 10: From top left to center, down the middle then out top left
	match patternNum:
		0:
			spawnArray = [
				[9, 10],
				[5, 7],
				[6, 8],
				[1, 2],
				[3, 4]
			]
		1:
			spawnArray = [
				[1],
				[2],
				[4],
				[5, 7],
				[3],
				[6, 8],
				[3, 4]
			]
		2:
			spawnArray = [
				[5, 6],
				[1, 2],
				[3, 4],
				[9, 10],
				[5, 7]
			]
		3:
			spawnArray = [
				[5, 7],
				[6, 8],
				[1, 2],
				[10, 9],
				[5, 6],
			]
	
	if State.is_bonus_level:
		spawnArray = []
		var i = 0
		for row in levelParams.rows:
			i += 1
			spawnArray.push_back([((State.gameLevel+i) % 10)+1])
	
	var spawnArrayPointerRow = 0
	var spawnArrayPointerCol = 0
	var waitTime: float = 0.0
	for row in levelParams.rows:
		# Randomise the columns
		for i in levelParams.columns:
			randomArr.append(i)
		for col in int(randomArr.size()):
			var columnIndex = int(rand_range(0, randomArr.size()))

			# Assign the invade pattern number to the invader object
			# SpaceInvaders always assigned pattern 0
			if !is_space_invader_level:
				invaders[row][randomArr[columnIndex]].pattern = spawnArray[spawnArrayPointerRow][spawnArrayPointerCol]
			else:
				invaders[row][randomArr[columnIndex]].pattern = 0
				
			#create a timer to call the spawnAlien function
			var timer = Timer.new()
			timer.add_to_group("AlienSpawnTimers")
			add_child(timer)
			if !is_space_invader_level:
				timer.wait_time = waitTime + (TIME_BETWEEN_ALIENS * col)
				timer.one_shot = true
				timer.connect("timeout", self, "spawnAlien", [row, randomArr[columnIndex]])
				timer.start()
			else:
				spawnAlien(row,randomArr[columnIndex])

			# Remove the spawned column from the index.
			randomArr.remove(columnIndex)

		# Increate the spawn array column index.
		spawnArrayPointerCol += 1

		# If no more cols in this spawnArray row, increase the wait time and increment the row index
		if !range(spawnArray[spawnArrayPointerRow].size()).has(spawnArrayPointerCol):
			spawnArrayPointerRow += 1
			spawnArrayPointerCol = 0
			if !is_space_invader_level:
				waitTime += TIME_BETWEEN_ROWS


func spawnAlien(row, col):
	var inv = invader.instance()
	var invObj = invaders[row][col]
	get_parent().add_child(inv)
	inv.init(invObj)
	totalSpawned += 1
	spawnComplete = totalSpawned == State.totalAliensThisLevel


func levelFormationAlgorithm():
	levelParams = JSON.parse(JSON.print(Config.formation)).result  #deepcopy of Config.formation
	
	# Set bonus level params
	
	if State.is_bonus_level == true:
		levelParams.columns = 10
		levelParams.rows = 5
		State.totalAliensThisLevel = levelParams.rows * levelParams.columns
		return
	
	#Alien grid gets bigger each level up to a max size
	levelParams.columns = min(
		Config.formation.columns + int((State.gameLevel) / 2), Config.formation.maxColumns
	)
	levelParams.rows = min(
		Config.formation.rows + State.gameLevel - 1, Config.formation.maxRows
	)
	if is_space_invader_level:
		levelParams.rows = min(levelParams.rows, Config.formation.maxSpaceInvaderRows)

	State.totalAliensThisLevel = levelParams.rows * levelParams.columns

	# Give aliens lives, so they take more than one hit to die.
	# Alien3 gets 1 life. From Level 5 it gets 2 lives increasing by 1 every 5 levels.
	# From Level 8 Alien2 gets 1 life increasing by 1 every 5 levels.
	var maxAlienLives = 10
	levelParams.alien3Lives = 1
	if State.gameLevel > 4:
		levelParams.alien3Lives = 2 + int((State.gameLevel / 5) - 1)
		if levelParams.alien3Lives > maxAlienLives:
			levelParams.alien3Lives = maxAlienLives

	if State.gameLevel > 7:
		levelParams.alien2Lives = 1 + int((State.gameLevel / 5) - 1)
		if levelParams.alien2Lives > maxAlienLives:
			levelParams.alien2Lives = maxAlienLives


func _on_MovementStartTimer_timeout() -> void:
	get_node("/root/GameWorld/MainViewportContainer/Viewport/Camera/GameUI/WaveTitleLabel").visible = false
	for invader in get_tree().get_nodes_in_group("Invaders"):
		invader.get_node("CollisionShape").disabled = false
	$"%Player".can_shoot = true
	randomize()
	if !is_space_invader_level:
		buildFormation()


func motherShipTimerRestart():
	$MotherShipSpawnTimer.stop()
	$MotherShipSpawnTimer.wait_time = Config.motherShip.interval
	$MotherShipSpawnTimer.start()

func _on_MotherShipSpawnTimer_timeout() -> void:
	var mother_ship_instance = mother_ship.instance()
	mother_ship_instance.fireRate = Config.motherShip.fireRate
	get_node("/root/GameWorld").add_child(mother_ship_instance)
