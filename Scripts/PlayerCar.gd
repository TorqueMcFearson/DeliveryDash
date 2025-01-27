extends CharacterBody2D

########################################
## Node Variables
####################
@onready var roads: TileMapLayer = $"../TileMap/Roads"
@onready var yellowroads: TileMapLayer = $"../TileMap/YellowRoad"
@onready var sprite: Sprite2D = $Move_collision/TitleDriver
@onready var arrow: Sprite2D = $CanvasLayer2/arrow
@export var pitch_curve:Curve
@export var volume_curve:Curve
@onready var arrow_safezone: Rect2 = $Viewport.get_rect()

########################################
## Constants & Enums
####################
enum {HORZ,VERT,BOTH}
enum STATE {DEACTIVE, ACTIVE, RESPAWNING}
var ACCEL = 20.0:
	get():
		return ACCEL * UI.accel_modifier
const DECELL = 30.0
var BUMP_DAMPING := .6:
	get():
		return move_toward(1,BUMP_DAMPING,UI.bump_modifer)
const ROAD_DIR = ["Horz","Vert","Both"]
const arrow_off_min = 160**2
const arrow_on_min = 200**2
	
	##Preset Variables
@export_range(0.0,2000.0,10.0) var MAX_SPEED_DEFAULT :float #450
@onready var MAX_SPEED :float = MAX_SPEED_DEFAULT
########################################
## Variables & Enums
####################
var dest : Vector2
var just_collided : bool:
	set(value):
		if value:
			get_tree().create_timer(1).timeout.connect(func():just_collided = false)
		just_collided = value
var collisions = []
var state : STATE = STATE.ACTIVE
var sound_velocity :float = 0
var bumped:bool=false


########################################
## Functions
####################

func _ready() -> void:
	pass
	
func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Respawn") and state != STATE.RESPAWNING:
		respawn()
			
	
func _physics_process(delta: float) -> void:
	render_arrow()
	if not roads:
		return
	var road_dir :int = get_road_direction()
	var yellow_road_speed:float = get_yellow_road()
	var x_direction = Input.get_axis("Left", "Right")
	var y_direction = Input.get_axis("Up", "Down")
	var input_vector = Vector2(x_direction,y_direction)
	
	match road_dir:
		HORZ:
			set_sprite_horz(x_direction)
		VERT:
			set_sprite_vert(y_direction)
		BOTH:
			if x_direction:
				set_sprite_horz(x_direction)
			elif y_direction:
				set_sprite_vert(y_direction)
			set_sprite_free(input_vector)
			
	get_road_direction()
	var speed = input_vector.length()
	if not UI.gas:
		MAX_SPEED = move_toward(MAX_SPEED,0,.75)
		if speed > 1:input_vector = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * (MAX_SPEED * UI.speed_modifier * yellow_road_speed), ACCEL)
	elif speed > 0:
		if speed > 1:input_vector = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * (MAX_SPEED * UI.speed_modifier * yellow_road_speed), ACCEL)
		UI.consume_gas(delta)
	else:
		# Decelerate to stop
		velocity = velocity.move_toward(Vector2.ZERO, DECELL )
	move_and_slide()
	
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
	process_motor()
	$Label.text = str(int(velocity.length()))

func restore_speed():
	if UI.gas:
		var tween_speed = create_tween()
		tween_speed.tween_property(self,"MAX_SPEED",MAX_SPEED_DEFAULT,1).set_delay(1.25)
		tween_speed.tween_callback(func():bumped = false)

func restore_speed_no_gas():
	var tween_speed = create_tween()
	tween_speed.tween_property(self,"MAX_SPEED",MAX_SPEED_DEFAULT,1).set_delay(.5)

func out_of_gas():
	$OutOfGas.start(10)
	

func respawn():
	$OutOfGas.stop()
	if UI.gas:
		$CanvasLayer/Respawning.text = "Respawning.."
	elif not UI.cash:
		$CanvasLayer/Respawning.text = "Out of Fuel and Money...\nWalking home :("
		$CanvasLayer/Respawning.show()
		await UI.fade_out(2.5)
		UI.end_day()
		return
	else:
		$CanvasLayer/Respawning.text = "Out of Fuel...\nTowing to Gas Station"
	$CanvasLayer/Respawning.show()
	await UI.fade_out(1.2,UI.fade_in.bind(.8),.5)
	$CanvasLayer/Respawning.hide()
	state = STATE.RESPAWNING
	velocity = Vector2(0,0)
	get_tree().create_timer(1).timeout.connect(func():state = STATE.ACTIVE)
	if UI.gas:
		global_position = UI.PLAYER_HOME_SPAWN
	else:
		global_position = get_parent().get_nearest_gas_station()

func show_timeup_message():
		$CanvasLayer/Respawning.text = "Day Over... Driving Home"
		$CanvasLayer/Respawning.show()
		#await get_tree().create_timer(2).timeout # Commented out because player will get freed by then.
		#$CanvasLayer/Respawning.hide()
		
func get_current_tilemap():
	var pos = roads.to_local(global_position)
	return roads.local_to_map(pos)
	
func get_road_direction():
	var coords = get_current_tilemap()
	var data: TileData = roads.get_cell_tile_data(coords)
	return data.get_custom_data("Direction")
	
func get_yellow_road():
	var coords = get_current_tilemap()
	var data: TileData = yellowroads.get_cell_tile_data(coords)
	return 1.15 if data else 1.0
	
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

func process_motor():		
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
