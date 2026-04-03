extends Node2D

func _ready():
	var bullet_scene = preload("res://Scenes/Projectile.tscn")
	$Base.set_bullet_scene(bullet_scene)
