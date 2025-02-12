extends HSlider

@onready var audio_bus = AudioServer.get_bus_index(name)
@onready var save_timer: Timer = $"../../SaveTimer"

# Called when the node enters the scene tree for the first time.
func _ready():
	update()
	value_changed.connect(_on_value_changed)
	ready_label()


func update():
	set_value_no_signal(sqrt(db_to_linear(AudioServer.get_bus_volume_db(audio_bus)))*100)
	ready_label()
	
func ready_label():
	$Value.text = str(value)
	if value <10:
		$Value.hide()
		#$Value.size.x= 10
		#$Value.position.x = -10
		#$Value.add_theme_color_override("font_color",Color("white"))
	else:
		$Value.show()
		$Value.size.x= value
		$Value.position.x = 0
		$Value.add_theme_color_override("font_color",Color("black"))


func _on_value_changed(value):
	save_timer.start()
	AudioServer.set_bus_volume_db(audio_bus, linear_to_db(pow(value*.01,2)))
	ready_label()
	if name == "SFX" and $"../SFX/Timer".is_stopped():
		print("SFX FIRING")
		UI.play_sfx()
		$"../SFX/Timer".start()
	
