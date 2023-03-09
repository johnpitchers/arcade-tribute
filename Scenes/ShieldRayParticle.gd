extends Spatial

var start_radius = 0.5
var end_radius = 9.0
var radius_step = 0.4
var cube_size = 0.2
var ray_degrees = 40.0
var number_of_rays = 20
var cubeArrays: Array
var counter:float = 0
var tractorLifeTime:float = 5.0

func _ready():
	var radius: float = start_radius
	var waitTime = 0
	while radius <= end_radius:
		var timer = Timer.new()
		timer.add_to_group("RaySpawnTimers")
		add_child(timer)
		timer.wait_time = waitTime + 0.1
		timer.one_shot = true
		timer.connect("timeout", self, "generateRay", [radius])
		timer.start()
		radius = radius + radius_step
		waitTime = waitTime + 0.1
	$Li


func _process(delta: float) -> void:
	var r: float = 1.0-counter
	var g: float = 1.0-counter*1.1
	var b: float = 1.0
	var row: float = 1
	counter = counter - delta*2
	for cubes in cubeArrays:
		r = wrapf(r + 0.1, 0.0, 1.0)
		g = wrapf(g + 0.1, 0.0, 1.0)
		b = wrapf(b-0.1,0.0,1.0)
		var color: Color = Color(r, g, b)
		for cube in cubes:
			cube.mesh.material.albedo_color = color


func generateRay(radius: float = 1):
	var angle: float = 0.0
	var cubes: Array
	while angle <= ray_degrees / 2:
		for c in range(-1, 2):
			var tempAngle = -90 + angle * c
			var x = radius * cos(deg2rad(tempAngle))
			var y = radius * sin(deg2rad(tempAngle))
			var cube = MeshInstance.new()
			cube.mesh = CubeMesh.new()
			cube.mesh.size = Vector3(cube_size, cube_size, cube_size)
			cube.mesh.surface_set_material(0, SpatialMaterial.new())
			#cube.mesh.material.flags_unshaded = true
			cube.translation = Vector3(x, y, 0)
			add_child(cube)
			cubes.push_back(cube)
		angle = angle + (cube_size * 80 / radius)
	cubeArrays.push_back(cubes)
