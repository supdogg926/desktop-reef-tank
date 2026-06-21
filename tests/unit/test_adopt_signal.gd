extends GutTest


func test_adopt_emits_signal_and_updates_list() -> void:
	GameManager.owned_creatures.clear()
	watch_signals(GameManager)
	GameManager.adopt("tomato_clown_m")
	assert_signal_emitted(GameManager, "creature_adopted")
	assert_eq(GameManager.owned_creatures.size(), 1, "领养后列表应该有1条记录")
