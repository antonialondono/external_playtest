class_name PathWithLine extends Path2D

const INACTIVE_COLOR: Color = Color.MEDIUM_SLATE_BLUE
const ACTIVE_COLOR: Color = Color.MEDIUM_SPRING_GREEN

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	line_2d.default_color = INACTIVE_COLOR
	line_2d.points = curve.get_baked_points()

func set_active(is_active: bool) -> void:
	if is_active:
		line_2d.default_color = ACTIVE_COLOR
	else:
		line_2d.default_color = INACTIVE_COLOR
