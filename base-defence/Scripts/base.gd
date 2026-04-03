extends Area2D

@export var fire_rate: float = 1.0       # shots per second
@export var bullet_speed: float = 400.0
@export var bullet_damage: float = 10.0
@export var detection_radius: float = 250.0

var fire_timer: float = 0.0
var bullet_scene: PackedScene

func _ready():
	position = Vector2(240, 427)  # center of 480x854 screen
	_draw_base()

func _draw_base():
	var poly = $Visual
	# Hexagon shape
	var points = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60 * i - 30)
		points.append(Vector2(cos(angle), sin(angle)) * 30)
	poly.polygon = points
	poly.color = Color(0.2, 0.6, 1.0)  # blue

func _process(delta):
	fire_timer += delta
	if fire_timer >= 1.0 / fire_rate:
		fire_timer = 0.0
		_try_shoot()

func _try_shoot():
	var target = _get_nearest_enemy()
	if target == null:
		return
	if bullet_scene == null:
		return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.setup(global_position.direction_to(target.global_position), bullet_speed, bullet_damage)

func _get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_dist = detection_radius
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func set_bullet_scene(scene: PackedScene):
	bullet_scene = scene
