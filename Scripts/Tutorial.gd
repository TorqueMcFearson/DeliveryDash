extends Control


# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if UI.tutorial \
		and event.is_pressed() \
		and event is InputEventMouseButton \
	or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		UI.tutorial = false
		self.hide()
		$Label.text = "-Game Paused-"
		#queue_free()
		get_tree().paused = false
