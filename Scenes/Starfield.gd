extends Spatial

var stars: Array = []
onready var starEntity = preload("res://Scenes/ExplosionParticle.tscn")

func _ready() -> void:
	createStarField()


func _process(delta: float) -> void:
	rollStarField(delta)


func createStarField() -> void:
	randomize()
	while stars.size() < Config.starfield.maxStars:
		var star: Spatial = newStarMesh()
		var star_object = {
			"mesh": star,
			"does_blink": false,
			"blink_interval": rand_range(0.5, 2),
			"blink_timer": 0
		}
		if randf() < Config.starfield.ratioOfBlinkers:
			star_object.does_blink = true
		add_child(star)
		stars.push_back(star_object)


func newStarMesh() -> MeshInstance:
	var scale = rand_range(Config.starfield.minSize, Config.starfield.maxSize)
	var color_index = rand_range(0, Config.starfield.colors.size() - 1)
	var color = Color(
		Config.starfield.colors[color_index][0],
		Config.starfield.colors[color_index][1],
		Config.starfield.colors[color_index][2],
		0.95
	)
	
	# Create the cube mesh
	var star_mesh = starEntity.instance()
	star_mesh.translation = Vector3(
		rand_range(Config.starfield.minX, Config.starfield.maxX),
		rand_range(Config.starfield.minY, Config.starfield.maxY),
		-5
	)
	star_mesh.scale = Vector3(scale, scale, scale)
	
	# Create the material
	#star_mesh.get_node("Mesh").mesh.material.flags_unshaded = true
	star_mesh.get_node("Mesh").mesh.material.emission = color
	star_mesh.get_node("Mesh").mesh.material.albedo_color = color
	return star_mesh


func rollStarField(delta) -> void:
	for s in stars:
		s.mesh.translation.y -= Config.starfield.speed * delta
		if s.mesh.translation.y < Config.starfield.minY:
			s.mesh.translation.y = Config.starfield.maxY
		s.blink_timer += delta
		if s.does_blink && s.blink_timer > s.blink_interval:
			s.mesh.visible = !s.mesh.visible
			s.blink_timer = 0
