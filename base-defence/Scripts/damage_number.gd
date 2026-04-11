extends Node2D

var velocity: Vector2 = Vector2(0, -60)
var lifetime: float = 0.8
var elapsed: float = 0.0

func setup(amount: float, pos: Vector2, type: String = "normal"):
	global_position = pos
	$Label.text = str(int(amount))
	$Label.add_theme_font_size_override("font_size", 16)
	match type:
		"normal":
			$Label.add_theme_color_override("font_color", Color.WHITE)
		"crit":
			$Label.add_theme_color_override("font_color", Color.ORANGE)
			$Label.add_theme_font_size_override("font_size", 20)
		"shield":
			$Label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		"hp":
			$Label.add_theme_color_override("font_color", Color.RED)
		"gold":
			$Label.add_theme_color_override("font_color", Color.GOLD)
			$Label.text = "💰" + $Label.text
		"lp":
			$Label.add_theme_color_override("font_color", Color(0.85, 0.4, 1.0))
			$Label.add_theme_font_size_override("font_size", 18)
			$Label.text = "★" + $Label.text
		"bleed":
			$Label.add_theme_color_override("font_color", Color(0.9, 0.0, 0.0))
			$Label.text = "🩸" + $Label.text
		"zap":
			$Label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
			$Label.add_theme_font_size_override("font_size", 18)
			$Label.text = "⚡" + $Label.text

func _process(delta):
	elapsed += delta
	position += velocity * delta
	modulate.a = 1.0 - (elapsed / lifetime)
	if elapsed >= lifetime:
		queue_free()
