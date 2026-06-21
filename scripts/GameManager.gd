extends Node

signal creature_adopted(instance_id: String, species_id: String)

var owned_creatures: Array = []  # [{instance_id, species_id, adopted_at}]


func adopt(species_id: String) -> String:
	var instance_id := species_id + "_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	owned_creatures.append({
		"instance_id": instance_id,
		"species_id": species_id,
		"adopted_at": Time.get_unix_time_from_system(),
	})
	creature_adopted.emit(instance_id, species_id)
	SaveManager.save_game()
	return instance_id
