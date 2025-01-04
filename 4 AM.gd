extends Control
const TITLE_SCENE = preload("res://Title_Screen.tscn")
const CITY_SCENE = preload("res://CityMain.tscn")

@onready var rows: Control = $"PanelContainer/Page 1/Order Rows"
@onready var perf_rows: Control = $"PanelContainer/Page 1/Performance Rows"
@onready var offscreen = $Markers/Offscreen.position.x
@onready var onscreen = $Markers/Onscreen.position.x
enum {LABEL,VALUE}
var broke = false
var page2 = false
@onready var expenses :Dictionary = {
	"Pocket_Cash" : UI.cash,
	"Total Expenses" : 0,
	"Rent" : randi_range(10,40)+8*UI.day,
	"Food" :  randi_range(0,20)+7*UI.day,
	"Electric" :  randi_range(-5,10)+6*UI.day,
	"Total Cash": 0}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UI.hide_UI()
	$Day.text = "Day %d" % UI.day
	$PanelContainer.clip_contents = true
	#if get_tree().current_scene == self: scene_root_ready()
	expenses["Total Expenses"] = (expenses["Rent"] + expenses["Food"] + expenses["Electric"])
	expenses["Total Cash"] = clampi(expenses["Pocket_Cash"] - expenses["Total Expenses"],0,1000)
	if expenses["Total Cash"] == 0:
		$"PanelContainer/Page 2/Order Rows/Total Cash/Cash".add_theme_color_override("font_color",Color(0.929, 0.102, 0.102))
		broke = true
	
	$"PanelContainer/Next Screen".disabled = true
	await UI.fade_in(1.5) # Replace with function body.
	init_stats()
		
#func scene_root_ready():
	#UI.round_stats = {
	#"Orders Accepted" : 12,
	#"Orders Completed" : 5,
	#"Orders Rejected" : 3,
	#"Orders Neglected" : 2,
	#"Orders Failed" : 1,
	#"Cars Hit" : 8,
	#"Mistakes Made" : 9,
	#"Cash Earned" : 120,
	#"Rating Change" : 30, 
	#} 
	#UI.rating = 30
	#UI.cash = 120
	#expenses["Pocket_Cash"] = 120
	
	
	
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
	print(node,val)
	if node == $"PanelContainer/Page 1/Performance Rows/Rating Earned":
		animate_stars_value(node,val)
		return
	var tween2 = create_tween().set_loops(val)
	tween2.tween_interval(1.0/val)
	tween2.tween_callback(update_value.bind(node))

func animate_stars_value(node,val):
	var value_label = node.get_child(VALUE)
	var final_size = Vector2((float(val)/UI.MAX_RATING) * UI.STAR_BAR_WIDTH,value_label.size.y)
	print(value_label,final_size)
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
	var music_player = UI.find_child("Music",false)
	UI.set_cash(expenses["Total Cash"])
	var tween = create_tween()
	tween.tween_property($Music,"volume_db",-50,1)
	tween.tween_callback(func(): music_player.stream = load("res://SFX/echo-flux-258965.mp3");music_player.play())
	tween.tween_property($Music,"volume_db",-14,1)
	
	if broke:
		UI.reset()
		UI.fade_out(.35,get_tree().change_scene_to_packed.bind(TITLE_SCENE))
	else:
		UI.player_map_position = UI.PLAYER_HOME_SPAWN
		UI.new_day()
		UI.fade_out(.35,get_tree().change_scene_to_packed.bind(CITY_SCENE))
		
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
	
