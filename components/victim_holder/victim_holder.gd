class_name VictimHolder extends Node2D

signal crash


@onready var inaction_victims: HBoxContainer = $InactionVictimHolder/InactionVictims
@onready var intervene_victims: HBoxContainer = $InterventionVictimHolder/InterveneVictims
@onready var area_2d: Area2D = $Area2D


func set_victim_count(inaction: int, intervention: int) -> void:
	_set_container_victim_count(inaction_victims, inaction)
	_set_container_victim_count(intervene_victims, intervention)


func _ready() -> void:
	area_2d.area_entered.connect(_on_area_entetred)


func _set_container_victim_count(container: BoxContainer, victim_count: int) -> void:
	var potential_victims := container.get_children()
	for child in potential_victims:
		child.hide()
	
	var clamped_victim_count: int = mini( victim_count, potential_victims.size() )
	
	for i in range( 0, clamped_victim_count):
		potential_victims[i].show()


func _on_area_entetred(area: Area2D) -> void:
	if area is TrolleyArea2D:
		crash.emit()
