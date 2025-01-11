extends Control

const CITY = preload("res://CityMain.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UI.hide_UI()
	UI.fade_in()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	for button in [$Start, $Options, $Exit]:
		button.disabled = true
	if UI.day_over:return
	UI.fade_out(1,get_tree().change_scene_to_packed.bind(CITY),.25)
	#get_tree().create_timer(.75).timeout.connect(UI.start_timers)


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.
