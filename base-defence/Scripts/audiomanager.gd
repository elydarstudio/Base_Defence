extends Node

# ── Streams ───────────────────────────────────
var sfx_shoot: AudioStreamPlayer
var sfx_boss_spawn: AudioStreamPlayer
var sfx_take_damage: AudioStreamPlayer
var sfx_boss_death: AudioStreamPlayer
var sfx_music: AudioStreamPlayer

var _muted: bool = false

func _ready():
	sfx_shoot = AudioStreamPlayer.new()
	sfx_shoot.stream = preload("res://Assets/Sounds/Shoot.wav")
	add_child(sfx_shoot)

	sfx_boss_spawn = AudioStreamPlayer.new()
	sfx_boss_spawn.stream = preload("res://Assets/Sounds/BossSpawn.wav")
	add_child(sfx_boss_spawn)

	sfx_take_damage = AudioStreamPlayer.new()
	sfx_take_damage.stream = preload("res://Assets/Sounds/TakeDamage.wav")
	add_child(sfx_take_damage)

	sfx_boss_death = AudioStreamPlayer.new()
	sfx_boss_death.stream = preload("res://Assets/Sounds/BossDeath.wav")
	add_child(sfx_boss_death)

	sfx_music = AudioStreamPlayer.new()
	sfx_music.stream = preload("res://Assets/Sounds/Music.wav")
	sfx_music.volume_db = -7.0
	sfx_music.autoplay = true
	sfx_music.finished.connect(func(): sfx_music.play())
	add_child(sfx_music)

func play(player: AudioStreamPlayer):
	if not _muted:
		player.volume_db = -15.0
		player.play()

func toggle_mute() -> bool:
	_muted = !_muted
	if _muted:
		sfx_music.stop()
	else:
		sfx_music.play()
	return _muted

func is_muted() -> bool:
	return _muted
