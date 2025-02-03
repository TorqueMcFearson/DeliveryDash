extends RichTextLabel
const good_event_database :Dictionary= {
	0:{ "title":"Bad Weather",
		"description":"While locking your front door, you notice %s as the sky darkens with clouds.",
		"highlight" : "empty streets",
		"snippet":"less traffic",
		"property": null, #TODO
		"amount": 1.5}, #TODO	
		
	1:{ "title":"New Speed Limits",
		"description":"While getting dressed, you hear the radio talk about police %s.",
		"highlight" : "reducing speeding fines",
		"snippet":"crazy drivers",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	2:{ "title":"Fresh Asphalt",
		"description":"While fueling up before work, you accidentally %s.",
		"highlight" : "spill your triple-shot espresso into your gas tank",
		"snippet":"faster driving speed",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	3:{ "title":"Patient Customers",
		"description":"While eating breakfast, the news mentions a tanker crashed on the freeway, %s.",
		"highlight" : "releasing tons of laughing gas into the air",
		"snippet":"patient customers",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	4:{ "title":"Sporting Event",
		"description":"While picking up groceries, you see several people in facepaint and big banners that read %s!",
		"highlight" : "SuperBowl Sunday",
		"snippet":"lots of orders",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	5:{ "title":"Gas Hike",
		"description":"While browsing social media, several memes describe a trade embargo %s to your country.",
		"highlight" : "restricting imports of crude oil",
		"snippet":"higher gas prices",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
		
	6:{ "title":"New Fuel Pumps",
		"description":"While picking up gas station snacks, you notice the %s to shiny new hi-tech ones.",
		"highlight" : "fuel pumps have been upgraded",
		"snippet":"fast gas pumps",
		"property": null, #TODO
		"amount": 1.5}, #TODO
}
const bad_event_database :Dictionary= {
		0:{ "title":"Local Festival",
		"description":"While swiping tiktok, you get a video ad about some %s.",
		"highlight" : "big hippie festival in your area",
		"snippet":"lots of traffic",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	1:{ "title":"Old Drivers",
		"description":"While texting with your mother, she mentions a local dealership mistakenly gave a 75%% discount to %s.",
		"highlight" : "senior citizens on new cars",
		"snippet":"slow drivers",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	2:{ "title":"Spare Tire",
		"description":"While pulling out your driveway, you hear the rubbery flop of a flat, forcing you to swap to your %s.",
		"highlight" : "rickety spare tire",
		"snippet":"slower driving speed",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	3:{ "title":"Impatient customers",
		"description":"While chatting on discord, you notice that %s is since Netflix did a crackdown on passwords.",
		"highlight" : "everyone has a short fuse",
		"snippet":"Impatient customers",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	4:{ "title":"Too Many Dashers",
		"description":"While logging into the DeliveryDash app, you notice there is double the amount of dashers working today and %s.",
		"highlight" : "hardly any available orders",
		"snippet":"reduced orders",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
	5:{ "title":"Oil Found in Texas",
		"description":"While chatting with your neighbor, you learn that recent %s caused a species of racoon to go extinct.",
		"highlight" : "deregulations of fracking",
		"snippet":"lower gas prices",
		"property": null, #TODO
		"amount": 1.5}, #TODO
		
		
	6:{ "title":"Crowded Pumps",
		"description":"While driving to get gas, you notice every pump is taken and every person is %s.",
		"highlight" : "checking their watch",
		"snippet":"slow fuel pumps",
		"property": null, #TODO
		"amount": 1.5}, #TODO
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible_ratio = 0
	var good_event = good_event_database[randi_range(0,len(good_event_database)-1)]
	var bad_event = bad_event_database[randi_range(0,len(bad_event_database)-1)]
	var good_descript :String = good_event["description"] % ("[b][color=steel_blue]%s[/color][/b]" % good_event["highlight"])
	var bad_descript :String = bad_event["description"] % ("[b][color=steel_blue]%s[/color][/b]" % bad_event["highlight"])
	var good_snippet = "[b][color=green]%s[/color][/b]" % good_event["snippet"]
	var bad_snippet = "[b][color=red]%s[/color][/b]" % bad_event["snippet"]
	var snippet = "Seems like you're in for %s and %s today." % [good_snippet,bad_snippet]
	var descript = "%s\n\nLater, %s"  % [good_descript,bad_descript.to_lower()]

	text = "%s\n\n%s" % [descript, snippet]
	create_tween().tween_property(self,"visible_ratio",1,.5)
