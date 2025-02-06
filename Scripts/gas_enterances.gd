extends Area2D

@onready var gas_timer: Timer = $Gas_guzzle
@onready var gas_click: AudioStreamPlayer = $Gas_Click
@onready var def_wait = gas_timer.wait_time
@onready var def_pitch = gas_click.pitch_scale
var gas_added := 0.00
var gas_add_rate := 2.5


func _on_body_entered(_body: Node2D) -> void:
	if UI.gas < 90 and UI.cash:
		UI.gas = snapped(UI.gas,5.0)
		gas_click.pitch_scale = (UI.gas/100) +.5
		gas_timer.start()
		UI.get_gas()


func _on_gas_guzzle_timeout() -> void:
	if UI.get_cost(gas_added) == UI.cash:
		prints("No Money!",UI.gas)
		_on_body_exited(null)
	elif UI.gas < UI.max_fuel: 
		gas_click.play()
		UI.gas += gas_add_rate
		gas_added += gas_add_rate
		UI.get_gas_tick(int(gas_added))
		gas_timer.wait_time = lerp(gas_timer.wait_time,.1 * UI.gas_fill_speed_mod,.15)
		gas_click.pitch_scale =lerp(gas_click.pitch_scale,3.0,.15)
		prints("Getting Gas!",UI.gas) # Replace with function body.
	else:
		prints("Gas FULL!",UI.gas)
		_on_body_exited(null)
	
	


func _on_body_exited(body: Node2D) -> void:
	UI.stop_gas(int(gas_added))
	gas_timer.stop()
	gas_timer.wait_time = def_wait
	gas_click.pitch_scale = def_pitch
	gas_added = 0.00
	prints("stopping",body)
	
