extends Control

@export var game_scene: PackedScene

@onready var play_button: Button = %PlayButton

func _ready() -> void:
	assert( game_scene != null, "Game scene must be specified on Tilte Menu root node." )
	play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)
