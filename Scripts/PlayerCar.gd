extends CharacterBody2D

########################################
## Node Variables
####################

@onready var roads: TileMapLayer = $"../TileMap/Roads"
@onready var yellowroads: TileMapLayer = $"../TileMap/YellowRoad"
@onready var sprite: Sprite2D = $Move_collision/TitleDriver
@onready var arrow: Sprite2D = $ArrowUI/arrow
@export var pitch_curve:Curve
@export var volume_curve:Curve
@onready var arrow_safezone: Rect2 = $Viewport.get_rect()
@onready var carhorn_pop_up: TextureProgressBar = $"PlayerUI/CarhornPop-up"


########################################
## Constants & Enums
####################

enum {HORZ,VERT,BOTH}
enum STATE {DEACTIVE, ACTIVE, RESPAWNING}
var BUMP_DAMPING := .6:
	get():
		return move_toward(1,BUMP_DAMPING,UI.bump_modifer)
var ACCEL = 20.0:
	get():
		return ACCEL * UI.accel_modifier
const DECELL = 30.0
const ROAD_DIR = ["Horz","Vert","Both"]
const arrow_off_min = 160**2
const arrow_on_min = 200**2
const HORN_COOLDOWN = 3
const YELLOW_ROAD_SPEED = 1.12
@export_range(0.0,2000.0,10.0) var MAX_SPEED_DEFAULT :float #450
@onready var MAX_SPEED :float = MAX_SPEED_DEFAULT

########################################
## Variables 
####################

var dest : Vector2
var just_collided : bool:
	set(value):
		if value:
			get_tree().create_timer(1).timeout.connect(func():just_collided = false)
		just_collided = value
var state : STATE = STATE.ACTIVE
var sound_velocity :float = 0
var bumped:bool=false
var car_horn = UI.car_horn


########################################
## Functions
####################

func _ready() -> void:
	if car_horn: carhorn_pop_up.show() 
	else: carhorn_pop_up.hide()

func _unhandled_input(event: InputEvent) -> void:
	if car_horn:
		if event.is_action_pressed("Honk"):
			print(event)
			blast_horn()
			cooldown_horn()
	
func _physics_process(delta: float) -> void:
	if not roads:
		return
		
	render_arrow() # Calculate and render GPS arrow.
		
	var road_dir :int = get_road_direction()
	var yellow_road_speed:float = get_yellow_road_modifier()
	var x_direction = Input.get_axis("Left", "Right")
	var y_direction = Input.get_axis("Up", "Down")
	var input_vector = Vector2(x_direction,y_direction)
	var input_power = input_vector.length()
	if input_power > 1: input_vector = input_vector.normalized() # Power is limited to 1 unit or less.
	
	# Determine new velocity from input and gas
	if not UI.gas:		MAX_SPEED = move_toward(MAX_SPEED,0,.75)
	if input_power: 	velocity = velocity.move_toward(input_vector * (MAX_SPEED * UI.speed_modifier * yellow_road_speed), ACCEL)
	else: 				velocity = velocity.move_toward(Vector2.ZERO, DECELL)
	
	# Process gas consumption based on velocity.
	if UI.gas:			UI.consume_gas((velocity.length()/MAX_SPEED_DEFAULT)*delta)
	
	# Uses tilemap and input direction to limit and set sprites facing.
	match road_dir:
		HORZ:
			set_sprite_horz(x_direction)
		VERT:
			set_sprite_vert(y_direction)
		BOTH:
			set_sprite_free(input_vector)

	move_and_slide()

	# Collisions process a reduced speed state called "bumped".
	if not just_collided:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is CharacterBody2D:
				$"../Crash".play()
				UI.round_stats["Cars Hit"] += 1
				if not bumped and UI.gas:
					bumped = true
					MAX_SPEED *= BUMP_DAMPING
					restore_speed()
				just_collided = true
	
	process_motor_sfx() # 
	
	$Speed.text = str(int(velocity.length())) # Debug feature


func restore_speed():
	if UI.gas:
		var tween_speed = create_tween()
		tween_speed.tween_property(self,"MAX_SPEED",MAX_SPEED_DEFAULT,1).set_delay(1.25)
		tween_speed.tween_callback(func():bumped = false)


func restore_speed_no_gas():
	var tween_speed = create_tween()
	tween_speed.tween_property(self,"MAX_SPEED",MAX_SPEED_DEFAULT,1).set_delay(.5)


# Starts a 10 second timer that will respawn player if they're still out of gas.
func out_of_gas():
	$OutOfGas.start(10)

func respawn():
	if state == STATE.RESPAWNING: return
	if UI.tween.is_valid(): return
	$OutOfGas.stop()
	
	var text :String
	var spawn :Vector2
	if UI.gas:
		spawn = UI.PLAYER_HOME_SPAWN
		text = "Respawning.."
	elif UI.cash:
		spawn = get_parent().get_nearest_gas_station()
		text = "Out of Fuel...\nTowing to Gas Station"
	else:
		return UI.end_day("Out of Fuel and Money...\nWalking home :(")
		
	await UI.fade_out(1.2,UI.fade_in.bind(.8),1,text)

	
	state = STATE.RESPAWNING
	velocity = Vector2(0,0)
	get_tree().create_timer(1).timeout.connect(func():state = STATE.ACTIVE)
	global_position = spawn


func get_current_tilemap():
	var pos = roads.to_local(global_position)
	return roads.local_to_map(pos)


func get_road_direction():
	var coords = get_current_tilemap()
	var data: TileData = roads.get_cell_tile_data(coords)
	return data.get_custom_data("Direction")


func get_yellow_road_modifier():
	var coords = get_current_tilemap()
	var data: TileData = yellowroads.get_cell_tile_data(coords)
	return YELLOW_ROAD_SPEED if data else 1.0


func set_sprite_horz(x_direction):
	if x_direction:
		#sprite.flip_v = true if x_direction < 0 else false
		$Move_collision.rotation_degrees = -90 if x_direction > 0 else 90


func set_sprite_vert(y_direction):
	if y_direction:
		$Move_collision.rotation_degrees = 0 if y_direction > 0 else 180


func set_sprite_free(temp_direction:Vector2):
	if temp_direction:
		$Move_collision.rotation = temp_direction.rotated(deg_to_rad(-90)).angle()


func render_arrow():
	if not dest:
		arrow.hide()
		return
	if not arrow.visible and global_position.distance_squared_to(dest) > arrow_on_min:
		arrow.show()
	elif global_position.distance_squared_to(dest) < arrow_off_min:
		arrow.hide()
		return
	arrow.global_position = lerp(global_position,dest,.35) 
	arrow.position = arrow.global_position.clamp(global_position+arrow_safezone.position,global_position+arrow_safezone.end) #global_position-vp.end/2.8,global_position+vp.end/2.8)
	arrow.rotation = position.direction_to(dest).angle()


func process_motor_sfx():
	if not UI.gas:
		$Motor_Sound.volume_db = -80
		return
	sound_velocity = lerp(sound_velocity,velocity.length(),.2)
	$Motor_Sound.pitch_scale = pitch_curve.sample(sound_velocity/MAX_SPEED)# + randf_range(-.05,.05)
	$Motor_Sound.volume_db = volume_curve.sample(sound_velocity/MAX_SPEED) #+ randf_range(-.5,.5)
	pass


func _on_traffic_body_exited(body: Node2D) -> void:
	if body == self: 
		return
	body.queue_free() # Replace with function body.


func _on_out_of_gas_timeout() -> void:
	if UI.gas == 0:
		respawn() # Replace with function body.


func cooldown_horn():
	car_horn = false
	var timer = get_tree().create_timer(HORN_COOLDOWN)
	create_tween().tween_property(carhorn_pop_up,"value",100,HORN_COOLDOWN)
	timer.timeout.connect(func():re_activate_horn())


func re_activate_horn():
	print("COOLDOWN REFRESHED")
	carhorn_pop_up.tint_progress = Color(1, 1, 1)
	var def_scale = carhorn_pop_up.scale
	var tween = create_tween()
	tween.tween_property(carhorn_pop_up,"scale",Vector2(.5,.5),.15)
	tween.tween_property(carhorn_pop_up,"scale",def_scale,.15)
	car_horn = true


func blast_horn():
	$Horn.play()
	carhorn_pop_up.value = 0
	carhorn_pop_up.tint_progress = Color(0.65, 0.65, 0.65)
	var blast_zone = generate_blast_radius()
	await wait_for_blast_data()
	var blasted_cars = blast_zone.get_overlapping_bodies()
	blast_zone.queue_free()  # Remove the temporary area
	blasted_cars.erase(self)
	for car in blasted_cars:
		car.get_horned()


func generate_blast_radius():
	var attack_radius: float = 450.0
	var blast_zone = Area2D.new()
	var shape := CircleShape2D.new()
	var collision_shape := CollisionShape2D.new()
	shape.radius = attack_radius
	collision_shape.shape = shape
	blast_zone.collision_mask = 2
	blast_zone.add_child(collision_shape)
	add_child(blast_zone)
	return blast_zone


func wait_for_blast_data():
	await get_tree().physics_frame
	await get_tree().physics_frame
