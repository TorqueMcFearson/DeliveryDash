extends PanelContainer
signal resumed
const ANIMATE_SPEED = .2
const OFFSET = 100
const PIVOT_OUT = Vector2(389/2,0)
const PIVOT_IN = Vector2(389/2,294)
@onready var options_menu: Panel = %"Options Menu"
@onready var stuck_button: Button = $ButtonMargin/ButtonBox/Stuck
@onready var pause_focus_button: Button = $ButtonMargin/ButtonBox/Resume
@onready var options_focus_button: HSlider = $"../Options Menu/Sliders/Music"
var previous_focus : Node
var just_options = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$"..".show()
	self.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_resume_pressed() -> void:
	resumed.emit()
	#unpause()


	
func _on_options_pressed() -> void:
	await animate_out(self,options_menu) 
	options_focus_button.grab_focus()

func _on_main_menu_pressed() -> void:
	UI.to_main_menu()

func pause():
	$"../Options Menu/Sliders/Music".update()
	$"../Options Menu/Sliders/SFX".update()
	set_stuck_visibility()
	animate_in(self)
	

func unpause():
	options_menu.hide()
	if previous_focus: previous_focus.grab_focus()
	hide()
	
func show_options():
	animate_in(options_menu)
	options_focus_button.grab_focus()
	
	
func hide_options():
	animate_out(options_menu)
	
func animate_out(obj:Control,obj2:Control=null):
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
		resumed.emit()
	else:
		animate_out(options_menu,self)  # Replace with function body.

func set_stuck_visibility():
	stuck_button.visible = UI.is_on_map()
	size.y = 0
	


func _on_stuck_pressed() -> void:
	$"../../../Tutorial".unpause()
	UI.player.respawn()


func _on_pause_menu_show() -> void:
	if is_node_ready() and visible:
		previous_focus = get_viewport().gui_get_focus_owner()
		pause_focus_button.call_deferred("grab_focus") # Replace with function body.
