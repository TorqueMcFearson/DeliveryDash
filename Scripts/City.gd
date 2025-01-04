extends Node2D
signal tutorial_complete
const HOUSE_TEXTURES = [
preload("res://Sprites/house1.png"),
preload("res://Sprites/house3.png"),
preload("res://Sprites/house4.png"),
preload("res://Sprites/house5.png"),
preload("res://Sprites/house6.png"),
]
const AI_CAR = preload("res://ai_car.tscn")
const MAX_CARS : int= 25
const GLOW = preload("res://Glow.tres")
var HOUSE = load("res://house.tscn")
var RESTURANT = load("res://resturant_scene.tscn")
@onready var tilemap: TileMap = %TileMap
@onready var player: CharacterBody2D = $Player
@onready var spawnlimit: ReferenceRect = $Player/Spawnlimit
@onready var viewport: ReferenceRect = $Player/Viewport
var target_queue = []
var current_target : Sprite2D
var at_destination :bool = false
var mouse_inside:bool=false


func _ready() -> void:
	#$CanvasModulate.color = Color(0,0,0,1)
	print(player.global_position)
	player.position = UI.player_map_position
	UI.show_UI()
	randomize_houses()
	UI.unpause_timers()
	if UI.tutorial:
		await UI.fade_in(1) # Replace with function body.
		print("FADE IN COMPLETE")
		UI.show_tutorial()
		get_tree().paused = true
	else:
		UI.fade_in(1)
	#call_deferred("add_cars")
	UI.get_stores($Stores.get_children())
	UI.get_houses($Houses.get_children())
	UI.new_active_order_set.connect(mark_target)
	if UI.active_order:
		mark_target(UI.active_order)
	else:
		UI.order_timer_start()



func mark_target(order :Order):
	var target:Sprite2D
	if not order:
		target = null
	else:
		match order.state:
			order.NEW:
				target = null
				print("AN UNACCEPTED ORDER AS TARGET?? IMPOSSIBLE!")
			order.TO_STORE:
				target = $Stores.get_child(order.resturant_idx)
			order.TO_HOUSE:
				target = $Houses.get_child(order.house_idx)
			order.DELIVERED:
				target = null
	
	demark_target(current_target)
	current_target = target
	if current_target:
		player.dest = current_target.position
		current_target.material = GLOW
		$Building_Entrance.position = current_target.position
	else:
		player.dest = Vector2(0,0)
		$Building_Entrance.position = Vector2(0,0)
	
func demark_target(target):
	if target:
		target.material = null
	

func _unhandled_input(event: InputEvent) -> void:
	if at_destination:
		if event.is_action_pressed("Enter") or (event is InputEventMouseButton and event.button_index == 1 and mouse_inside):
			go_to_building()
			get_viewport().set_input_as_handled()


	
func randomize_houses():
	var houses = $Houses.get_children()
	houses.shuffle()
	var half :int = len(houses) #int(len(houses)/2) - undo when you have more houses
	for house:Sprite2D in houses.slice(0,half):
		house.texture = HOUSE_TEXTURES.pick_random()
	for house in houses.slice(half):
		house.queue_free()
		

func near_player(marker:Marker2D):
	var marker_pos = player.to_local(marker.global_position)
	return spawnlimit.get_rect().has_point(marker_pos) and not (viewport.get_rect().has_point(marker_pos))
	 

func add_cars(n = MAX_CARS):
	var usable_markers = $Spawns.get_children().filter(near_player)
	var count = clamp(n,0,len(usable_markers))
	for i in range(count):
		var new_car = AI_CAR.instantiate()
		new_car.global_position = usable_markers.pop_back().global_position
		new_car.tilemap = %TileMap
		$Cars.add_child(new_car)

func _on_car_check_timeout() -> void:
	var count = $Cars.get_child_count()
	if count < MAX_CARS:
		add_cars(MAX_CARS-count) # Replace with function body.

func go_to_building():
	UI.player_map_position = player.position
	UI.location = current_target.name
	if current_target.get_parent().name == "Stores":
		UI.fade_out(.35,get_tree().change_scene_to_packed.bind(RESTURANT))
	else:
		UI.fade_out(.35,get_tree().change_scene_to_packed.bind(HOUSE))
	


func _on_building_entrance_body_entered(body: Node2D) -> void:
	if body == player:
		at_destination = true
		 # Replace with function body.

func _on_building_entrance_body_exited(body: Node2D) -> void:
	if body == player:
		at_destination = false
	pass # Replace with function body.


func _on_building_entrance_mouse_entered() -> void: mouse_inside = true
func _on_building_entrance_mouse_exited() -> void:  mouse_inside = false 