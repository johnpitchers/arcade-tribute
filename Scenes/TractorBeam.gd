extends Area

var start_radius: float = 1.0
var end_radius: float = 12.0
var radius_step: float = 0.4
var cube_size: float = 0.2
var ray_degrees: float = 30.0
var cube_arrays: Array
var counter: float = 0
var tractor_life_time: float = 8.0
var has_captured: bool = false

var muted: bool = false

onready var rand_num = randi()
onready var particle = preload("res://Scenes/ExplosionParticle.tscn")


func _ready():
	if muted:
		end_radius = 1.1
		radius_step = 0.8
		tractor_life_time = 2
		monitorable = false
	else:
		$SFX.play()

	generateRays()
	$LifeTimer.wait_time = tractor_life_time
	$LifeTimer.start()


func _process(delta: float) -> void:
	var r: float = 1.0 - counter
	var g: float = 1.0 - counter
	var b: float = 1.0
	var a: float = 1
	if muted:
		a = 0.01
	var row: float = 1
	counter = counter - delta * 3
	for cubes in cube_arrays:
		r = wrapf(r + 0.1, 0.0, 1.0)
		g = wrapf(g + 0.1, 0.0, 1.0)
		var color: Color = Color(r, g, b, a)
		for cube in cubes:
			cube.get_node("Mesh").mesh.material.albedo_color = color

	var particles = get_tree().get_nodes_in_group("TractorBeamParticles" + str(rand_num))
	if $LifeTimer.is_stopped() && !particles:
		if !muted:
			get_parent().exitCapturingState()
		self.queue_free()


func removeRays():
	var wait_time: float = 0.01
	for index in range(cube_arrays.size(), -1, -1):
		var cubes = cube_arrays.pop_back()
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = wait_time
		timer.one_shot = true
		timer.connect("timeout", self, "removeRay", [cubes])
		timer.start()
		wait_time = wait_time + 0.1


func removeRay(cubes: Array):
	if !muted:
		var pitch_step: float = 0.2 / (float(end_radius - start_radius) / radius_step)
		$SFX.pitch_scale = $SFX.pitch_scale - pitch_step
		$SFX.volume_db = $SFX.volume_db - pitch_step
	for i in cubes.size():
		var cube = cubes.pop_front()
		cube.queue_free()


func generateRays():
	var radius: float = start_radius
	var wait_time: float = 0.05
	while radius <= end_radius:
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = wait_time
		timer.one_shot = true
		timer.connect("timeout", self, "generateRay", [radius])
		timer.start()
		radius = radius + radius_step
		wait_time = wait_time + 0.05


func generateRay(radius: float = 1):
	if !muted:
		var pitch: float = 0.6 + 0.4 * (radius / float(end_radius))
		$SFX.pitch_scale = pitch
	if radius > end_radius - 1 && !has_captured:
		self.monitoring = true
	var angle: float = 0.0
	var cubes: Array
	while angle <= ray_degrees / 2:
		for c in range(-1, 2):
			var tempAngle = -90 + angle * c
			var x = radius * cos(deg2rad(tempAngle))
			var y = radius * sin(deg2rad(tempAngle))
			var cube = particle.instance()
			cube.add_to_group("TractorBeamParticles" + str(rand_num))
			cube.get_node("Mesh").mesh.size = Vector3(cube_size, cube_size, cube_size)
			cube.translation = Vector3(x, y, 0)
			add_child(cube)
			cubes.push_back(cube)
		angle = angle + (cube_size * 80 / radius)
	cube_arrays.push_back(cubes)


func _on_LifeTimer_timeout() -> void:
	self.monitoring = false
	removeRays()


func _on_TractorRay_area_shape_entered(
	area_rid: RID, area: Area, area_shape_index: int, local_shape_index: int
) -> void:
	if muted:
		return
	if has_captured:
		return
	capturePlayer(area)


func capturePlayer(player):
	has_captured = true
	self.monitoring = false
	player.playerInTractorBeam()
	var standIn = createStandInPlayer(player)
	animateToCapturePosition(standIn)
	State.captured_player_in_formation = true
	playCaptureSound()
	#$LifeTimer.stop()
	#$LifeTimer.wait_time = 1
	$LifeTimer.start(1.0)


func playCaptureSound():
	if !muted:
		$CaptureSFX.play()


func createStandInPlayer(player):
	var player_mesh: Spatial = player.find_node("Mesh")
	var standin_player_mesh = reparentStandInToInvader()
	standin_player_mesh.global_rotation = player_mesh.global_rotation
	standin_player_mesh.global_translation = player_mesh.global_translation
	standin_player_mesh.scale = player_mesh.scale
	standin_player_mesh.visible = true
	return standin_player_mesh


func reparentStandInToInvader():
	var standin_player_mesh = $StandInPlayerMesh
	self.remove_child(standin_player_mesh)
	get_parent().add_child(standin_player_mesh)
	get_parent().has_captured_player = true
	standin_player_mesh.set_owner(get_parent())
	return standin_player_mesh


func animateToCapturePosition(standIn):
	var end_position = get_parent().global_translation + Vector3(0, 2, 0)
	var end_rotation = Vector3(0, 0, PI * 4)
	#var transTween = Tween.new()
	standIn.get_node("TranslationTween").interpolate_property(
		standIn,
		"global_translation",
		standIn.global_translation,
		end_position,
		1.5,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	standIn.get_node("TranslationTween").start()
	standIn.get_node("RotationTween").interpolate_property(
		standIn, "rotation", standIn.rotation, end_rotation, 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT
	)
	standIn.get_node("RotationTween").start()
