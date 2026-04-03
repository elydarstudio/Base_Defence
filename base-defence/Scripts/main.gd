extends Node2D

var bullet_scene: PackedScene
var enemy_scene: PackedScene

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var currency: int = 0

# Upgrade tracking
var attack_speed_level: int = 0
var attack_speed_cost: int = 25
var attack_speed_max: int = 10

func _ready():
	bullet_scene = preload("res://Scenes/Projectile.tscn")
	enemy_scene = preload("res://Scenes/Enemy.tscn")
	$Base.set_bullet_scene(bullet_scene)
	_update_ui()

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
	_update_ui()

func _update_ui():
	$UI/CurrencyLabel.text = "Gold: " + str(currency)
	var btn = $UI/UpgradeButton
	if attack_speed_level >= attack_speed_max:
		btn.text = "Attack Speed - MAXED"
		btn.disabled = true
	else:
		btn.text = "Attack Speed Lv" + str(attack_speed_level + 1) + " - " + str(attack_speed_cost) + "g"
		btn.disabled = currency < attack_speed_cost

func _on_upgrade_button_pressed():
	if currency < attack_speed_cost:
		return
	if attack_speed_level >= attack_speed_max:
		return
	currency -= attack_speed_cost
	attack_speed_level += 1
	attack_speed_cost = int(attack_speed_cost * 1.4)  # scaling cost
	$Base.fire_rate += 0.5  # each level adds 0.5 shots/sec
	_update_ui()

func _random_edge_position() -> Vector2:
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 480), -20)
		1: return Vector2(randf_range(0, 480), 874)
		2: return Vector2(-20, randf_range(0, 854))
		3: return Vector2(500, randf_range(0, 854))
	return Vector2.ZERO
