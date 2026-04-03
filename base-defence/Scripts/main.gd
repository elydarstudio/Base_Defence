extends Node2D

var bullet_scene: PackedScene
var enemy_scene: PackedScene

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var currency: int = 0

func _ready():
	bullet_scene = preload("res://Scenes/Projectile.tscn")
	enemy_scene = preload("res://Scenes/Enemy.tscn")
	$Base.set_bullet_scene(bullet_scene)

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

func _spawn_enemy():
	var e = enemy_scene.instantiate()
	add_child(e)
	e.setup($Base, self)
	e.global_position = _random_edge_position()

func add_currency(amount: int):
	currency += amount
	$UI/CurrencyLabel.text = "Gold: " + str(currency)

func _random_edge_position() -> Vector2:
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 480), -20)
		1: return Vector2(randf_range(0, 480), 874)
		2: return Vector2(-20, randf_range(0, 854))
		3: return Vector2(500, randf_range(0, 854))
	return Vector2.ZERO
