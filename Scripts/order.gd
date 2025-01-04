class_name Order
extends PanelContainer
class Bag:
	var order:Order
	var receipt:Array
	var correct:bool
	func _init(order,receipt,correct) -> void:
		self.order = order
		self.receipt = receipt
		self.correct = correct

@onready var order_expand: MarginContainer = $HBoxContainer2/Order_Expand
@onready var expand_content: VBoxContainer = $HBoxContainer2/Order_Expand/More_Details
static var order_next :int = 1
signal bag_cleared
signal scrollposition(pos:Vector2)
signal new_active(order:Order)
enum {NEW,TO_STORE,TO_HOUSE,DELIVERED}
enum FOOD {WAITING=1,PICKED_UP=2,DELIVERED=3,WRONG_LOCATION=4}
enum {NONE,HOVER,CLICKED}
const FORGOT_UPDATE_PVALUE = 3
var food_status :FOOD = FOOD.WAITING
var state:
	set(value):
		state = value
		update_state()
				
var order_num:int
var customer:String
var resturant: String
var resturant_pos:Vector2
var resturant_idx:int
var house :String
var house_pos : Vector2
var house_idx : int
var address:String
var store_to_house_dist : int
var reward : int
var select_state = NONE
var active : bool = false
var timeleft : int
var bag:Bag
var forgot_pickup = false
var forgot_delivery = false

func _ready() -> void:
	state = NEW
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func init(customer:String,resturant,house,address):
	self.order_num = order_next
	order_next +=1
	self.customer = customer
	self.resturant = resturant.name
	self.resturant_pos = resturant.global_position
	self.resturant_idx = resturant.idx
	self.house = house.name
	self.house_pos = house.global_position
	self.house_idx = house.idx
	self.address = address
	self.store_to_house_dist = int(resturant_pos.distance_to(resturant_pos)/100)

#func _unhandled_key_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept"):
		#progress_order()
		
func progress_order():# NEW,TO_STORE,TO_HOUSE,DELIVERED
	match state: #Check current state
		NEW:
			pass
		TO_STORE: # If picking up
			if food_status != FOOD.PICKED_UP:
				UI.phone.bad_notification("You haven't picked up the order yet!")
				if not forgot_pickup:
					UI.made_a_mistake(FORGOT_UPDATE_PVALUE)
					forgot_pickup = true
				return
		TO_HOUSE:
			if food_status != FOOD.DELIVERED:
				UI.phone.bad_notification("You haven't delivered the order yet!")
				if not forgot_delivery:
					UI.made_a_mistake(FORGOT_UPDATE_PVALUE)
					forgot_delivery = true
				return
		DELIVERED:
				complete_order()
	state = (state + 1)
	
func complete_order():
	UI.round_stats["Orders Completed"] += 1
	UI.complete_order(self)
	queue_free()
	
func update_state(): #Called whenever the state changes
	match state: # NEW,TO_STORE,TO_HOUSE,DELIVERED
		NEW:
			$HBoxContainer/Basket.hide()
			$HBoxContainer/House.hide()
			$Status.text = "New!"
			$Target.text = "#"+str(order_num)+" | " + resturant
			$Status.modulate=Color(0, 0.086, 1)
			$HBoxContainer2/VBoxContainer/Accept.show()
			$HBoxContainer2/VBoxContainer/Reject.show()
			$HBoxContainer2/Order_Expand/More_Details/HBoxContainer/Resturant.text = resturant
			$HBoxContainer2/Order_Expand/More_Details/HBoxContainer2/OrderNum.text = "Order #" + str(order_num)
			$HBoxContainer2/Order_Expand/More_Details/HBoxContainer3/Customer.text = customer
			$HBoxContainer2/Order_Expand/More_Details/HBoxContainer4/Address.text = address
		TO_STORE:
			$Reward.text = ""
			$HBoxContainer/Basket.show()
			$HBoxContainer/House.hide()
			$Status.text = "Picking up..."
			$Target.text = "#"+str(order_num)+" | " + resturant
			$Status.modulate=Color(1, 0.65, 0.199)
			$"HBoxContainer2/VBoxContainer/Progress".show()
			$"HBoxContainer2/VBoxContainer/Progress".text = "mark as picked up"
			$"HBoxContainer2/Order_Expand/TimeLeftBox/Until Order Expires".text = "Complete delivery in:"
		TO_HOUSE:
			$HBoxContainer/Basket.hide()
			$HBoxContainer/House.show()
			$Status.text = "Delivering..."
			$Target.text = "#"+str(order_num)+" | " +address
			$Status.modulate=Color(1, 0.915, 0.15)
			$"HBoxContainer2/VBoxContainer/Progress".text = "Mark as Delivered"
		DELIVERED: 
			$HBoxContainer/Basket.hide()
			$HBoxContainer/House.hide()
			$HBoxContainer2/Order_Expand/TimeLeftBox.hide()
			$Target.text = "Order Complete!"
			var tip = reward * UI.rating * .015
			$Status.text = "$%d + $%d TIP = $%d" % [reward, tip,reward+tip] 
			$Status.modulate=Color(1, 0.867, 0)
			$"HBoxContainer2/VBoxContainer/Progress".text = "Collect Pay"
			
	var dist = get_distance()
	if state == NEW: 
		if not reward:
				reward = int(randi_range(2,12) + dist/2)
		if not timeleft:
			timeleft = (randi_range(15,40))
			update_time()
		$Reward.text = "$"+str(reward)
		$Reward.modulate = Color("gold")
		return	
	elif state == TO_STORE:
		timeleft = (int(dist/10)+randi_range(3,5))*22
		update_time()
	if active:
		new_active.emit(self)
	
func activate():
	for order in get_parent().get_children():
		order.deactivate()
	active = true
	add_theme_stylebox_override("panel",load("res://StyleBoxes/order_entry_active.tres"))
	$HBoxContainer2/VBoxContainer/Progress.show()
	#$HBoxContainer2/VBoxContainer/Set_Active.hide() TEST
	new_active.emit(self)

func deactivate():
	add_theme_stylebox_override("panel",load("res://StyleBoxes/order_entry.tres"))
	if state != NEW:
		active = false
		$HBoxContainer2/VBoxContainer/Progress.hide()
		#$HBoxContainer2/VBoxContainer/Set_Active.show()

func get_distance():
	var dist
	match state: # NEW,TO_STORE,TO_HOUSE,DELIVERED
		DELIVERED: 
			$HBoxContainer/Distance.text = ""
			return
		NEW: 
			dist = get_distance_from_player(resturant_pos) + store_to_house_dist
			
		TO_STORE: dist = get_distance_from_player(resturant_pos)
		TO_HOUSE: dist = get_distance_from_player(house_pos)
	$HBoxContainer/Distance.text = str(dist) + " m"
	return dist

func update_time():
	if state == DELIVERED:
		return
	timeleft -= 1
	if timeleft < 1:
		$HBoxContainer2/Order_Expand/TimeLeftBox/TimeLeft.text = "Expired!"
		order_expired()
	else:
		timeleft
		var mins = int(timeleft /60)
		var secs = timeleft % 60
		$HBoxContainer2/Order_Expand/TimeLeftBox/TimeLeft.text = "%01d:%02d" % [mins,secs]
		
func get_distance_from_player(target :Vector2):
	var root = get_tree().current_scene
	var dist = 69
	if root and root.name == "City":
		var player : CharacterBody2D = root.find_child("Player",false)
		dist = player.global_position.distance_to(target)
	else:
		dist = UI.player_map_position.distance_to(target)
	dist = int(dist/100)
	return dist

func _on_order_select_pressed() -> void:
	if order_expand.custom_minimum_size.y:
		shrink_order()
	else:
		expand_order()
		
func shrink_order():
	self_modulate = Color(1,1,1,1)
	order_expand.custom_minimum_size.y = 0
	expand_content.hide()
	
func expand_order():
	for order in get_parent().get_children():
		order.shrink_order()
	self_modulate = Color(0.568, 0.52, 1, 0.651)
	order_expand.custom_minimum_size.y = 300
	expand_content.show()
	scrollposition.emit(position)

func _on_accept_pressed() -> void:
	UI.round_stats["Orders Accepted"] += 1
	$HBoxContainer2/VBoxContainer/Accept.queue_free()
	$HBoxContainer2/VBoxContainer/Reject.queue_free()
	progress_order()
	if get_parent().get_children().any(func(order):return order.active): # non-active if active order, 
		deactivate()
	else:                                                                # otherwise make this active.
		activate()
	
func pickup_food(location:String): 
	if location != resturant: return FOOD.WRONG_LOCATION
	match food_status: 
		FOOD.WAITING: 
			return true
		_: return food_status
		
func new_bag(order,receipet,correct):
	bag = Bag.new(order,receipet,correct)
	
func clear_bag():
	bag_cleared.emit()
	bag = null

func take_bag():
	food_status = FOOD.PICKED_UP
	
func drop_bag():
	food_status = FOOD.DELIVERED
	
func _on_reject_pressed() -> void:
	UI.round_stats["Orders Rejected"] += 1
	UI.phone.bad_notification("Don't Reject too many orders...")
	UI.made_a_mistake(2)
	queue_free()

func _on_progress_order_pressed() -> void:
	progress_order()
	
		
func order_expired():
	if state == NEW:
		UI.round_stats["Orders Neglected"] += 1
		UI.phone.bad_notification("Failed to Respond to Requests")
		UI.made_a_mistake(5)
	else:
		UI.round_stats["Orders Failed"] += 1
		UI.phone.bad_notification("You Failed to Deliver on Time!")
		UI.made_a_mistake(10)
	queue_free()
	
func _on_tree_exited() -> void:
	if self.active:
		print("active deleted!")
		var order = null
		for xorder in UI.order_list.get_children():
			if xorder.can_become_active():
				order = xorder
				break
		if order: 
			order.activate() 
		else:
			new_active.emit(null)
	UI.new_order_timer_update() # Replace with function body.

func _button_pressed():
	$"Phone Click".play()

func can_become_active(): #{NEW,TO_STORE,TO_HOUSE,DELIVERED}
	return not active and not state == NEW

func _on_select_order_header() -> void:
	if can_become_active():
		activate() # Replace with function body.
