extends RefCounted
## Procedural light textures (no external assets).

static func make_radial_texture(size: int = 128, falloff: float = 1.6) -> ImageTexture:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x - c + 0.5, y - c + 0.5).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0) ** falloff
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
