extends CanvasLayer

# Cut Message
# Hurry if you want to afford rent and food at the end of the day!
# Just don't mess up or forget orders, and keep on delivering!
# (Hint: Gas stations are on yellow roads)

const ORDER = preload("res://order.tscn")
const _4_AM = preload("res://4_am.tscn")
@onready var order_list: VBoxContainer = $Phone/Screen/Scrollbox/Order_List
@onready var add_cash_pos = $UI/Panel/Cash/Add_Cash.position
@onready var phone: Panel = $Phone
@onready var gas_level: TextureProgressBar = $"UI/Gas Can/Gas Box/Gas Level"
@onready var gas_can: TextureRect = $"UI/Gas Can"


signal new_active_order_set(order:Order)
signal tween_complete
signal tutorial_change

class ClockTime:
	var hour: int
	var minute :int
	var time_up :Array
	
	func _init(xhour:int,xminute:int) -> void:
		hour = xhour
		minute = xminute
		time_up = [xhour+4,xminute] 
			
	func tick():
		minute += 1
		if minute == 60:
			minute = 0
			hour += 1
		if hour == 24:
			hour = 0
			
	func _get_ampm():
		return "AM" if hour < 12 else "PM"
		
	func get_time():
		var t_hour:String
		if hour == 0: t_hour = "12"
		elif hour > 12: t_hour = str(hour-12)
		else: t_hour = str(hour)
		var t_minute = minute
		return "%s:%02d %s" % [t_hour,t_minute,_get_ampm()]
		
	func is_time_up():
		return hour == time_up[0] and minute == time_up[1]
	func almost_time():
		return hour == 19 and minute > 29
class Building:
	var name:String
	var global_position:Vector2
	var idx: int
	var type: String
	
	func _init(name,global_position,idx,type) -> void:
		self.name = name
		self.global_position = global_position
		self.idx = idx
		self.type = type

## Play State ######################
@export var rating : float = 20.0
@export var cash :int = 10
var cash_to_add :int = 0
var tween_tracking:bool
var tip_to_add :int = 0
var clock = ClockTime.new(16,00)
var player_map_position : Vector2 =  PLAYER_HOME_SPAWN 
var stores : Array
var houses : Array
const PLAYER_HOME_SPAWN = Vector2(2785,2779)
const MAX_RATING = 100
const STAR_BAR_WIDTH = 170.0
const MAX_ORDERS = 3
const ORDER_MIN_TIME = 7
const ORDER_MAX_TIME = 13
const FORGOT_MARK_PICKUP_PVALUE = 6
var round_stats : Dictionary = {
	"Orders Accepted" : 0,
	"Orders Completed" : 0,
	"Orders Rejected" : 0,
	"Orders Neglected" : 0,
	"Orders Failed" : 0,
	"Cars Hit" : 0,
	"Mistakes Made" : 0,
	"Cash Earned" : 0,
	"Rating Change" : 0, 
	}

## Order Generation ######################
const first_names = [
	"James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
	"William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
	"Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa",
	"Matthew", "Betty", "Anthony", "Margaret", "Donald", "Sandra","Justin","Danielle","Jack","Jake","Cortney","Pat"]
const last_names = [
	"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
	"Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
	"Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White",
	"Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson","Thomas","Nash","Bias","Mitchell"] 
const street_names = [
	"Main", "Oak", "Maple", "Pine", "Cedar", "Elm", "Willow", "Birch", "Ash", "Spruce",
	"River", "Lake", "Hill", "Sunset", "Meadow", "Spring", "Forest", "Park", "Valley", "Garden",
	"Cherry", "Magnolia", "Hawthorn", "Sycamore", "Chestnut", "Walnut", "Aspen", "Cottonwood", "Bay", "Juniper"]
const street_types = ["St", "Ave", "Rd", "Blvd", "Dr", "Ln", "Way", "Ct", "Pl", "Terr"]

## Game Dynamics ######################
var active_order :Order
var location :String
var player_inventory :Array[Order]
enum T{STAGE0 = 0, STAGE1 = 10,STAGE2 = 20,STAGE3 = 30,STAGE4 = 40,STAGE5 = 50}
var tutorial := 1
var tutorial_enabled = true: 
	set(value):
		tutorial_enabled = value
		tutorial_change.emit()
@export var day = 1
@export var difficulty := 1.0
var tween :Tween 
var day_over:bool = false
var time_passed := 0.0
@export var speed_modifier := 1.0
@export var accel_modifier := 1.0
@export var max_fuel_modifier := 1.0:
	set(value):
		max_fuel_modifier = value
		set_gas_level()
@export var fuel_consume_modifier := 1.0
@export var bump_modifer := 1.0
@export var car_horn := false
@export var upgrade_levels = {
	"Strong Bumpers" : 0,
	"TuroCharge Engine" : 0,
	"Fuel Efficiency" : 0,
	"Fuel Tank Size" : 0,
	"Car Horn" : 0,
	}
## Gas Variables ######################
const GAS_COST = .5
const FUEL_WARNING_LEVEL = 25
var gas_inflation = 0.05
var gas_tween:Tween
var max_fuel := 50.0:
	get():
		return max_fuel * max_fuel_modifier

var gas := 45.0:
	set(value):
		gas = clampf(value,0,max_fuel)
		gas_level.value = gas
		if gas == 0:
			out_of_gas()

var fuel_rate:=.92:
	get():
		return fuel_rate * UI.fuel_consume_modifier
var debug_dictionary := {"Fuel Spend": 0,}
var gas_label_pos = Vector2(-14,-151)
var upgrades = {}


func _ready() -> void:
	gas_level.value = gas
	set_gas_level()
	$Tutorial.hide()
	$Fader.show()
	pause_timers()
	$UI/Panel/STAR_BAR.size.x = (rating/MAX_RATING) * STAR_BAR_WIDTH
	$UI/Panel/Time.text = clock.get_time()
	fade_in() # Replace with function body.
	get_tree().create_timer(1).timeout.connect(test_UI_functions)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().current_scene.name == "Title":
		$"Pause Dimmer".show()
		$"Controls".show()
		get_tree().paused=true
		if not UI.tutorial_stage(0):
			show_pause_menu()
		show_tutorial()

func _process(delta: float) -> void:
	gas_can_effects(delta)
	clock_effects(delta)

func gas_can_effects(delta):
	$"UI/Gas Can".scale = Vector2(1,1)
	if gas > FUEL_WARNING_LEVEL:
		$"UI/Gas Can".modulate = Color(1, 1, 1,1)
	elif gas > 0:
		var strength = 1-(gas/FUEL_WARNING_LEVEL)
		time_passed += delta
		var blink_str = .7*strength
		var blink = 1-blink_str + blink_str * sin(time_passed * 8) 
		var color = $"UI/Gas Can".modulate
		color.b = blink
		color.g = blink
		color.r = 1.0
		color.a = 1.0
		$"UI/Gas Can".modulate = color
		if gas < FUEL_WARNING_LEVEL *0.5 and not gas_tween:
			var n_scale = 1 + .1*strength * sin(time_passed * 8)
			$"UI/Gas Can".scale = Vector2(n_scale,n_scale)
	else:
		$"UI/Gas Can".modulate = Color(0.753, 0.843, 1,0.75)

func clock_effects(delta):
	if clock.almost_time():
		time_passed += delta
		var blink = .65 + .35 * sin(time_passed * 6) 
		var color = $UI/Panel/Time.modulate
		color.b = blink
		color.g = blink
		color.r = 1.0
		$UI/Panel/Time.modulate = color
	else:
		$UI/Panel/Time.modulate = Color(1, 1, 1)
		
func show_tutorial():
	$Tutorial.show()
	
func hide_tutorial():
	$Tutorial.hide()
	
func tutorial_stage(x):
	return tutorial_enabled and tutorial < T["STAGE"+str(x)]+10

func give_tutorial_signals(signals):
	$"Tutorial".setup_tutorial_signals(signals)
		
func tutorial_phone(_stage:int):
	await phone._phone_on()
	pause(_stage)
	
func pause(run_tutorial_stage = null):
	$"Pause Dimmer".show()
	$"Controls".show()
	get_tree().paused=true
	if run_tutorial_stage == null:
		show_pause_menu()
	if get_tree().current_scene.name != "4 AM" and UI.tutorial_enabled:
		show_tutorial()
	if run_tutorial_stage != null:
		$Tutorial.play_tutorial(run_tutorial_stage)
	
func show_pause_menu():
	$"Options".get_child(0).pause()

func test_UI_functions():
	#add_cash(120,0)
	#get_tree().create_timer(5).timeout.connect(end_day)
	#get_tree().create_timer(.5).timeout.connect(add_cash.bind(2,20)) 
	#did_a_good(30)
	pass

func fade_in(duration=1.0,callback=null,delay=.25):
	tween = create_tween()
	tween.tween_property($Fader,"modulate",Color(1,1,1,0),duration)
	if callback:tween.tween_callback(callback).set_delay(delay)
	return tween.finished
	
func fade_out(duration=.5,callback=null,delay=.25):
	tween = create_tween()
	tween.tween_property($Fader,"modulate",Color(1,1,1,1),duration)
	if callback:tween.tween_callback(callback).set_delay(delay)
	return tween.finished
	
func hide_UI():
	$UI.hide()
	$Phone.hide()
	
func show_UI():
	$UI.show()
	$Phone.show()

func update_clock():
	$UI/Panel/Time.text = clock.get_time()
	if clock.is_time_up():
		var player = get_tree().current_scene.find_child("Player")

		$Respawning.text = "Day Over... Driving Home"
		$Respawning.show()
		end_day()
		$Respawning.hide()

		
func _on_clock_tick() -> void:
	clock.tick()
	update_clock()
	update_order_timers()
	
	
func unpause_timers():
	for timer in [$ClockTick, $Order_Update, $New_Order_Timer]:
		timer.paused = false
		
func pause_timers():
	for timer in [$ClockTick, $Order_Update, $New_Order_Timer]:
		timer.paused = true
		
func end_day():
	day_over = true
	phone._phone_off()
	pause_timers()
	if tween: tween.kill()
	var tween2 = create_tween()
	tween2.tween_property($Music,"volume_db",-50,1.8)
	tween2.tween_callback(func():$Music.stream = load("res://SFX/lofi-boy-night-waves-lofi-relax-instrumental-278248.mp3");$Music.play())
	tween2.tween_property($Music,"volume_db",-14,.75)
	
	for order in order_list.get_children():
		order.queue_free()
	await fade_out(2,get_tree().change_scene_to_packed.bind(_4_AM))
	
func to_main_menu():
	pause_timers()
	if tween: tween.kill()
	reset()
	unpause()
	fade_out(.25,get_tree().change_scene_to_packed.bind(load("res://Title_Screen.tscn")))

func unpause():
	$Tutorial.unpause()
	
func generate_customer():
	return first_names.pick_random() + ' ' + last_names.pick_random()
	
func generate_address():
	return "%d %s %s %s" % [randi_range(100,9999),["N","W","S","E"].pick_random(),street_names.pick_random(),street_types.pick_random()]
	
func generate_order() -> Order:
	var new_order = ORDER.instantiate()
	var customer = generate_customer()
	var store = stores.pick_random()
	var house = houses.pick_random()
	var address = generate_address()
	new_order.init(customer,store,house,address)
	new_order.new_active.connect(update_new_active_order)
	return new_order
	
func generate_random_receipt(): #[order.customer,order.resturant,order.address]
	return [stores.pick_random(),randi_range(1,99),generate_customer(),generate_address(),]
	
func new_order() -> Order:
	var new_order = generate_order()
	$Phone.add_order(new_order)
	if UI.tutorial_stage(1):
			get_tree().create_timer(.75).timeout.connect(tutorial_phone.bind(1))
	elif UI.tutorial < 20: UI.tutorial = 20
	return new_order

func start_timers():
	$ClockTick.start()
	$Order_Update.start()
	#$New_Order_Timer.start()
	
func _on_order_update_timeout() -> void:
	$Phone.update_orders() # Replace with function body.
	
	
func get_stores(stores):
	var idx = 0
	for store in stores:
		self.stores.append(Building.new(store.name,store.global_position,idx,"store"))
		idx +=1
	

func get_houses(houses):
	var idx = 0
	for house in houses:
		self.houses.append(Building.new(house.name,house.global_position,idx,"house"))
		idx +=1
		
func order_timer_timeout():
	if order_list.get_child_count() < MAX_ORDERS:
		$"Phone Ding".play()
		$Phone.blink()
		new_order()
		new_order_timer_update()
		
	
func order_timer_start(): 
	$New_Order_Timer.start(randi_range(2,4))
	
func new_order_timer_update():
	var order_count:int = order_list.get_child_count()
	if not order_count:
		$New_Order_Timer.start(randi_range(1,5))
	else:
		$New_Order_Timer.start(randi_range(ORDER_MIN_TIME*order_count,ORDER_MAX_TIME*order_count))
		print("Time til next order: ",$New_Order_Timer.wait_time," secs.")
		
func get_order(idx :int):
	return order_list.get_child(idx)

func update_new_active_order(order:Order): #this fires when the active order leaves the tree..
	active_order = order
	new_active_order_set.emit(order)
	
func update_order_timers():
	for order in order_list.get_children():
		order.update_time()
	if active_order:
		var timeleft = active_order.timeleft
		var mins = int(timeleft /60)
		var secs = timeleft % 60
		$Phone/ActiveOrderTimer.text = "%02d:%02d LEFT!" % [mins,secs]
	else:
		$Phone/ActiveOrderTimer.text = ""

func made_a_mistake(value): 
	UI.round_stats["Rating Change"] -= value
	UI.round_stats["Mistakes Made"] += 1
	var spawn_point = $UI.get_global_mouse_position()
	rating = clamp(rating - value,0,100) 
	$FlyingStar/star_label.text = "-"
	$FlyingStar.modulate = Color("red")
	tween_star(spawn_point)
	
func did_a_good(value): 
	var spawn_point = $UI.get_global_mouse_position()
	UI.round_stats["Rating Change"] += value
	rating = clamp(rating + value,0,100)
	$StarGain.play()
	$FlyingStar/star_label.text = "+"
	$FlyingStar.modulate = Color("white")
	tween_star(spawn_point)

func tween_star(spawn_point):
	var fs :TextureRect = $FlyingStar
	var star_tween:Tween = create_tween()
	fs.scale = Vector2.ZERO
	fs.global_position = spawn_point
	star_tween.tween_property(fs,"scale",Vector2(1,1),.2)
	star_tween.tween_property(fs,"global_position",$UI/Panel/STAR_BAR/STAR3.global_position,.5).set_delay(.3)
	star_tween.parallel().tween_property(fs,"scale",Vector2.ZERO,.1).set_delay(.7)
	star_tween.tween_callback(tween_rating)
	
	
	#star_tween.tween_property($UI/FlyingStar,"scale")
func tween_rating():
	
	var ratio = (float(rating)/MAX_RATING)
	var size =  Vector2(STAR_BAR_WIDTH * ratio,$UI/Panel/STAR_BAR.size.y)
	create_tween().tween_property($UI/Panel/STAR_BAR,"size",size,.5)
	
func add_cash(value,tip):
	UI.round_stats["Cash Earned"] += value + tip
	$Cash_Noise.volume_db = 0
	$Cash_Noise.pitch_scale = 1
	if tween_tracking:
		await tween_complete
		await get_tree().create_timer(.5).timeout
	tween_tracking = true
	cash_to_add = value
	tip_to_add = tip
	$UI/Panel/Cash/Add_Cash.text = "+$"+str(cash_to_add)
	$UI/Panel/Cash/Add_Cash/Add_Tip.text = "+$"+str(tip_to_add) + " TIP"
	var tween = create_tween()
	tween.tween_property($UI/Panel/Cash/Add_Cash,"position",Vector2(add_cash_pos.x,$UI/Panel/Cash/L_Cash.position.y),.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(animate_cash).set_delay(.18)
	
func animate_cash():
	if cash_to_add:
		$Cash_Noise.pitch_scale = 1.0-cash_to_add*.01
		$Cash_Noise.volume_db -= 2
		var tween2 = create_tween().set_loops(cash_to_add)
		tween2.tween_callback(cash_count)
		tween2.tween_interval(.045)
		tween2.finished.connect(func():get_tree().create_timer(.3).timeout.connect(animate_tip))
	else:
		get_tree().create_timer(.3).timeout.connect(animate_tip)
	
func animate_tip():
	if tip_to_add:
		$Cash_Noise.pitch_scale += .2
		$Cash_Noise.volume_db += 1
		var tween2 = create_tween().set_loops(tip_to_add)
		tween2.tween_callback(tip_count)
		tween2.tween_interval(.045)
		tween2.finished.connect(func():$UI/Panel/Cash/Add_Cash.position = add_cash_pos; tween_tracking = false; tween_complete.emit())
	else:
		$UI/Panel/Cash/Add_Cash.position = add_cash_pos
		tween_tracking = false
		tween_complete.emit()
	
func cash_count():
	cash_noise(cash_to_add)
	cash +=1
	$UI/Panel/Cash/L_Cash.text = "$"+str(cash)
	cash_to_add -=1
	$UI/Panel/Cash/Add_Cash.text = "+$"+str(cash_to_add)
	
func tip_count():
	cash_noise(tip_to_add)
	cash +=1
	$UI/Panel/Cash/L_Cash.text = "$"+str(cash)
	tip_to_add -=1
	$UI/Panel/Cash/Add_Cash/Add_Tip.text = "+$"+str(tip_to_add)+ " TIP"

func cash_noise(to_add):
	$Cash_Noise.volume_db += 2/to_add
	$Cash_Noise.pitch_scale += .01
	$Cash_Noise.play()

func cash_decrease(to_sub):
	cash -= to_sub
	debug_dictionary["Fuel Spend"] += to_sub
	$Cash_Noise.play()
	$UI/Panel/Cash/L_Cash.text = "$"+str(cash)
	
func complete_order(order):
	var reward = order.reward
	var tip = order.reward * rating * .015
	did_a_good(8)
	await get_tree().create_timer(1.5).timeout
	add_cash(reward,tip) 

func check_forgot():
	var is_forgot = func (order:Order):return order.state != order.food_status and order.state != Order.NEW
	var forgotten :Array = order_list.get_children().filter(is_forgot)
	if forgotten:
		for order in forgotten:
			order.progress_order()
		UI.phone.bad_notification("You forgot to update the status!");
		UI.made_a_mistake(len(forgotten) * FORGOT_MARK_PICKUP_PVALUE)

func order_expired(): #TODO i have no idea what this is for..
	pass
	
func new_day():
	set_rating(rating - 10)
	day += 1
	location = ""
	player_map_position =  PLAYER_HOME_SPAWN 
	clock = ClockTime.new(16,00)
	round_stats = {
	"Orders Accepted" : 0,
	"Orders Completed" : 0,
	"Orders Rejected" : 0,
	"Orders Neglected" : 0,
	"Orders Failed" : 0,
	"Cars Hit" : 0,
	"Mistakes Made" : 0,
	"Cash Earned" : 0,
	"Rating Change" : 0,
	} 
	debug_dictionary["Fuel Spend"] = 0
	phone._phone_off()
	
func reset():
	for order in order_list.get_children():
		order.queue_free()
	day = 1
	active_order = null
	location = ""
	set_rating(20)
	set_cash(10)
	cash_to_add = 0
	tween_tracking = false
	tip_to_add = 0
	clock = ClockTime.new(16,00)
	player_map_position =  PLAYER_HOME_SPAWN 
	round_stats = {
	"Orders Accepted" : 0,
	"Orders Completed" : 0,
	"Orders Rejected" : 0,
	"Orders Neglected" : 0,
	"Orders Failed" : 0,
	"Cars Hit" : 0,
	"Mistakes Made" : 0,
	"Cash Earned" : 0,
	"Rating Change" : 0, 
	} 
	phone._phone_off()

func _on_texture_button_toggled(toggled_off: bool) -> void:
	if toggled_off:
		$Music.volume_db = -80 # Replace with function body.
	else:
		$Music.volume_db = -14

func set_cash(value):
	cash = value
	$UI/Panel/Cash/L_Cash.text = "$" + str(value)
	
func set_rating(value):
	rating = value
	var ratio = (float(rating)/MAX_RATING)
	$UI/Panel/STAR_BAR.size.x =  STAR_BAR_WIDTH * ratio


func consume_gas(delta):
	gas -= fuel_rate*delta

func out_of_gas():
	var player = get_tree().current_scene.find_child("Player")
	if player: player.out_of_gas()
	
		
	
	
func get_gas():
	if gas_tween: gas_tween.kill()
	get_tree().current_scene.find_child("Player").restore_speed_no_gas()
	gas_tween = create_tween()
	gas_tween.tween_property(gas_can,"position",$"UI/Gas Focus".position,.25)

func get_gas_tick(gas_added):
	var cost = get_cost(gas_added)
	print("cost: ",cost)
	%"Gas Cost".text = "-$"+str(int(cost))
	
func stop_gas(gas_added):
	if gas_tween: gas_tween.kill()
	gas_tween = create_tween()
	gas_tween.tween_property(gas_can,"position",$"UI/Gas Unfocus".position,.25)
	gas_tween.tween_callback(func():gas_tween = null)
	if gas_added:
		var gpos = %"Gas Cost".global_position
		%"Gas Cost".set_as_top_level(true)
		var tween2 := create_tween() 
		tween2.tween_property(%"Gas Cost","global_position",$Tutorial/Money/L_Cash.position,.42).from(gpos)
		await tween2.finished
		cash_decrease(get_cost(gas_added))
		%"Gas Cost".set_as_top_level(false)
		%"Gas Cost".position = gas_label_pos
	%"Gas Cost".text = ""

func money_for_gas(gas_added,gas_add_rate):
	return get_cost(gas_added+gas_add_rate) <= cash

func get_cost(gas_added):
	print(gas_added * (GAS_COST + day*gas_inflation))
	return gas_added * (GAS_COST + day*gas_inflation)
	
func set_gas_level():
	gas_level.custom_minimum_size = Vector2(gas_level.custom_minimum_size.x,max_fuel)
	gas_level.max_value = max_fuel
	gas_label_pos.y = -50 - max_fuel
	%"Gas Cost".position = gas_label_pos

func play_sfx():
	$Cash_Noise.play()
