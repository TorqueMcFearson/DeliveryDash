extends Control
const TITLE_SCENE = preload("res://Title_Screen.tscn")
const CITY_SCENE = preload("res://CityMain.tscn")


@onready var rows: Control = $"PanelContainer/Page 1/Order Rows"
@onready var perf_rows: Control = $"PanelContainer/Page 1/Performance Rows"
@onready var offscreen = $Markers/Offscreen.position.x
@onready var onscreen = $Markers/Onscreen.position.x
@onready var day_event_text: RichTextLabel = $DayEvent/UpgradePanel/VBoxContainer/DayEventText

enum {LABEL,VALUE}
var broke = false
var page2 = false
@onready var expenses :Dictionary = {
	"Pocket_Cash" : UI.cash,
	"Total Expenses" : 0,
	"Rent" : randi_range(10,40)+9*UI.day*UI.expense_mod,
	"Food" :  randi_range(0,20)+8*UI.day*UI.expense_mod,
	"Electric" :  randi_range(-5,10)+7*UI.day*UI.expense_mod,
	"Total Cash": 0}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	UI.hide_UI()
	$Day.text = "Day %d" % UI.day
	$PanelContainer.clip_contents = true
	#if get_tree().current_scene == self: scene_root_ready()
	expenses["Total Expenses"] = (expenses["Rent"] + expenses["Food"] + expenses["Electric"])
	expenses["Total Cash"] = max(expenses["Pocket_Cash"] - expenses["Total Expenses"],0)
	if expenses["Total Cash"] == 0:
		$"PanelContainer/Page 2/Order Rows/Total Cash/Cash".add_theme_color_override("font_color",Color(0.929, 0.102, 0.102))
		broke = true
	
	$"PanelContainer/Next Screen".disabled = true
	await UI.fade_in(1.5) # Replace with function body.
	init_stats()
	write_stats_to_file()
	

func init_stats():
	var o_rows = rows.get_children()
	var p_rows = perf_rows.get_children()
	var keys = UI.round_stats.keys()
	
	var total_orders = UI.round_stats["Orders Accepted"] + UI.round_stats["Orders Rejected"] + UI.round_stats["Orders Neglected"]
	get_tree().create_timer(1).timeout.connect(animate_stats_in.bind($"PanelContainer/Page 1/Orders Total",3.5,total_orders))
		
	var i = 0
	
	for node in (o_rows + p_rows):
		var val = UI.round_stats[keys[i]]
		animate_stats_in(node,i,val)
		i +=1
		
	get_tree().create_timer(3).timeout.connect(func():$"PanelContainer/Next Screen".disabled = false)
	
func set_labels(node,key):
	var value:Label = node.get_child(VALUE)
	var val = UI.round_stats[key]
	value.text = str(val)
		
func animate_stats_in(node,i:int,val):
	var tween = create_tween()
	node.position.x = offscreen
	tween.tween_callback($Slide_SFX.play).set_delay((.2 * i))
	tween.tween_property(node,"position",Vector2(onscreen,node.position.y),.4).set_trans(Tween.TRANS_SPRING)
	tween.tween_callback(animate_stats_value.bind(node,val)).set_delay(.2)
	
func animate_stats_value(node,val):
	if node == $"PanelContainer/Page 1/Performance Rows/Rating Earned":
		animate_stars_value(node,val)
		return
	var tween2 = create_tween().set_loops(val)
	tween2.tween_interval(1.0/val)
	tween2.tween_callback(update_value.bind(node))

func animate_stars_value(node,val):
	var value_label = node.get_child(VALUE)
	var final_size = Vector2((float(val)/UI.MAX_RATING) * UI.STAR_BAR_WIDTH,value_label.size.y)
	create_tween().tween_property(value_label,"size",final_size,1)
	
func update_value(node):
	var label_node:Label = node.get_child(VALUE)
	if label_node.name == "Cash":
		var val = int(label_node.text.lstrip("$ "))
		label_node.text = "$%3d" %(val+1)
	else:
		var val = int(label_node.text)
		label_node.text = str(val+1)

func _pay_bills_button():
	if page2: 
		_page2_button()
	else:
		$"PanelContainer/Next Screen".disabled = true
		$"PanelContainer/Next Screen".text = ""
		page2 = true
		get_tree().create_timer(3).timeout.connect(func():$"PanelContainer/Next Screen".disabled = false;$"PanelContainer/Next Screen".text = "GAME OVER" if broke else "Next Day")
		await animate_stats_out($"PanelContainer/Page 1")
		animate_panel_shrink()
	
func _page2_button():
	$"PanelContainer/Next Screen".disabled = true 
	UI.set_cash(expenses["Total Cash"])
	if broke:
		after_page_2()
		#UI.reset()
		#UI.fade_out(1,get_tree().change_scene_to_packed.bind(TITLE_SCENE))
	else:
		after_page_2()
		
func animate_stats_out(node):
		var tween = create_tween()
		tween.tween_property(node,"position",Vector2(-380,node.position.y),.4).set_trans(Tween.TRANS_SPRING)
		return tween.finished
	
func animate_panel_shrink():
	create_tween().tween_property($"PanelContainer/Page 2/Orders","position",Vector2(0,22),.25).set_delay(.4)
	var tween = create_tween()
	tween.tween_property($PanelContainer,"size",Vector2(0,-150),.68).as_relative()
	#var tween = create_tween()
	#tween.tween_property($"PanelContainer/Cash","position",Vector2(0,-210),.8).as_relative()
	tween.tween_callback(animate_page_2)

func animate_page_2(): #400 difference
	
	var i = 0
	var keys = expenses.keys()
	for node in ($"PanelContainer/Page 2/Order Rows".get_children()):
		var val = expenses[keys[i]]
		animate_stats_in(node,i,val)
		i +=1
	
func write_stats_to_file():
	var f = FileAccess.open("res://log.txt",FileAccess.READ_WRITE)
	f.seek_end()
	var string = ""
	if UI.day ==1: 
		string = "\n\n" + Time.get_datetime_string_from_system() + "\n"
	string += "DAY " + str(UI.day) + " || "
	string += "Cash Earned: " + str(UI.round_stats["Cash Earned"]) + " , "
	for key in ["Pocket_Cash","Total Expenses","Total Cash"]:
		string += key + ": " + str(expenses[key]) + " , "
	for key in UI.debug_dictionary:
		string += key + ": " + str(UI.debug_dictionary[key]) + "\n"
	f.store_string(string)
	f.close()
	
func after_page_2():
	await UI.fade_out(1.15)
	$PanelContainer.hide()
	UI.new_day()
	$"Car Upgrades".update()
	UI.fade_in(1.0)
	await tween_nextday_label()
	$"Car Upgrades".show()
	$"Car Upgrades".modulate = Color(1, 1, 1, 0)
	create_tween().tween_property($"Car Upgrades","modulate",Color(1,1,1,1),.35).set_delay(.45)
	create_tween().tween_property($Day,"global_position", $Markers/NextDayEnd.global_position,.5).set_trans(Tween.TRANS_QUAD)
	

func tween_nextday_label():
	$Day.global_position = $Markers/NextDayStart.global_position
	$Day.text = "Day %d" % UI.day
	var tween := create_tween()
	tween.tween_property($Day,"global_position", $Markers/NextDayMiddle.global_position,1).set_delay(.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(1)
	return tween.finished
	
func _on_car_upgrades_done_shopping_pressed() -> void:
	switch_to_day_event_panel()
	
func switch_to_day_event_panel():
	var tween = create_tween()
	tween.tween_property($"Car Upgrades","modulate",Color(1,1,1,0),.35)
	tween.tween_callback($"Car Upgrades".hide)
	tween.tween_property($DayEvent,"modulate",Color(1,1,1,1),.75).set_delay(.12)
	tween.tween_callback(func():$DayEvent.show();day_event_text.update())
	
	
	
func start_next_day():
	var tween = create_tween()
	UI.day_over = false
	UI.fade_out_in_music("res://SFX/echo-flux-258965.mp3",1)
	UI.player_map_position = UI.PLAYER_HOME_SPAWN
	UI.fade_out(1.5,get_tree().change_scene_to_packed.bind(CITY_SCENE))
	get_tree().create_timer(1).timeout.connect(UI.unpause_timers)


func _on_back_button_pressed() -> void:
	start_next_day() 
