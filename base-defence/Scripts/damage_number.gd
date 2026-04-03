extends Node2D

var velocity: Vector2 = Vector2(0, -60)
var lifetime: float = 0.8
var elapsed: float = 0.0

func setup(amount: float, pos: Vector2):
	global_position = pos
	$Label.text = str(int(amount))
	$Label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	$Label.add_theme_font_size_override("font_size", 16)

func _process(delta):
	elapsed += delta
	position += velocity * delta
	modulate.a = 1.0 - (elapsed / lifetime)
	if elapsed >= lifetime:
		queue_free()
