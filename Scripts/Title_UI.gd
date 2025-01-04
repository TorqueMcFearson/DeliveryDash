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
	#for button:Button in $MarginContainer/Buttons.get_children():
		#button.disabled = true
	
	var fade = get_tree().create_tween()
	
	UI.fade_out(1,get_tree().change_scene_to_packed.bind(CITY),.25)
	get_tree().create_timer(1.25).timeout.connect(UI.start_timers)


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.
