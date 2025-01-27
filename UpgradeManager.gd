extends Control
@onready var upgrade_nodes = $"Options Menu/UpgradeGrid".get_children() as Array[UpgradeNodes]
signal done_shopping_pressed

@export var upgrade_data = {
	"Strong Bumpers" : {
		"max_level": 2,
		"prices":[45,75],
		"stats": [-50,-100],
		"stats_des": "%d%% slowdown",
		"level" : UI.upgrade_levels["Strong Bumpers"],
		"callback" : upgrade_bumper
		
	},
	
	"TuroCharge Engine" : {
		"max_level": 5,
		"prices":[30,50,75,100,125],
		"stats": [[10,2.5],[20,5.0],[30,7.5],[40,10],[50,12.5]],
		"stats_des": "+%d%% speed\n  +%d%% acceleration",
		"level" : UI.upgrade_levels["TuroCharge Engine"],
		"callback" : upgrade_engine
		
	},
	"Fuel Efficiency" : {
		"max_level": 3,
		"prices":[30,60,125],
		"stats": [-10,-25,-50],
		"stats_des": "%d%% fuel consumption",
		"level" : UI.upgrade_levels["Fuel Efficiency"],
		"callback" : upgrade_fuel_eff
		
	},
	"Fuel Tank Size" : {
		"max_level": 4,
		"prices":[25,75,100,150],
		"stats": [20,50,100,135],
		"stats_des": "+%d%% fuel tank size",
		"level" : UI.upgrade_levels["Fuel Tank Size"],
		"callback" : upgrade_fuel_tank
		
	},
	"Car Horn" : {
		"max_level": 1,
		"prices":[100],
		"stats": [1],
		"stats_des": "Gain %d car horn",
		"level" : UI.upgrade_levels["Car Horn"],
		"callback" : upgrade_car_horn
	},
	
	
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#randomizer()
	for upgrade in upgrade_nodes:
		upgrade.init(upgrade_data[upgrade.name])
		upgrade.purchase.connect(upgrade_data[upgrade.name]["callback"])
	update()
	print("-%d%% this is for testing purposes" % [5])
	pass # Replace with function body.


func randomizer():
	for upgrade in upgrade_data:
		var max_level = randi_range(3,5)
		var prices = []
		var stats = []
		for x in range(max_level):
			prices.append(randi_range(1,30))
		for x in range(max_level):
			stats.append(randi_range(1,30))
		var stats_des = "-%d%% this is for testing purposes"
		var level = randi_range(0,max_level)
		upgrade_data[upgrade]["max_level"] = max_level
		upgrade_data[upgrade]["prices"] = prices
		upgrade_data[upgrade]["stats"] = stats
		#upgrade_data[upgrade]["stats_des"] = stats_des
		upgrade_data[upgrade]["level"] = level
	UI.cash = 300
		

func update_cash_label():
	UI.set_cash(UI.cash)
	$"Options Menu/Cash/L_Cash".text = "$" + str(UI.cash)

func upgrade_bumper(price):
	print("fired upgrade_bumper")
	var upgrade = "Strong Bumpers"
	process_payment(price)
	process_upgrade(upgrade)
	process_modifer(upgrade,"bump_modifer")
	update()
	

func upgrade_engine(price):
	print("fired upgrade_engine")
	process_payment(price)
	var upgrade = "TuroCharge Engine"
	process_upgrade(upgrade)
	process_modifer(upgrade,["speed_modifier","accel_modifier"])
	update()
	
func upgrade_fuel_eff(price):
	print("fired upgrade_fuel_eff")
	process_payment(price)
	var upgrade = "Fuel Efficiency"
	process_upgrade(upgrade)
	process_modifer(upgrade,"fuel_consume_modifier")
	update()
	
func upgrade_fuel_tank(price):
	print("fired upgrade_fuel_tank")
	process_payment(price)
	var upgrade = "Fuel Tank Size"
	process_upgrade(upgrade)
	process_modifer(upgrade,"max_fuel_modifier")
	update()
	
func upgrade_car_horn(price):
	print("fired upgrade_car_horn")
	process_payment(price)
	var upgrade = "Car Horn"
	process_upgrade(upgrade)
	UI.car_horn = true
	update()

func process_upgrade(upgrade):
	UI.upgrade_levels[upgrade] += 1
	var level = UI.upgrade_levels[upgrade]
	
func process_modifer(upgrade,modifier):
	var level = UI.upgrade_levels[upgrade]
	if modifier is Array:
		for n in range(len(modifier)):
			UI.set(modifier[n],1.0+(upgrade_data[upgrade]["stats"][level-1][n]/100.00))
			prints("NEW MODIFIER",upgrade,UI.get(modifier[n]))
	else:
		UI.set(modifier,1.0+(upgrade_data[upgrade]["stats"][level-1]/100.00))
		prints("NEW MODIFIER",upgrade,UI.get(modifier))
	
func process_payment(price):
	UI.cash -= price
	update_cash_label()

func update():
	for node in upgrade_nodes:
		node.update()
	update_cash_label()
	


func _on_back_button_pressed() -> void:
	done_shopping_pressed.emit() # Replace with function body.
