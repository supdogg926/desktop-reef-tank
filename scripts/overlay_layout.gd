class_name OverlayLayout
extends RefCounted


static func calculate_overlay_rect(screen_size: Vector2i, height_ratio: float = 0.2) -> Rect2i:
	var h := int(round(screen_size.y * height_ratio))
	var y := screen_size.y - h
	return Rect2i(0, y, screen_size.x, h)
