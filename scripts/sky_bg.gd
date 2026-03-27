extends Node2D

func _draw() -> void:
	var sky_top := Color(0.28, 0.55, 0.90)
	var sky_bot := Color(0.76, 0.89, 0.98)
	var steps   := 24
	var total_h := 720.0
	for i in range(steps):
		var t  := float(i) / steps
		var y  := t * total_h
		var dy := total_h / steps + 1.0
		draw_rect(Rect2(0.0, y, 1280.0, dy), sky_top.lerp(sky_bot, t))
