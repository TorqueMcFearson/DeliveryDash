extends Control

var tutorial_step :int = 0
@onready var ts_nodes :Array[Label] = [$Rating, $Money, $Controls, $"Gas Text", $Phone]
# Called when the node enters the scene tree for the first time.
func _ready():
	for node in ts_nodes: node.hide()

func _input(event: InputEvent) -> void:
	if UI.tutorial \
	and UI.tutorial_enabled \
	and event.is_pressed() \
	and event is InputEventMouseButton \
	or event.is_action_pressed("pause"):
		var click_label = $"Click To Continue"
		if tutorial_step < len(ts_nodes):
			var node = ts_nodes[tutorial_step]
			if tutorial_step < len(ts_nodes) -1:
				click_label.position = node.position + Vector2((node.size.x-click_label.size.x)/2,node.size.y + 5)
			else:
				click_label.text = "Click to Complete"
				click_label.position = get_viewport_rect().get_center()-Vector2(click_label.size.x/2,0)
			node.show()
			tutorial_step += 1
		else:
			unpause()

func unpause():
	print("UNPAUSE")
	$"../Pause Dimmer".hide()
	get_viewport().set_input_as_handled()
	$"../Options".get_child(0).unpause()
	UI.tutorial = false
	self.hide()
	$"Click To Continue".text = "-Game Paused-"
	#queue_free()
	get_tree().paused = false
