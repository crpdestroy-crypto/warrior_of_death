class_name ParallaxCrypt
extends ParallaxBackground
## Фон склепа-усыпальницы в духе референса: небо с луной, горы, руины, земля.

func _ready() -> void:
	layer = -100
	z_index = -100
	var sky := ParallaxLayer.new()
	sky.motion_scale = Vector2(0.05, 0.0)
	sky.motion_mirroring = Vector2(640, 0)
	add_child(sky)
	var sky_spr := Sprite2D.new()
	sky_spr.texture = load("res://assets/bg/sky.png")
	sky_spr.centered = false
	sky.add_child(sky_spr)
	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.2, 0.0)
	far.motion_mirroring = Vector2(640, 0)
	far.position = Vector2(0, 130)
	add_child(far)
	var far_spr := Sprite2D.new()
	far_spr.texture = load("res://assets/bg/far.png")
	far_spr.centered = false
	far.add_child(far_spr)
	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.5, 0.0)
	mid.motion_mirroring = Vector2(640, 0)
	mid.position = Vector2(0, 150)
	add_child(mid)
	var mid_spr := Sprite2D.new()
	mid_spr.texture = load("res://assets/bg/mid.png")
	mid_spr.centered = false
	mid.add_child(mid_spr)

	var front := ParallaxLayer.new()
	front.motion_scale = Vector2(1.2, 0.0)
	front.motion_mirroring = Vector2(640, 0)
	front.position = Vector2(0, 250)
	add_child(front)
	var front_spr := Sprite2D.new()
	front_spr.texture = load("res://assets/bg/foreground.png")
	front_spr.centered = false
	front_spr.modulate = Color(1, 1, 1, 0.9)
	front.add_child(front_spr)
