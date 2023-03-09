#########################
#
#  Custom explosion particle generator
#  Generates 3D meshes that tumble independently of their direction.
#  Using Godot particle engine, one face is always fixed billboard style.
#
#########################
extends Spatial

var particleMesh = preload("res://Scenes/ExplosionParticle.tscn")
var particles = []
var maxDuration = 0.1
var overrideColor: Color = Color(0, 0, 0, 0)


func _ready() -> void:
	pass


func init(location, numParticles:int = 1, force:float = 1.0, scale:float = 1.0, type = ""):
	scale *= 1.25
	#scale = max(scale, 0.6)
	print(scale)
	while particles.size() < numParticles:
		var particle = newParticleMesh(scale)
		particle.translation = location
		var particleObject = {
			"spatial": particle,
			"mesh": particle.get_node("Mesh"),
			"velocity": randf() * 3 * force * scale,
			"movementVector":
			Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized(),
			"rotationVector":
			Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized(),
			"rotationVelocity": randf() * 3,
			"duration": randf() * 2.5,
			"opacity": 1
		}
		particleObject.spatial.rotation = particleObject.rotationVector
		particleObject.spatial.translate(
			particleObject.movementVector * particleObject.velocity / 2
		)

		if particleObject.duration > maxDuration:
			maxDuration = particleObject.duration
		particles.push_back(particleObject)
		add_child(particle)
	$DurationTimer.wait_time = maxDuration
	$DurationTimer.start()
	if State.gameState == State.STATE_PLAYING:
		if numParticles < 10 && type != "None": type = "Small"
		playSound(type)


func playSound(type):
	match type:
		"None":
			pass
		"Invaders":
			$InvaderExplosionAudio.play()
		"Player":
			$PlayerExplosionAudio.play()
		"PowerUp":
			$PowerUpAudio.play()
		"MotherShip":
			$MotherShipExplosionAudio.play()
		_:
			$SmallExplosionAudio.play()

func newParticleMesh(_scale):
	var particleSpatial = particleMesh.instance()
	var particleMesh = particleSpatial.get_node("Mesh")
	#particleMesh.mesh = CubeMesh.new()
	#particleMesh.mesh.surface_set_material(0, SpatialMaterial.new())
	var scale = 0.14 * _scale
	var color = Color(1, 1, randf(), 1)
	if overrideColor != Color(0, 0, 0, 0) && randf() < 0.8: #80% of particles in override color
		color = overrideColor
	particleMesh.scale = Vector3(scale, scale, scale) * _scale
	particleMesh.mesh.material.emission = color
	particleMesh.mesh.material.albedo_color = color

	return particleSpatial


func _process(delta: float) -> void:
	for p in particles:
		if p.duration < 0:
			continue
		p.duration -= delta
		if p.duration < 0:
			p.mesh.queue_free()
		# Fade it out
		if p.duration < 0.5:
			p.opacity = p.duration / 0.5
			p.mesh.mesh.material.albedo_color.a = p.opacity
		p.mesh.rotate(p.rotationVector, p.rotationVelocity * delta)
		p.spatial.translate(p.movementVector * p.velocity * delta)
		p.velocity = lerp(p.velocity, 0, 0.01)


func _on_DurationTimer_timeout() -> void:
	self.queue_free()
