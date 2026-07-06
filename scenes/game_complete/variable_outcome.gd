class_name VariableOutcome extends HBoxContainer

@onready var variable_name_label: Label = %VariableNameLabel
@onready var variable_value_label: Label = %VariableValueLabel


func set_variable_data(var_name: String, value: Variant) -> void:
	if not is_node_ready(): await ready
	
	variable_name_label.text = var_name
	variable_value_label.text = str(value)
