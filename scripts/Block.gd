class_name Block
extends Node2D
## A single stack block. Used both for the piece currently falling/sliding
## and for every block already resting on the tower. `position` is treated
## as the block's CENTER point, which makes width trimming and centering
## math simple.

@export var color: Color = Color(0.35, 0.75, 0.95)
@export var height: float = 44.0

var width: float = 260.0:
	set(value):
		width = max(value, 0.0)
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(-width / 2.0, -height / 2.0), Vector2(width, height))
	draw_rect(rect, color, true)
	draw_rect(rect, color.darkened(0.3), false, 2.0)

func set_width(new_width: float) -> void:
	width = new_width
