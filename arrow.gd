extends Sprite2D
var time_passed = 0.0
const BLINK_SPEED = 8


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	time_passed += delta
	# Generate a smooth alpha value oscillating between 0 and 1
	var new_alpha = .4 + .3 * sin(time_passed * BLINK_SPEED)  # Adjust 2.0 for speed
	new_alpha = pow(new_alpha,2)
	var color = material.get_shader_parameter("color")
	color.a = new_alpha  # Update alpha
	material.set_shader_parameter("color", color)
