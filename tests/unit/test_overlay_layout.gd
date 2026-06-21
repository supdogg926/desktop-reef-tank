extends GutTest


func test_overlay_rect_1920x1080() -> void:
	var rect := OverlayLayout.calculate_overlay_rect(Vector2i(1920, 1080))
	assert_eq(rect, Rect2i(0, 864, 1920, 216), "1920x1080 bottom 1/5: y=864 h=216")


func test_overlay_rect_2560x1440() -> void:
	var rect := OverlayLayout.calculate_overlay_rect(Vector2i(2560, 1440))
	assert_eq(rect, Rect2i(0, 1152, 2560, 288), "2560x1440 bottom 1/5: y=1152 h=288")
