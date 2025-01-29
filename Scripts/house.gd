extends Node2D
signal t_house_drop
const CITY = preload("res://CityMain.tscn")
var bag_drop = false
const TUTORIAL_STAGE = 3 
var need_to_mark_order :Array[Order]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$Bag.modulate = Color(1,1,1,0)
	if UI.tutorial_stage(TUTORIAL_STAGE):
		UI.fade_in(1)
		UI.pause(TUTORIAL_STAGE)
		var t_house_update = UI.active_order.t_house_update
		var t_house_complete = UI.active_order.t_house_complete
		UI.give_tutorial_signals([t_house_drop,t_house_update,t_house_complete])
	else:
		if UI.tutorial < TUTORIAL_STAGE*10: UI.tutorial = TUTORIAL_STAGE*10
		UI.fade_in(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func drop_bag():
	need_to_mark_order.append(UI.active_order)
	$Bag/Receipt.text = "%s\nOrder# %s\n\n%s\n\n%s" % UI.active_order.bag.receipt
	$Bag.modulate = Color(1,1,1,1)
	bag_drop = true
	UI.active_order.drop_bag()
	t_house_drop.emit()

func _on_exit_pressed() -> void:
	if UI.day_over:return
	if UI.tween.is_valid():return
	if UI.find_child("Tutorial").playing_tutorial:return
	UI.location = ""
	get_tree().create_timer(4).timeout.connect(UI.check_forgot.bind(need_to_mark_order))
	UI.fade_out(.35,get_tree().change_scene_to_packed.bind(CITY),.25) # Replace with function body.

func _on_check_receipt() -> void:
	$Bag/Receipt/Check_Bag.disabled = true
	get_tree().create_timer(.5).timeout.connect(func():$Bag/Receipt/Check_Bag.disabled = false)
	if $Bag/Receipt.rotation == 0: # GO SMALL
		var tween = create_tween()
		tween.tween_property($Bag/Receipt,"scale",Vector2(0.14,0.21),.18)
		tween.parallel().tween_property($Bag/Receipt,"rotation_degrees",-10.4,.18)
	else: # GO Big
		var tween = create_tween()
		tween.tween_property($Bag/Receipt,"scale",Vector2(2,2),.18)
		tween.parallel().tween_property($Bag/Receipt,"rotation_degrees",0,.18)


func _on_button_pressed() -> void:
	if UI.active_order.house == UI.location:
		$Button.disabled = true
		drop_bag()


func _on_button_mouse_entered() -> void:
	if not bag_drop:
		$Bag.modulate = Color(1,1,1,.40)


func _on_button_mouse_exited() -> void:
	if not bag_drop:
		$Bag.modulate = Color(1,1,1,0) # Replace with function body.
