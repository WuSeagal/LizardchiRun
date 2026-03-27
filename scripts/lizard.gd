extends CharacterBody2D

enum State { WAITING, ACTIVE, FROZEN, HAPPY, SAD }
var state: State = State.WAITING

var normal_tex: Texture2D
var faint_tex:  Texture2D
var happy_tex:  Texture2D
var sad_tex:    Texture2D

const SPEED              = 280.0
const JUMP_VELOCITY      = -620.0   # 體型變大後跳躍稍低
const GRAVITY            = 1600.0   # 落下更快
const FLIP_SPEED_DEG     = 390.0    # 後空翻旋轉速度（deg/s）

var is_flipping: bool = false

@onready var sprite:    Sprite2D          = $Sprite2D
@onready var col_shape: CollisionShape2D  = $CollisionShape2D

func _ready() -> void:
	add_to_group("lizard")
	set_physics_process(false)

func setup(n: Texture2D, f: Texture2D, h: Texture2D, s: Texture2D) -> void:
	normal_tex = n
	faint_tex  = f
	happy_tex  = h
	sad_tex    = s
	sprite.texture = normal_tex

# ── 狀態切換 ──────────────────────────────────────────

func activate() -> void:
	state = State.ACTIVE
	sprite.texture   = normal_tex
	sprite.modulate  = Color(1, 1, 1)
	sprite.rotation  = 0.0
	is_flipping      = false
	set_physics_process(true)
	queue_redraw()

func freeze() -> void:
	state = State.FROZEN
	sprite.texture  = faint_tex
	sprite.modulate = Color(1, 1, 1)
	sprite.rotation = 0.0
	is_flipping     = false
	velocity        = Vector2.ZERO
	set_physics_process(false)
	collision_layer = 1       # 變成地形，其他蜥蜴可以踩
	# faint sprite 橫躺：280×90px 原圖 × 0.2688 ≈ 75×24px
	# 用扁矩形取代膠囊，貼合躺平圖形
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72.0, 22.0)
	col_shape.shape = rect
	queue_redraw()

func show_happy() -> void:
	state = State.HAPPY
	sprite.texture  = happy_tex
	sprite.modulate = Color(1, 1, 1)
	sprite.rotation = 0.0
	is_flipping     = false
	set_physics_process(false)
	queue_redraw()

func show_sad() -> void:
	state = State.SAD
	sprite.texture  = sad_tex
	sprite.modulate = Color(1, 1, 1)
	sprite.rotation = 0.0
	is_flipping     = false
	set_physics_process(false)
	queue_redraw()

# ── 黃色箭頭指示器（只在 ACTIVE 時顯示）──────────────

func _draw() -> void:
	if state == State.ACTIVE:
		draw_colored_polygon(
			PackedVector2Array([Vector2(-10, -62), Vector2(10, -62), Vector2(0, -46)]),
			Color.YELLOW
		)

# ── 物理 / 輸入 ───────────────────────────────────────

func _physics_process(delta: float) -> void:
	if state != State.ACTIVE:
		return

	# 重力
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 左右移動（A/D 或 方向鍵）
	var x := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		x -= 1.0
	velocity.x = x * SPEED

	# 跳躍（空白鍵、↑、W）
	var jump_pressed: bool = (
		Input.is_action_just_pressed("ui_accept") or
		Input.is_action_just_pressed("ui_up") or
		Input.is_key_pressed(KEY_W)
	)
	if is_on_floor() and jump_pressed:
		velocity.y  = JUMP_VELOCITY
		is_flipping = true
		sprite.rotation = 0.0

	# 左右翻轉
	if x > 0:
		sprite.flip_h = true
	elif x < 0:
		sprite.flip_h = false

	# 後空翻旋轉（在空中時持續轉）
	if is_flipping:
		sprite.rotation -= deg_to_rad(FLIP_SPEED_DEG * delta)

	move_and_slide()

	# 落地後還原旋轉
	if is_flipping and is_on_floor():
		is_flipping     = false
		sprite.rotation = 0.0

	# 左右邊界
	var vp := get_viewport_rect().size
	position.x = clamp(position.x, 15.0, vp.x - 15.0)
