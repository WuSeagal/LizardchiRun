extends StaticBody2D

@export var platform_size: Vector2 = Vector2(200, 22)
@export var platform_color: Color = Color(0.5, 0.32, 0.1, 1)
@export var platform_texture: Texture2D = null
@export var is_goal: bool = false
@export var goal_lizard_tex: Texture2D = null
var goal_lizard_happy_tex: Texture2D = null

var current_speech: String = ""
var _cycling: bool = false

func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	col.shape = shape
	add_child(col)

	if is_goal:
		_start_speech_cycle()

func _draw() -> void:
	var half := platform_size / 2.0
	var rect := Rect2(-half, platform_size)

	if is_goal:
		_draw_goal_platform(half)
	elif platform_texture != null:
		draw_texture_rect(platform_texture, rect, true)
		draw_line(
			Vector2(-half.x, -half.y),
			Vector2( half.x, -half.y),
			Color(0.25, 0.15, 0.05, 0.8), 3.0
		)
	else:
		draw_rect(rect, platform_color)

# ── 終點平台 ───────────────────────────────────────────

func _draw_goal_platform(half: Vector2) -> void:
	# 平台主體
	draw_rect(Rect2(-half, platform_size), Color(0.82, 0.60, 0.04, 1))
	draw_rect(Rect2(-half, Vector2(platform_size.x, platform_size.y * 0.45)),
			  Color(1.0, 0.87, 0.22, 1))
	draw_rect(Rect2(Vector2(-half.x, half.y - 5.0), Vector2(platform_size.x, 5.0)),
			  Color(0.55, 0.38, 0.02, 1))
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			  Color(1.0, 0.96, 0.6, 1), 3.0)

	var top_y := -half.y

	# 角落小星星
	_draw_star(Vector2(-half.x + 14, top_y - 10), 5.5, 2.5, Color(1.0, 0.93, 0.25, 0.90))
	_draw_star(Vector2( half.x - 14, top_y - 10), 5.5, 2.5, Color(1.0, 0.93, 0.25, 0.90))

	# 蜥蜴圖示坐在平台上（134×134，同玩家尺寸）
	if goal_lizard_tex != null:
		draw_texture_rect(goal_lizard_tex,
			Rect2(-67.0, top_y - 79.0, 134.0, 134.0), false)

	# 說話泡泡（渲染在蜥蜴右側）
	if current_speech != "":
		_draw_speech_bubble(top_y)

func _draw_speech_bubble(top_y: float) -> void:
	var font  := ThemeDB.fallback_font
	var fsize := 15

	var tw := font.get_string_size(current_speech, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var bw := maxf(tw + 18.0, 76.0)
	var bh := 26.0

	# 泡泡在蜥蜴右側（蜥蜴右緣 local x = +67）
	var bx := 72.0
	var by := top_y - 55.0   # 大約蜥蜴頭部高度

	# 泡泡背景
	draw_rect(Rect2(bx, by, bw, bh), Color(1, 1, 1, 0.93), true)
	draw_rect(Rect2(bx, by, bw, bh), Color(0.55, 0.38, 0.18, 0.65), false, 1.5)
	# 左側尖角（指向蜥蜴）
	var mid_y := by + bh / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx,     mid_y - 5),
		Vector2(bx,     mid_y + 5),
		Vector2(bx - 8, mid_y),
	]), Color(1, 1, 1, 0.93))
	# 文字
	var tx := bx + (bw - tw) / 2.0
	var ty := by + fsize + 3.0
	draw_string(font, Vector2(tx, ty), current_speech,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.15, 0.08, 0.03, 1))

func _draw_star(center: Vector2, outer_r: float, inner_r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + i * PI / 5.0
		var r := outer_r if i % 2 == 0 else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)

# ── 說話循環 ───────────────────────────────────────────

func _start_speech_cycle() -> void:
	_cycling = true
	_next_speech()

func _next_speech() -> void:
	if not _cycling or not is_inside_tree():
		return
	var phrases := [tr("SPEECH_1"), tr("SPEECH_2")]
	current_speech = phrases[randi() % phrases.size()]
	queue_redraw()
	await get_tree().create_timer(2.8).timeout
	if not _cycling or not is_inside_tree():
		return
	current_speech = ""
	queue_redraw()
	await get_tree().create_timer(randf_range(1.2, 2.4)).timeout
	_next_speech()

func say_win() -> void:
	_cycling = false
	if goal_lizard_happy_tex != null:
		goal_lizard_tex = goal_lizard_happy_tex
	current_speech = tr("SPEECH_WIN")
	queue_redraw()

func say_lose() -> void:
	_cycling = false
	current_speech = tr("SPEECH_LOSE")
	queue_redraw()
