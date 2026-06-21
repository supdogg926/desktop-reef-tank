extends GutTest

var emitter: PlaceholderSignalEmitter


func before_each() -> void:
	emitter = PlaceholderSignalEmitter.new()
	add_child(emitter)
	watch_signals(emitter)


func test_trigger_emits_signal() -> void:
	emitter.trigger(7)
	assert_signal_emitted(emitter, "something_happened")
	assert_signal_emitted_with_parameters(emitter, "something_happened", [7])
