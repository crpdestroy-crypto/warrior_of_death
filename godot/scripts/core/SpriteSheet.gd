class_name SpriteSheet
extends RefCounted

static func slice(path: String, count: int, w: int, h: int) -> Array:
	var out: Array = []
	var tex: Texture2D = load(path)
	if tex == null:
		return out
	for i in range(count):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		out.append(at)
	return out

static func make(frames: Dictionary, speeds: Dictionary, loops: Dictionary) -> SpriteFrames:
	var f := SpriteFrames.new()
	for anim in frames.keys():
		var key := String(anim)
		if not f.has_animation(key):
			f.add_animation(key)
		f.set_animation_speed(key, float(speeds.get(key, 8.0)))
		f.set_animation_loop(key, bool(loops.get(key, true)))
		var list: Array = frames[anim]
		for t in list:
			f.add_frame(key, t)
	return f
