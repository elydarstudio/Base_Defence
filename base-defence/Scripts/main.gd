extends Node2D

var bullet_scene: PackedScene
var enemy_scene: PackedScene
var boss_scene: PackedScene
var damage_number_scene: PackedScene

var spawn_timer: float = 0.0
var spawn_interval: float = 1.5
var currency: int = 0

var attack_speed_level: int = 0
var attack_speed_cost: int = 25
var attack_speed_max: int = 10

var wave: int = 1
var wave_timer: float = 0.0
var wave_duration: float = 20.0  # seconds per wave
var enemies_killed: int = 0
var enemies_needed: int = 10
var phase: int = 1
var game_over: bool = false
var boss_wave: bool = false
var boss_alive: bool = false

var difficulty: int = 0

func _ready():
	bullet_scene = preload("res://Scenes/Projectile.tscn")
	enemy_scene = preload("res://Scenes/Enemy.tscn")
	boss_scene = preload("res://Scenes/Boss.tscn")
	damage_number_scene = preload("res://Scenes/damage_number.tscn")
	$Base.set_bullet_scene(bullet_scene)
	$Base.set_main(self)
	_update_ui()

func _process(delta):
	if game_over or boss_wave:
		return
	wave_timer += delta
	spawn_timer += delta
	
	var current_spawn_interval = max(0.3, spawn_interval - (difficulty * 0.05))
	if spawn_timer >= current_spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()
	
	if wave_timer >= wave_duration:
		wave_timer = 0.0
		_advance_wave()

func _spawn_enemy():
	var e = enemy_scene.instantiate()
	add_child(e)
	e.setup($Base, self)
	e.scale_to_wave(difficulty)
	e.global_position = _random_edge_position()

func _spawn_boss():
	boss_wave = true
	boss_alive = true
	var b = boss_scene.instantiate()
	add_child(b)
	b.setup($Base, self)
	b.scale_to_phase(difficulty)
	b.global_position = Vector2(240, -40)
	$UI/WaveLabel.text = "⚠ BOSS WAVE ⚠ | Phase: " + str(phase)
	
func spawn_damage_number(amount: float, pos: Vector2):
	var dn = damage_number_scene.instantiate()
	$DamageLayer.add_child(dn)
	dn.setup(amount, pos)

func on_boss_killed():
	boss_alive = false
	boss_wave = false
	wave = 1
	phase += 1
	difficulty += 3  # boss kill = big difficulty jump
	enemies_killed = 0
	enemies_needed = int(10 + (difficulty * 0.8))
	_update_ui()

func add_currency(amount: int):
	currency += amount
	if not boss_wave:
		enemies_killed += 1
	_update_ui()
func _advance_wave():
	wave += 1
	difficulty += 1
	enemies_needed = int(10 + (difficulty * 1.2))
	spawn_interval = max(0.3, 1.5 - (difficulty * 0.05))
	if wave >= 10:
		_spawn_boss()
	else:
		_update_ui()

func update_health_ui(hp: float):
	$UI/BaseHealthLabel.text = "HP: " + str(int(hp))

func trigger_game_over():
	game_over = true
	$UI/GameOverScreen.visible = true
	$UI/GameOverScreen/PhaseLabel.text = "Phase Reached: " + str(phase)
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _update_ui():
	$UI/CurrencyLabel.text = "Gold: " + str(currency)
	$UI/WaveLabel.text = "Wave: " + str(wave) + " | Phase: " + str(phase)
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
	attack_speed_cost = int(attack_speed_cost * 1.4)
	$Base.fire_rate += 0.5
	_update_ui()

func _random_edge_position() -> Vector2:
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 480), -20)
		1: return Vector2(randf_range(0, 480), 874)
		2: return Vector2(-20, randf_range(0, 854))
		3: return Vector2(500, randf_range(0, 854))
	return Vector2.ZERO
