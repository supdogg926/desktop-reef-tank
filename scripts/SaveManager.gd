extends Node

const SAVE_PATH := "user://save.json"


func save_game() -> void:
	var data := {"owned_creatures": GameManager.owned_creatures}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := f.get_as_text()
	f.close()
	var data: Dictionary = JSON.parse_string(content)
	if data and data.has("owned_creatures"):
		GameManager.owned_creatures = data["owned_creatures"]
