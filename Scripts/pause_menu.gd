extends Panel
const ANIMATE_SPEED = .2
const OFFSET = 100
const PIVOT_OUT = Vector2(389/2,0)
const PIVOT_IN = Vector2(389/2,294)
@onready var options_menu: Panel = $"../Options Menu"
var just_options = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"..".show()
	self.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_resume_pressed() -> void:
	print("Resume")
	var pause_event = InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	#unpause()


	
func _on_options_pressed() -> void:
	animate_out(self,options_menu) 
	
	

func _on_main_menu_pressed() -> void:
	UI.to_main_menu()

func pause():
	animate_in(self)

func unpause():
	options_menu.hide()
	hide()
	
func show_options():
	animate_in(options_menu)
func hide_options():
	animate_out(options_menu)
	
func animate_out(obj:Panel,obj2:Panel=null):
	obj.pivot_offset = PIVOT_OUT
	var tween = create_tween().set_parallel(true)
	tween.tween_property(obj,"scale",Vector2(1,0),ANIMATE_SPEED).set_trans(Tween.TRANS_EXPO)
	if obj2:
		tween.tween_callback(animate_in.bind(obj2)).set_delay(ANIMATE_SPEED*.65)
	await tween.finished
	obj.hide()

func animate_in(obj2):
	obj2.pivot_offset = PIVOT_IN
	obj2.scale = Vector2(1,0)
	obj2.position = position
	obj2.show()
	create_tween().tween_property(obj2,"scale",Vector2.ONE,ANIMATE_SPEED).set_trans(Tween.TRANS_EXPO)
	

func _on_back_button_pressed() -> void:
	if just_options:
		animate_out(options_menu)
	else:
		animate_out(options_menu,self)  # Replace with function body.
