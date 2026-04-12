extends Node

# ══════════════════════════════════════════════
# SpawnManager
# Owns all enemy spawn logic for the main game scene.
# Add as child of Main, call setup() in main._ready().
# Future game modes override spawn behavior here only.
# ══════════════════════════════════════════════

var main: Node = null

var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
var brute_scene: PackedScene = preload("res://Scenes/brute.tscn")
var runner_scene: PackedScene = preload("res://Scenes/runner.tscn")
var boss_scene: PackedScene = preload("res://Scenes/boss.tscn")

var spawn_timer: float = 0.0
var spawn_edge: int = 0

func setup(main_node: Node) -> void:
	main = main_node

# ── Wave enemy count ──────────────────────────
func get_wave_enemy_count() -> int:
	return int(main.BASE_ENEMIES_PER_WAVE + (main.wave * main.ENEMIES_PER_WAVE_WAVE_SCALING) + (main.phase * main.ENEMIES_PER_WAVE_PHASE_SCALING))

# ── Spawn tick — call from main._process() ────
func tick(delta: float) -> void:
	spawn_timer += delta
	var current_spawn_interval = (0.8 / (1.0 + (main.difficulty * 0.09))) * randf_range(0.8, 1.2)
	if spawn_timer >= current_spawn_interval and main.enemies_spawned < main.enemies_to_spawn:
		spawn_timer = 0.0
		main.enemies_spawned += 1
		_spawn_enemy()

# ── Enemy selection ───────────────────────────
func _get_spawn_scene() -> PackedScene:
	if main.phase < 2:
		return enemy_scene
	var brute_every: int = max(6, 10 - (main.phase - 2))
	var runner_every: int = max(4, 8 - (main.phase - 3)) if main.phase >= 3 else 0
	if runner_every > 0 and main.enemies_spawned % runner_every == 0:
		return runner_scene
	if main.enemies_spawned % brute_every == 0:
		return brute_scene
	return enemy_scene

# ── Spawn enemy ───────────────────────────────
func _spawn_enemy() -> void:
	var scene = _get_spawn_scene()
	var e = scene.instantiate()
	main.add_child(e)
	e.setup(main.get_node("Base"), main)
	e.scale_to_wave(main.difficulty)
	e.global_position = _random_edge_position()

# ── Spawn boss ────────────────────────────────
func spawn_boss() -> void:
	main.boss_wave = true
	main.boss_alive = true
	var b = boss_scene.instantiate()
	main.add_child.call_deferred(b)
	b.setup(main.get_node("Base"), main)
	b.scale_to_phase(main.phase)
	b.global_position = Vector2(360, -40)
	main.get_node("UI/WaveLabel").text = "⚠ BOSS WAVE ⚠ | Phase: " + str(main.phase)
	main.get_node("UIManager").boss_spawn_flash()
	AudioManager.play(AudioManager.sfx_boss_spawn)

# ── Edge positions ────────────────────────────
func _random_edge_position() -> Vector2:
	spawn_edge = (spawn_edge + 1) % 6
	match spawn_edge:
		0: return Vector2(randf_range(-350, 1070), -700)
		1: return Vector2(randf_range(-350, 1070), 2000)
		2: return Vector2(-380, randf_range(-700, 2000))
		3: return Vector2(-380, randf_range(-700, 2000))
		4: return Vector2(1100, randf_range(-700, 2000))
		5: return Vector2(1100, randf_range(-700, 2000))
	return Vector2.ZERO
