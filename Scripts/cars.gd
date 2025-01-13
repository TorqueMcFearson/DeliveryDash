extends CharacterBody2D

var vehicles = {
	"pickup": {"xy": Vector2(57, 131), "size": Vector2(28, 51)},
	"pickup2": {"xy": Vector2(36, 78), "size": Vector2(28, 51)},
	"pickup3": {"xy": Vector2(350, 203), "size": Vector2(28, 51)},
	"suv": {"xy": Vector2(380, 204), "size": Vector2(28, 50)},
	"suv2": {"xy": Vector2(410, 204), "size": Vector2(28, 50)},
	"van2": {"xy": Vector2(440, 204), "size": Vector2(27, 50)},
	"van3": {"xy": Vector2(469, 204), "size": Vector2(27, 50)},
	"mustang2": {"xy": Vector2(66, 80), "size": Vector2(26, 49)},
	"camaro": {"xy": Vector2(87, 134), "size": Vector2(26, 48)},
	"camaro2": {"xy": Vector2(94, 84), "size": Vector2(26, 48)},
	"challenger2": {"xy": Vector2(115, 135), "size": Vector2(28, 48)},
	"challenger3": {"xy": Vector2(145, 138), "size": Vector2(28, 48)},
	"lexus": {"xy": Vector2(122, 85), "size": Vector2(26, 48)},
	"lexus2": {"xy": Vector2(175, 138), "size": Vector2(26, 48)},
	"gwagon": {"xy": Vector2(150, 89), "size": Vector2(27, 47)},
	"bmw": {"xy": Vector2(179, 89), "size": Vector2(25, 47)},
	"gwagon2": {"xy": Vector2(203, 149), "size": Vector2(27, 47)},
	"patrol": {"xy": Vector2(232, 149), "size": Vector2(27, 47)},
	"patrol2": {"xy": Vector2(261, 149), "size": Vector2(27, 47)},
	"lexus3": {"xy": Vector2(290, 149), "size": Vector2(26, 48)},
	"taxi": {"xy": Vector2(318, 149), "size": Vector2(26, 48)},
	"taxi2": {"xy": Vector2(206, 99), "size": Vector2(26, 48)},
	"lambo": {"xy": Vector2(234, 101), "size": Vector2(27, 46)},
	"lambo2": {"xy": Vector2(263, 101), "size": Vector2(27, 46)},
	"lancer": {"xy": Vector2(292, 100), "size": Vector2(26, 47)},
	"bmw2": {"xy": Vector2(320, 100), "size": Vector2(25, 47)},
	"bmw3": {"xy": Vector2(32, 10), "size": Vector2(25, 47)},
	"lancer2": {"xy": Vector2(346, 150), "size": Vector2(26, 47)},
	"mustang3": {"xy": Vector2(347, 101), "size": Vector2(26, 47)},
	"wrangler": {"xy": Vector2(374, 155), "size": Vector2(24, 46)},
	}


@export_enum("pickup","pickup2","pickup3","suv","suv2","van2","van3","mustang2","camaro","camaro2","challenger2","challenger3","lexus","lexus2","gwagon","bmw","gwagon2","patrol","patrol2","lexus3","taxi","taxi2","lambo","lambo2","lancer","bmw2","bmw3","lancer2","mustang3","wrangler") 
var vehicle_name:String = "pickup"

const SPEED = 20
const MAX_SPEED = 200
const V_MAX_SPEED = Vector2(MAX_SPEED,MAX_SPEED)

var stopped : bool = false
var tilemap: TileMapLayer
@onready var sprite: Sprite2D = $Move_collision/CarSprite
@onready var move_collision: CollisionShape2D = $Move_collision
enum STATE {DRIVING,TURNING}
enum {UP=0,RIGHT=1,DOWN=2,LEFT=3}
enum {HORZ,VERT,BOTH}
const V_DIR = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
const ROAD_DIR = ["Horz","Vert","Both","OffRoad"]
var direction :int
var v_direction:Vector2
var state
var turning_progress : float = 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = STATE.DRIVING
	#vehicle_name = vehicles.keys().pick_random()
	var vehicle_dict = vehicles[vehicle_name]
	var xy = vehicle_dict["xy"]
	var size = vehicle_dict["size"]
	sprite.texture = sprite.texture.duplicate()
	sprite.texture.region = Rect2(xy.x,xy.y,size.x,size.y)
	var road_dir :int = get_road_direction(global_position)
	match road_dir:
		HORZ:
			direction = [LEFT,RIGHT].pick_random()
		VERT:
			direction = [UP,DOWN].pick_random()
		BOTH:
			direction = [LEFT,RIGHT,UP,DOWN].pick_random()
	rotation=deg_to_rad(direction*90)
	v_direction = V_DIR[direction]
	$Move_collision.disabled = true
	stopped = true
	await get_tree().create_timer(randf_range(.25,1.25))
	$Move_collision.disabled = false
	stopped = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if stopped:
		return
		
		
	match state:
		STATE.TURNING:
			$Label.text = "%s - %s" % ["Both","Turning" if state == STATE.TURNING else "Driving"]
			var temp = rotation_degrees
			if temp < 0: temp += 360
			if temp > direction*90-1 and temp < direction*90+1:
					rotation_degrees = direction*90
					state = STATE.DRIVING
					get_tree().create_timer(.25).timeout.connect(func():turning_progress = 0)
			else:
				rotation = lerp_angle(rotation, deg_to_rad(direction*90), turning_progress) # move_toward(rotation,deg_to_rad(direction*90),3*delta)
				turning_progress = clamp(turning_progress + 3*delta,0,1)



		STATE.DRIVING:
			var road_dir :int = get_road_direction(global_position)
			if road_dir == 3: return queue_free()
			if road_dir == 0 and direction not in [LEFT,RIGHT]: 
				direction = [LEFT,RIGHT].pick_random()
				rotation=deg_to_rad(direction*90)
			if road_dir == 1 and direction not in [UP,DOWN]: 
				direction = [UP,DOWN].pick_random()
				rotation=deg_to_rad(direction*90)
			$Label.text = "%s - %s - %s" % [ROAD_DIR[road_dir],"Turning" if state == STATE.TURNING else "Driving", ["UP","RIGHT","DOWN","LEFT"][direction]]
			var mod:int
			if direction == LEFT or direction == RIGHT:
				mod = (int(position.x) % 64)
				lock_y_32()
			else:
				mod = (int(position.y) % 64)
				lock_x_32()
			if not turning_progress and road_dir == BOTH and 30 < mod and mod < 34:
				if direction == LEFT or direction == RIGHT:
					lock_x_32()
				else:
					lock_y_32()
				velocity = Vector2.ZERO
				new_direction(random_turn())
				state = STATE.TURNING
				return

	velocity = (velocity + v_direction*SPEED).clamp(-V_MAX_SPEED,V_MAX_SPEED)
	var temp_pos = position
	var collide = move_and_collide(velocity*delta)
	if collide:
		if collide.get_collider() is TileMapLayer:
			if state != STATE.TURNING:
				new_direction(-v_direction)
				rotate(deg_to_rad(180))
				position += v_direction*SPEED/2
		else:
			position = temp_pos
			velocity = Vector2.ZERO
			stopped = true
			var timer = get_tree().create_timer(randf_range(.75,1.5)).timeout.connect(end_collision)
		
	$Label.position = position + Vector2(-20,20)
	
	
func lock_x_32():
	position.x = snapped(position.x,32)
func lock_y_32():
	position.y = snapped(position.y,32)	

func random_turn():
	var directions = []
	for dir:Vector2 in V_DIR:
		var check_pos = global_position + dir*64
		if dir != -v_direction and get_road_direction(check_pos) != 3:
			directions.append(dir)
	return directions.pick_random()
		
func new_direction(new_dir):
	v_direction = new_dir
	match v_direction:
		Vector2.UP:
			direction = UP
		Vector2.DOWN:
			direction = DOWN
		Vector2.LEFT:
			direction = LEFT	
		Vector2.RIGHT:
			direction = RIGHT

func get_road_direction(g_pos):
	var pos = tilemap.to_local(g_pos)
	var coords = tilemap.local_to_map(pos)
	var data: TileData = tilemap.get_cell_tile_data(coords) 	# 0 == layer index
	return data.get_custom_data("Direction")
	
func end_collision():
	stopped = false
	collision_mask = 1
	get_tree().create_timer(.5).timeout.connect(func():collision_mask  = 3)
	
func set_sprite_horz(x_direction):
	if x_direction:
		sprite.flip_v = true if x_direction < 0 else false
		$Move_collision.rotation = 0
	
func set_sprite_vert(y_direction):
	if y_direction:
		sprite.flip_v = false
		$Move_collision.rotation = deg_to_rad(90 * y_direction / abs(y_direction))
