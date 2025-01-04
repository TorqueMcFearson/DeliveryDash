extends Control


# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event.is_pressed() and event is InputEventMouseButton:
		UI.tutorial = false
		self.hide()
		$Label.text = "-Game Paused-\nClick to Continue"
		#queue_free()
		get_tree().paused = false
