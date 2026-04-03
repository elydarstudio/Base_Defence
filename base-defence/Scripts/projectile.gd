extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: float = 10.0
var lifetime: float = 2.0

func _ready():
	var poly = $Visual
	poly.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(4, 4), Vector2(-4, 4)
	])
	poly.color = Color(1.0, 0.9, 0.2)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, spd: float, dmg: float):
	direction = dir
	speed = spd
	damage = dmg

func _process(delta):
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.take_damage(damage)
		queue_free()
