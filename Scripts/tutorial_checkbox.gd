extends CheckBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_pressed_no_signal(UI.tutorial_enabled)
	UI.tutorial_change.connect(update_text)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_toggled(toggled_on: bool) -> void:
	UI.tutorial_enabled = toggled_on
	Save.save_preferences()


func update_text():
	if UI.tutorial_enabled:
		$"../TutorialLabel".text = "Tutorial Enabled"
		$"../TutorialLabel".modulate = "white"
		#UI.show_tutorial()
	else:
		$"../TutorialLabel".modulate = Color(1, 1, 1, 0.5)
		$"../TutorialLabel".text = "Tutorial Disabled"
		#UI.hide_tutorial()  # Replace with function body.
	set_pressed_no_signal(UI.tutorial_enabled)
	
