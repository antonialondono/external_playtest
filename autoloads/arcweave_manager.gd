extends ArcweaveManagerInstance

@export_file_path("*.json") var arcweave_project_json: String


func goto_next_element(element: ArcweaveElement) -> ArcweaveElement:
	if element.outputs.size() < 1: return null
	
	var default_connection: ArcweaveConnection = project.connections.get(element.outputs[0])
	if default_connection == null:
		return null
	
	return follow_connection(default_connection)


func follow_connection(connection: ArcweaveConnection) -> ArcweaveElement:
	if connection == null:
		push_error("Invalid choice: no connection")
		return null

	var target_id := _get_target_id_from_connection(connection)

	if target_id == "":
		push_error("Invalid choice: no target_id")
		return null

	var raw_label := connection.label

	# Arcweave original
	if auto_evaluate_scripts and raw_label != "":
		var preprocessed = ArcweaveUtils.preprocess_arcscript_html(raw_label)
		interpreter.evaluate(preprocessed, false)

	return goto_element(target_id)


func get_connection_target_element(connection: ArcweaveConnection) -> ArcweaveElement:
	var target_id := _get_target_id_from_connection(connection)
	if target_id == "":
		return null

	return get_element(target_id)


func _get_target_id_from_connection(connection: ArcweaveConnection) -> String:
	if connection == null:
		return ""

	var resolved_target := _get_target_from_connection(connection.id)
	if resolved_target != "":
		return resolved_target

	return connection.targetid

func _ready() -> void:
	if not arcweave_project_json.is_empty():
		if not load_project_from_file(arcweave_project_json):
			printerr("Invalid project file passed: %s" % arcweave_project_json)
			return
	else:
		printerr("No project specified in %s" % scene_file_path)
		return
	
	# we will manage this manually
	present_choices = false
	reset()


func reset() -> void:
	state.reset(project.initial_variables)
