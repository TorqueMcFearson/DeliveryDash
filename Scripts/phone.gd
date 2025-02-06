extends Panel

enum {OFF, ON}
var state = OFF
const PHONE_ON_SCALE = Vector2(2.4,2.6)
@onready var order_list: VBoxContainer = $Screen/Scrollbox/Order_List
@onready var PHONE_ON_POS = $Marker2D.global_position # Vector2(635,583)
const PHONE_OFF_SCALE = Vector2(1,1)
const PHONE_OFF_POS = Vector2(1075,583)
var tween :Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Blackout.show()
	tween = create_tween()
	tween.kill()
	$Screen/Notification.scale.y = 0
	scale = Vector2(1,1) # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if state == ON:
		if (event is InputEventMouseButton and event.button_index in [1]): 
			_phone_off()
			
func _input(event: InputEvent) -> void:
	if state == ON:
		if (event is InputEventMouseButton and event.button_index == 2): 
			_phone_off()
			
func add_order(order:Order):
	order.scrollposition.connect(update_scroll)
	$Screen/Scrollbox/Order_List.add_child(order)
	
func _phone_on():
	if tween.is_running():
		await tween.finished
	$ActiveOrderTimer.hide()
	$Blackout.set_disabled(true)
	$Blackout.mouse_filter = 2
	state = ON
	tween = create_tween()
	tween.tween_property(self,"scale",PHONE_ON_SCALE,.4)
	tween.parallel().tween_property(self,"position",PHONE_ON_POS,.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($Screen/Notification,"position",Vector2(813,90),.56).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($Blackout,"modulate",Color(1,1,1,0),.2)
	return tween.finished
	
func _phone_off():
	if tween.is_running():
		await tween.finished
	$Blackout.set_disabled(false)
	$Blackout.button_pressed = false
	tween = create_tween()
	for order in order_list.get_children():
		order.shrink_order()
	tween.tween_property(self,"scale",PHONE_OFF_SCALE,.5)
	tween.parallel().tween_property(self,"position",PHONE_OFF_POS,.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property($Screen/Notification,"position",Vector2(927,547),.5).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property($Blackout,"modulate",Color(1,1,1,1),.2)
	tween.tween_callback(_phone_off_callback)
	$ActiveOrderTimer.show()
	return tween.finished

func _phone_off_callback():
	$Blackout.mouse_filter = 0
	state = OFF
	
func update_orders():
	var orders = order_list.get_children()
	for order:Order in orders:
		order.get_distance()

#func check_pickups():
	#order_list.get_children().filter(func(order):order)
		
		
func update_scroll(pos:Vector2):
	$Screen/Scrollbox.scroll_vertical = pos.y
	
func blink():
	if state == OFF:
		var tween = create_tween()
		#var tween = create_tween().tween_property().as_relative()
		tween.tween_callback(func():$Blackout.button_pressed = true).set_delay(.1)
		tween.tween_callback(func():$Blackout.button_pressed = false).set_delay(.1)
		tween.tween_callback(func():$Blackout.button_pressed = true).set_delay(.1)
		tween.tween_callback(func():$Blackout.button_pressed = false).set_delay(.1)
		
		
		#tween.tween_property($Blackout,"modulate",Color(1,1,1,.75),.1)
		#tween.tween_property($Blackout,"modulate",Color(1,1,1,1),.1)
		
func bad_notification(message:String):
	#if state == OFF:
		#_phone_on() 
	
	$Screen/Notification.text = message
	$"Phone Bad Ding".play()
	var tween = create_tween()
	tween.tween_property($Screen/Notification,"scale",Vector2(.75,.9),.25)
	tween.tween_property($Screen/Notification,"scale",Vector2(0,.9),.25).set_delay(3)
