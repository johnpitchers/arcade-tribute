extends Spatial

var brick1 = preload("res://Scenes/Brick.tscn")
var explosion = preload("res://Scenes/Explosion.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func buildBarriers(numBarriers):
	var posy:float = 4
	var totalWidth:float = Config.formation.maxX*4 - Config.formation.minX*4
	var distance:float = totalWidth / (numBarriers - 1)
	var posx:float = Config.formation.minX*4
	for i in numBarriers:
		var pos = Vector3(posx, posy, 0)
		buildBarrier(pos)
		posx += distance


func buildBarrier(pos):
	var rows:float = 8
	var columns:float = 14
	for row in rows:
		for column in columns:
			# Omit certain blocks to create the arch
			if row == 2 && column > 3 && column < columns - 4:
				continue
			if row < 2 && column > 2 && column < columns - 3:
				continue
			if row == rows - 1 && (column == 0 || column == columns - 1):
				continue
			var brick = brick1.instance()
			var brickSize = {
				"x": brick.get_node("MeshInstance").mesh.size.x,
				"y": brick.get_node("MeshInstance").mesh.size.y
			}

			var x:float = (column * brickSize.x) - ((columns - 1) / 2 * brickSize.x)-0.15 # -0.15 to center the barriers.
			var y:float = (row * brickSize.y) - ((rows - 1) / 2 * brickSize.y)
			var brickColor:Color = Color(
				0.7 + rand_range(-0.1, 0.1),
				0.6 + rand_range(-0.1, 0.1),
				0.4 + rand_range(-0.1, 0.1),
				1
			)
			brick.get_node("MeshInstance").mesh.material.albedo_color = brickColor
			brick.get_node("MeshInstance").mesh.material.emission = brickColor
			get_node("/root/GameWorld").add_child(brick)
			brick.global_translation = Vector3(x, y, 0) + pos


func barrierDestroy(brickInstance):
	var explosionInstance = explosion.instance()
	brickInstance.queue_free()
	get_node("/root/GameWorld").add_child(explosionInstance)
	explosionInstance.init(brickInstance.global_translation, 4, 0.6, 0.8, "None")
