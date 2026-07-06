extends GridContainer

const VARIABLE_OUTCOME: PackedScene = preload("uid://cuvpdvsuwp6h7")

@onready var return_to_title_button: Button = %ReturnToTitleButton

func _ready() -> void:
	return_to_title_button.pressed.connect(_on_return_to_title_pressed)
	
	for child in get_children():
		child.queue_free()
	
	for variable in ArcweaveManager.state.variables:
		var value = ArcweaveManager.get_variable(variable)
		
		# TODO: this is a temp filter to remove variables that are not in use.
		if not typeof(value) == TYPE_BOOL: continue
		
		var new_outcome: VariableOutcome = VARIABLE_OUTCOME.instantiate()
		new_outcome.set_variable_data(variable, value)
		add_child(new_outcome)

func _on_return_to_title_pressed() -> void:
	ArcweaveManager.reset()
	get_tree().change_scene_to_file("res://scenes/title/title_menu.tscn")
