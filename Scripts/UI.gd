extends CanvasLayer

const ORDER = preload("res://order.tscn")
const _4_AM = preload("res://4_am.tscn")
@onready var order_list: VBoxContainer = $Phone/Screen/Scrollbox/Order_List
@onready var add_cash_pos = $UI/Panel/Cash/Add_Cash.position
@onready var phone: Panel = $Phone

signal new_active_order_set(order:Order)
signal tween_complete
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

var rating : float = 20.0
var cash :int = 10
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

var active_order :Order
var location :String
var player_inventory :Array[Order]
var tutorial = true
var day = 1
var tween :Tween = Tween.new()
var day_over:bool = false

func _ready() -> void:
	$Tutorial.hide()
	$Fader.show()
	pause_timers()
	$UI/Panel/STAR_BAR.size.x = (rating/MAX_RATING) * STAR_BAR_WIDTH
	$UI/Panel/Time.text = clock.get_time()
	fade_in() # Replace with function body.
	get_tree().create_timer(1).timeout.connect(test_UI_functions)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and get_tree().current_scene.name != "Title":
		if phone.state: 
			await phone._phone_off()
		
		get_tree().paused=true
		show_tutorial()
		
func show_tutorial():
	$Tutorial.show()
		
func test_UI_functions():
	#add_cash(120,0)
	#get_tree().create_timer(5).timeout.connect(end_day)
	#get_tree().create_timer(.5).timeout.connect(add_cash.bind(2,20)) 
	#did_a_good(30)
	pass

func fade_in(duration=1,callback=null,delay=.25):
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
		end_day()

		
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
	fade_out(2,get_tree().change_scene_to_packed.bind(_4_AM))
	
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
	var default_pos = fs.global_position 
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
	
func reset():
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
