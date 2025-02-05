extends RichTextLabel
@onready var sub_text: RichTextLabel = $"../SubText"
const good_event_database :Dictionary= {
	0:{ "title":"Bad Weather",
		"description":"While locking your front door, you notice %s as the sky darkens with clouds.",
		"highlight" : "empty streets",
		"snippet":"less traffic",
		"property": "max_cars_modifier",
		"amount": 0.75},	
		
	1:{ "title":"New Speed Limits",
		"description":"While getting dressed, you hear the radio talk about police %s.",
		"highlight" : "reducing speeding fines",
		"snippet":"crazy drivers",
		"property": "AI_max_speed_mod",
		"amount": 1.25},
		
	2:{ "title":"Spilt Coffee",
		"description":"While fueling up before work, you accidentally %s.",
		"highlight" : "spill your triple-shot espresso into your gas tank",
		"snippet":"faster driving speed",
		"property": "speed_modifier",
		"amount": 1.25},
		
	3:{ "title":"Crashed Tanker",
		"description":"While eating breakfast, the news mentions a tanker crashed on the freeway, %s.",
		"highlight" : "releasing tons of laughing gas into the air",
		"snippet":"patient customers",
		"property": "order_duration_mod",
		"amount": 1.25},
		
	4:{ "title":"The Big Game",
		"description":"While picking up groceries, you see several people in facepaint and big banners that read %s!",
		"highlight" : "SuperBowl Sunday",
		"snippet":"lots of orders",
		"property": "order_timer_mod",
		"amount": 1.25},
		
	5:{ "title":"Dead Racoons",
		"description":"While chatting with your neighbor, you learn that recent %s caused a species of racoon to go extinct.",
		"highlight" : "deregulations of fracking",
		"snippet":"lower gas prices",
		"property": "gas_price_mod",
		"amount": 0.75},

	6:{ "title":"New Fuel Pumps",
		"description":"While picking up gas station snacks, you notice the %s to shiny new hi-tech ones.",
		"highlight" : "fuel pumps have been upgraded",
		"snippet":"fast gas pumps",
		"property": "gas_fill_speed_mod",
		"amount": 1.25},
		}
		
const bad_event_database :Dictionary= {
		0:{ "title":"Local Festival",
		"description":"While swiping tiktok, you get a video ad about some %s.",
		"highlight" : "big hippie festival in your area",
		"snippet":"lots of traffic",
		"property": "max_cars_modifier",
		"amount": 1.25},
		
	1:{ "title":"Old Drivers",
		"description":"While texting with your mother, she mentions a local dealership mistakenly gave a 75%% discount to %s.",
		"highlight" : "senior citizens on new cars",
		"snippet":"slow drivers",
		"property": "speed_modifier",
		"amount": 0.75},
		
	2:{ "title":"Flat Tire",
		"description":"While pulling out your driveway, you hear the rubbery flop of a flat, forcing you to swap to your %s.",
		"highlight" : "rickety spare tire",
		"snippet":"slower driving speed",
		"property": "speed_modifier",
		"amount": 0.75},
		
	3:{ "title":"Mad World",
		"description":"While chatting on discord, you notice that %s since Netflix did a crackdown on sharing passwords.",
		"highlight" : "everyone has a short fuse",
		"snippet":"impatient customers",
		"property": "order_duration_mod",
		"amount": 0.75},
		
	4:{ "title":"Too Many Newbs",
		"description":"While logging into the DeliveryDash app, you notice there is double the amount of dashers working today and %s.",
		"highlight" : "hardly any available orders",
		"snippet":"reduced orders",
		"property": "order_timer_mod",
		"amount": 0.75},
		
	5:{ "title":"Trade Wars",
		"description":"While browsing social media, several memes describe a trade embargo %s to your country.",
		"highlight" : "restricting imports of crude oil",
		"snippet":"higher gas prices",
		"property": "gas_price_mod",
		"amount": 1.25},
		
	6:{ "title":"Crowded Pumps",
		"description":"While driving to get gas, you notice every pump is taken and every person is %s.",
		"highlight" : "checking their watch",
		"snippet":"slow fuel pumps",
		"property": "gas_fill_speed_mod",
		"amount": 0.75},
		}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	visible_ratio = 0
	sub_text.visible_ratio = 0
	if get_tree().current_scene.name == "Day Event Panel":
		update()
	
func update():

	var idx = range(len(good_event_database))
	idx.shuffle()
	var good_event = good_event_database[idx.pop_back()]
	var bad_event = bad_event_database[idx.pop_back()]
	set_event_text(good_event,bad_event)
	if UI.temp_mod_dict: restore_mods()
	save_mods(good_event["property"],bad_event["property"])
	apply_mod(good_event["property"],good_event["amount"])
	apply_mod(bad_event["property"],bad_event["amount"])
	tween_text()
	
func restore_mods():
	for prop in UI.temp_mod_dict:
		apply_mod(prop,UI.temp_mod_dict[prop])
		assert(UI.get(prop) == UI.temp_mod_dict[prop])
		
		
func save_mods(good_prop: String,bad_prop: String):
	UI.temp_mod_dict = {good_prop:UI.get(good_prop),bad_prop:UI.get(bad_prop)}
	assert(UI.get(good_prop) == UI.temp_mod_dict[good_prop])
	assert(UI.get(bad_prop) == UI.temp_mod_dict[bad_prop])
	
	
func apply_mod(prop,amount):
	UI.set(prop,amount)
	
	
func tween_text():
	visible_ratio = 0
	sub_text.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(self,"visible_ratio",1,1.10)
	tween.tween_property(sub_text,"visible_ratio",1,.5)
	
	
func set_event_text(good_event,bad_event):
	var good_descript :String = good_event["description"] % ("[b][color=steel_blue]%s[/color][/b]" % good_event["highlight"])
	var bad_descript :String = bad_event["description"] % ("[b][color=steel_blue]%s[/color][/b]" % bad_event["highlight"])
	
	var good_snippet = "[b][color=green]%s[/color][/b]" % good_event["snippet"]
	var bad_snippet = "[b][color=red]%s[/color][/b]" % bad_event["snippet"]
	var snippet = "[center]Seems like you're in for %s and %s today." % [good_snippet,bad_snippet]
	
	var good_text = "[font_size=18][center][b][color=green]%s[/color][/b]\n%s" % [good_event["title"],good_descript]
	var bad_text = "[b][color=red]%s[/color][/b][/center][/font_size]\nLater, %s" % [bad_event["title"],bad_descript.to_lower()]
	
	text = "[center]%s\n\n%s" % [good_text,bad_text]
	sub_text.text = snippet
