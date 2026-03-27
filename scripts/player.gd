extends CharacterBody2D

const SPEED = 320.0
const JUMP_VELOCITY = -680.0
const GRAVITY = 1500.0

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	# 重力：不在地上就持續往下加速
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 跳躍：踩在地上才能跳（空白鍵 或 上方向鍵）
	if is_on_floor() and (
		Input.is_action_just_pressed("ui_accept") or
		Input.is_action_just_pressed("ui_up")
	):
		velocity.y = JUMP_VELOCITY

	# 左右移動
	var dir := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir -= 1.0

	velocity.x = dir * SPEED

	# 翻轉（圖片預設朝左）
	if dir > 0:
		sprite.flip_h = true
	elif dir < 0:
		sprite.flip_h = false

	move_and_slide()

	# 左右邊界限制
	var vp := get_viewport_rect().size
	position.x = clamp(position.x, 20.0, vp.x - 20.0)
