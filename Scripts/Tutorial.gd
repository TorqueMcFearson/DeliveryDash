extends Control

@onready var ts_nodes :Array[Label] = [$Phone, $Time, $Money, $Rating, $"Gas Text"]
@onready var click_label = $"Click To Continue"
enum T{INTRO,NEW_ORDER,RESTURANT,HOUSE}
const COMPLETE_MESSAGE = " - Click to Resume - "
const TUTORIAL_POS = {10: Vector2(494,207),
					  11: Vector2(504,260),
					  12: Vector2(633,225),
					  13: Vector2(504,240),
					  20: Vector2(280,317),
					  21: Vector2(84,330),
					  22: Vector2(541,238),}
const TUTORIAL_MESSAGES = { 10: "Sweet gainful employment, you got an order!",
							11: "Don't ignore these or your boss will dock your rating big time!",
							12: "if your overwhelmed, rejecting is only a tiny hit to your rating",
							13: "Press Accept, and let's start our 1st delivery!",
							20: "Time to get our food. Ask this guy for it.",
							21: "Don't forget to take the bag!",
							22: "Don't forget to update the order status!\n Click this and let's get moving!",}
var playing_tutorial := false
var stage = 0
var click_to_continue := true
var connected_signals :Array
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_all()

func _input(event: InputEvent) -> void:
	if not get_tree().paused: return
	if playing_tutorial and event.is_pressed() and event is InputEventMouseButton \
	or event.is_action_pressed("pause"):
		if playing_tutorial:
			if click_to_continue:
				progress_tutorial()
		else:
			unpause()

func unpause():
	print("UNPAUSE")
	$"../Pause Dimmer".hide()
	$"../Controls".hide()
	get_viewport().set_input_as_handled()
	$"../Options".get_child(0).unpause()
	self.hide()
	set_continue_text(null,"-Game Paused-")
	#queue_free()
	get_tree().paused = false

func progress_tutorial():
	match stage:
		T.INTRO:
			if UI.tutorial == len(ts_nodes):
				set_continue_text()
				for label in ts_nodes: 
					label.show()
				UI.tutorial += 1
			elif UI.tutorial > len(ts_nodes):
				UI.tutorial = UI.T.STAGE1
				return stage_done()
			else:
				var p_node =  ts_nodes[UI.tutorial-1]
				var node = ts_nodes[UI.tutorial]
				p_node.hide()
				set_continue_text(node)
				node.show()
				
				
		T.NEW_ORDER: # Run When an the first order is recieved.
			var message = TUTORIAL_MESSAGES.get(UI.tutorial)
			if message:
				$Phone2.text = message
				$Phone2.size.y = 0
				$Phone2.position = TUTORIAL_POS.get(UI.tutorial)
				if TUTORIAL_MESSAGES.get(UI.tutorial+1):
					set_continue_text($Phone2)
				else:
					click_label.hide()
					$"CanvasLayer".show()
					return
				
				
		T.RESTURANT:
			var text_label = $Phone2
			if UI.tutorial == 22:
				text_label.hide()
				await UI.phone._phone_on()
				text_label.show()
			var message = TUTORIAL_MESSAGES.get(UI.tutorial)
			if message:
				text_label.text = message
				text_label.size.y = 0
				text_label.position = TUTORIAL_POS.get(UI.tutorial)
				if UI.tutorial == 22:
					text_label.position += UI.active_order.position*.6
			else:
				stage_done()

		
		
		T.HOUSE:pass
		
		
		4:pass
		5:pass
		
	UI.tutorial += 1

func set_continue_text(node=null,label_text = "Click to Continue"):
	click_label.text = "Click to Resume"
	if node:
		click_label.position = node.position + node.size - Vector2(click_label.size.x+4,12)
	else:
		click_label.position = get_viewport_rect().get_center()-Vector2(click_label.size.x/2,0)
		
func stage_done():
	UI.tutorial = (stage+1)*10
	hide_all()
	playing_tutorial = false
	unpause()
	
func play_tutorial(stage:int):
	playing_tutorial = true
	self.stage = stage
	$"Click To Continue".show()
	match stage: #Ready the tutorial
		T.INTRO: 
			$Phone.show()
			
			
		T.NEW_ORDER: # Run When an the first order is recieved.
			$Phone2.show()
			progress_tutorial()
			
			
		T.RESTURANT:
			UI.tutorial = 20
			$"Click To Continue".hide()
			$"../Controls".hide()
			$"../Pause Dimmer".hide()
			click_to_continue = false
			get_tree().paused = false
			UI.pause_timers()
			$Phone2.show()
			progress_tutorial()
			
		T.HOUSE:pass
		4:pass
		5:pass

func hide_all():
	for node in get_children():
		node.hide()


func _on_sneaky_button_pressed() -> void:
	var order = UI.order_list.get_child(0) as Order
	stage_done()
	order._on_accept_pressed()
	
func setup_tutorial_signals(signals):
	connected_signals = signals.duplicate()
	for sig in connected_signals as Array[Signal]:
		sig.connect(Callable(self,sig.get_name()))
		print(sig.get_connections())
		
func remove_tutorial_signals():
	for sig in connected_signals as Array[Signal]:
		sig.disconnect(Callable(self,sig.get_name()))
	connected_signals.clear()

func t_res_request():
	if UI.tutorial == 21:
		print("request fired!")
		progress_tutorial()
func t_res_grab():
	if UI.tutorial == 22:
		print("grab fired!")
		progress_tutorial()
		
func t_res_update():
	print("update order fired!")
	if UI.tutorial == 23:
		progress_tutorial()
