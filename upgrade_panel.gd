extends PanelContainer

@onready var icon_node: TextureRect = $"UpgradeContainer/Icon-Title/Icon"
@onready var title_node: Label = $"UpgradeContainer/Icon-Title/Title"
@onready var description_node: RichTextLabel = $UpgradeContainer/Description
@onready var stats_node: Label = $UpgradeContainer/VBoxContainer2/Stats
@onready var upgrade_stats_node: Label = $UpgradeContainer/VBoxContainer2/Upgrade_stats
@onready var price_node: Button = $UpgradeContainer/VBoxContainer/Price
@onready var level_node: Label = $UpgradeContainer/Sprite2D/Level
@onready var starbox: HBoxContainer = $UpgradeContainer/VBoxContainer/Starbox

var star_texture = load("res://Sprites/star_filled.png")
var max_level:int
var level:int
var prices :Array
var price: int
var stats:Array
var stats_des: String

signal purchase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prints("name",name)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init(upgrade_data:Dictionary):
	for stat in upgrade_data.keys():
		set(stat,upgrade_data[stat])
		if not get(stat):
			print(stat," is not a property!")
	add_stars()
	update()
	
func update():
	print("update fired")
	level = UI.upgrade_levels[name]
	fill_stars(level)
	if not disable_by_lvl():
		set_price()
		disable_by_cost(UI.cash)
	set_stats()
	
	pass

func set_level(_level:int):
	level = _level
	level_node.text = str(_level)

func set_price():
	price = prices[level]
	price_node.text = "$ " + str(price)

func set_stats():
	set_current_stats()
	set_next_stats()
	
func set_current_stats():
	if level > 0: 
		stats_node.show()
		stats_node.text = "Current Level:\n  " + stats_des % stats[level-1] + "\n\n"
	else:
		stats_node.hide()
	
func set_next_stats():
	if not is_max_level(): 
		upgrade_stats_node.show()
		upgrade_stats_node.text = "Next Level:\n  " + stats_des % stats[level]
	else:
		upgrade_stats_node.hide()
		
	
func disable_by_cost(cash:int):
	if cash < price:
		price_node.set_disabled(true)

func disable_by_lvl():
	
	if level == max_level:
		price_node.text = "Max Upgrade"
		price_node.set_disabled(true)
		return true
	return false

func is_max_level():
	return level == max_level

func add_stars():
	var star = starbox.get_child(0)
	for x in range(1,max_level):
		starbox.add_child(star.duplicate())
		
func fill_stars(level):
	var idx = level
	for star in starbox.get_children().slice(0,level):
		star.texture = star_texture

func _on_price_pressed() -> void:
	purchase.emit(price) # Replace with function body.
