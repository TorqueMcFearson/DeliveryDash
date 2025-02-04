extends Control

const CITY = preload("res://CityMain.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UI.hide_UI()
	UI.fade_in()
	$Path2D/PathFollow2D.progress_ratio = 0
	create_tween().tween_property($Path2D/PathFollow2D,"progress_ratio",1,.75).set_trans(Tween.TRANS_CUBIC)
	var delay = .35
	var distance = -$Buttons.position
	for button in [$Buttons/Exit, $Buttons/Options, $Buttons/Start]:
		create_tween().tween_property(button,"position",distance,.45).as_relative().set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		delay += .25
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	for button in [$Buttons/Start, $Buttons/Options, $Buttons/Exit,]:
		button.disabled = true
	UI.fade_out(1,get_tree().change_scene_to_packed.bind(CITY),.25)
	get_tree().create_timer(4).timeout.connect(UI.unpause_timers)


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.
