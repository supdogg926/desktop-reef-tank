extends GutTest


func test_save_then_load_restores_creatures() -> void:
	GameManager.owned_creatures.clear()
	GameManager.adopt("rainbow_carpet_anemone")
	GameManager.adopt("tomato_clown_f")
	var saved_count := GameManager.owned_creatures.size()

	GameManager.owned_creatures.clear()
	SaveManager.load_game()

	assert_eq(GameManager.owned_creatures.size(), saved_count, "读档后数量应该跟存档时一致")
