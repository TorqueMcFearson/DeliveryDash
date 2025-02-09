extends Node2D
enum FOOD {WAITING=1,PICKED_UP=2,DELIVERED=3,WRONG_LOCATION=4}
const CITY = preload("res://CityMain.tscn")
const CORRECT_BAG_PVALUE = 10
const TUTORIAL_STAGE = 2
signal t_res_request
signal t_res_grab
var location:String
var foregrounds = {"Taco Hut":"res://Sprites/foreground_taco_hutt.png",
 				  "Wenny's":"res://Sprites/foreground_wenny's.png",
				  "IHOW":"res://Sprites/foreground_ihow.png", 
				  "Cajun Betty's":"res://Sprites/foreground_cajun_bettys.png", 
				  "Timmy Tom's":"res://Sprites/foreground_timmy_toms.png"}
var bagged_order:Order
var need_to_mark_order :Array[Order]
@onready var speech: Label = $Control/speech
@onready var request_order: Button = $Control/Request_Order
@onready var receipt: Label = $Control/Receipt
@onready var bag: Button = $Control/Bag
@onready var default_focus = request_order
@onready var ask_label: Label = $Control/ask_label


func _ready() -> void:
	location = UI.location
	UI.phone.scene_has_focus_nodes(true)
	
	if not location:
		location = "Cajun Betty's"
		print("ERROR: Location.UI was null when entering resturant.")
	$Foreground.texture = load(foregrounds[location])
	speech.text = ""
	ask_label.text = ""
	if UI.tutorial_stage(TUTORIAL_STAGE):
		UI.fade_in(.75) # Replace with function body.
		UI.pause(TUTORIAL_STAGE)
		var t_res_update = UI.active_order.t_res_update
		UI.give_tutorial_signals([t_res_request,t_res_grab,t_res_update])
	else:
		if UI.tutorial < TUTORIAL_STAGE*10: UI.tutorial = TUTORIAL_STAGE*10
		UI.fade_in(1)
	focus_from_phone()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not get_viewport().gui_get_focus_owner():
		default_focus.grab_focus()
		


func _on_exit_arrow_pressed() -> void: # button is EXIT
	if UI.day_over:return
	if UI.tween.is_valid():return
	if UI.find_child("Tutorial").playing_tutorial:return
	UI.location = ""
	get_tree().create_timer(4).timeout.connect(UI.check_forgot.bind(need_to_mark_order))
	UI.fade_out(.35,get_tree().change_scene_to_packed.bind(CITY),.25) # Replace with function body.

func make_bag(order:Order):
	var receipet
	var correct
	
	if true: #randi_range(0,3): # if 1,2,3 bag correct, if 0 bag incorrect goto else
		receipet = [order.resturant,order.order_num,order.customer,order.address]
		correct = true
	else:
		receipet = UI.generate_random_receipt()
		correct = false
	order.new_bag(order,receipet,correct)
	
func put_order_in_bag(order:Order):
	if not order.bag: # if no bag, construct one.
		make_bag(order)
	place_bag(order)
	
func place_bag(order):
	order.bag_cleared.connect(remove_bag)
	bagged_order = order
	receipt.text = "%s\nOrder# %s\n\n%s\n\n%s" % order.bag.receipt
	bag.show()
	receipt.show()
	
func remove_bag():
	receipt.text = ""
	bagged_order = null
	bag.hide()
	receipt.hide()
	
func _get_order() -> void: # Button
	request_order.disabled = true
	var res
	if UI.active_order:
		res = UI.active_order.pickup_food(location)
	else: 
		res = false
	
	var message:String
	match res:
		true: 
			message = "Here you go I guess..."
			put_order_in_bag(UI.active_order)
		false: message = "But like... what order...?"
		FOOD.PICKED_UP: message = "You already have it dude..."
		FOOD.DELIVERED: message = "Umm pretty sure that was already delivered..."
		FOOD.WRONG_LOCATION: message = "Dude, wrong store..are you new?"
	dialog(message)
	t_res_request.emit()
	
func dialog(message):
	speech.add_theme_color_override("font_color","black")
	speech.text = message
	get_tree().create_timer(2).timeout.connect(func():speech.text = "";request_order.disabled = false)
	
func correct_bag(order):
	UI.did_a_good(CORRECT_BAG_PVALUE)
	var receipet = [order.resturant,order.order_num,order.customer,order.address]
	var correct = true
	UI.new_bag(order,receipet,correct)
	remove_bag()
	get_tree().create_timer(1.25).timeout.connect(func():place_bag(order);dialog("Here.. this should be it.. probably..."))
	
func _on_wrong_order_pressed() -> void:
	$Control/Receipt/Wrong_Order.disabled = true
	if bagged_order.bag.correct:
		UI.made_a_mistake(CORRECT_BAG_PVALUE)
		dialog("Uhhh.. no.. it's correct. Look again...")
	else:
		dialog("Oh.. my bad. All these bags look the same...")
		correct_bag(bagged_order)

func _on_check_receipt() -> void:
	$Control/Receipt/Check_Bag.disabled = true
	get_tree().create_timer(.5).timeout.connect(func():$Control/Receipt/Check_Bag.disabled = false)
	if receipt.rotation == 0: # GO SMALL
		var tween = create_tween()
		tween.tween_property(receipt,"scale",Vector2(0.14,0.21),.18)
		tween.parallel().tween_property(receipt,"rotation_degrees",-10.4,.18)
		tween.tween_callback($Control/Receipt/Wrong_Order.hide)
	else: # GO Big
		var tween = create_tween()
		tween.tween_property(receipt,"scale",Vector2(1,1),.18)
		tween.parallel().tween_property(receipt,"rotation_degrees",0,.18)

func _on_take_bag() -> void:
	bagged_order.take_bag()
	need_to_mark_order.append(bagged_order)
	remove_bag()
	t_res_grab.emit()

func _on_bag_mouse_entered() -> void:
	$Control/Check.text = "Take Bag" # Replace with function body.

func _on_receipt_mouse_entered() -> void:
	if receipt.rotation != 0:
		receipt.scale = Vector2(0.16,0.23)
		$Control/Check.text = "Check Recipet" # Replace with function body.

func _on_receipt_mouse_exited() -> void:
	if receipt.rotation != 0:
		receipt.scale = Vector2(0.14,0.21)
		$Control/Check.text = "Take Bag" # Replace with function body.

func _on_bag_mouse_exited() -> void:
	$Control/Check.text = "" # Replace with function body.

func _on_request_order_mouse_entered() -> void:
	if not request_order.disabled:
		ask_label.add_theme_color_override("font_color","white")
		ask_label.text = "Ask for Order"
	pass # Replace with function body.

func _on_request_order_mouse_exited() -> void:
	if not request_order.disabled:
		ask_label.add_theme_color_override("font_color","white")
		ask_label.text = ""
	pass # Replace with function body.


func _on_to_phone_node_focus_entered() -> void:
	if not UI.phone.is_phone_on():
		await UI.phone._phone_on()
	UI.phone.give_order_focus()

func focus_from_phone():
	default_focus.grab_focus()
