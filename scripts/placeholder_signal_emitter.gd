class_name PlaceholderSignalEmitter
extends Node

signal something_happened(value: int)


func trigger(value: int) -> void:
	something_happened.emit(value)
