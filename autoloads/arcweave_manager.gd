extends ArcweaveManagerInstance

@export_file_path("*.json") var arcweave_project_json: String


func goto_next_element(element: ArcweaveElement) -> ArcweaveElement:
	if element.outputs.size() < 1: return null
	
	var default_connection: ArcweaveConnection = project.connections.get(element.outputs[0])
	
	return goto_element(default_connection.targetid)


func follow_connection(connection: ArcweaveConnection) -> ArcweaveElement:
	var target_id = connection.targetid

	if target_id == "":
		push_error("Invalid choice: no target_id")
		return null

	var raw_label := connection.label

	# Arcweave original
	if auto_evaluate_scripts and raw_label != "":
		var preprocessed = ArcweaveUtils.preprocess_arcscript_html(raw_label)
		interpreter.evaluate(preprocessed, false)

	return goto_element(target_id)

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
