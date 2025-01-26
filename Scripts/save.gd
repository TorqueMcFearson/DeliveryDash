extends Node

func _ready() -> void:
	print(process_mode)
	load_preferences()
	
func save_preferences(_arg = null):
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	

	# Call the node's save function.
	var node_data = save()

	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(node_data)

	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)
	print ("SAVE COMPLETE: ",node_data)
		
func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"tutorial" : UI.tutorial, # Vector2 is not supported by JSON
		"tutorial_enabled" : UI.tutorial_enabled,
		"difficulty": UI.difficulty,
		"music_level" : AudioServer.get_bus_volume_db(1),
		"sfx_level" : AudioServer.get_bus_volume_db(2)
	}
	
	return save_dict
	
# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_preferences():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		
		print ("LOAD COMPLETE: ",node_data)
		
		#UI.tutorial = snappedi(node_data["tutorial"],10)
		UI.tutorial_enabled = node_data["tutorial_enabled"]
		UI.difficulty = node_data["difficulty"]
		AudioServer.set_bus_volume_db(1,node_data["music_level"])
		AudioServer.set_bus_volume_db(2,node_data["sfx_level"])
		
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			set(i, node_data[i])
