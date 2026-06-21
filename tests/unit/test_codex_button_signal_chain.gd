extends GutTest

var main_scene: Node


func before_each() -> void:
	GameManager.owned_creatures.clear()
	# 清除旧存档，防止之前测试的存档干扰
	var save_path := "user://save.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	main_scene = load("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main_scene)
	# Scene._ready() is now async (has await process_frame x2),
	# so the test must also wait before accessing child nodes


func test_clicking_adopt_button_in_codex_triggers_real_adopt() -> void:
	# Wait for async _ready() to complete
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var adopt_button: Button = main_scene.find_child("AdoptButton_tomato_clown_m", true, false)
	assert_not_null(adopt_button, "应该能在场景树里找到番茄小丑公鱼的领养按钮")
	watch_signals(GameManager)
	adopt_button.pressed.emit()
	assert_signal_emitted(GameManager, "creature_adopted")
	assert_eq(GameManager.owned_creatures.size(), 1, "领养后列表应该有1条记录")
