extends GutTest


func test_add_two() -> void:
	assert_eq(PlaceholderMath.add_two(2, 3), 5, "2+3 应该等于 5")
