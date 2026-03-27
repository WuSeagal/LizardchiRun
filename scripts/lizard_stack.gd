extends Node2D

const LIZARD_COUNT   = 21
const SPAWN_X        = 120.0    # 畫面左邊靠邊，遠離堆疊區
const GROUND_Y       = 642.0    # 地面中心（膠囊半徑 14+高 4，地板頂 y=660）
const SPAWN_Y        = 530.0    # 從空中落下，避免出生點被凍結蜥蜴堵住

# 皮膚清單統一由 GameData autoload 管理

var skin_ids:        Array = []   # 21 個隨機皮膚 ID（未生成）
var spawned_lizards: Array = []   # 已出場的蜥蜴節點
var current_index:   int   = 0

func _ready() -> void:
	var pool: Array = GameData.ALL_SKINS.duplicate()
	pool.shuffle()
	skin_ids = pool.slice(0, LIZARD_COUNT)

	# 第 22 個皮膚給終點平台的蜥蜴（不在 21 隻之中）
	if pool.size() > LIZARD_COUNT:
		var goal_skin: String = pool[LIZARD_COUNT]
		var goal_tex       := load("res://assets/skin/images/%s_sad.png"  % goal_skin) as Texture2D
		var goal_happy_tex := load("res://assets/skin/images/%s_happy.png" % goal_skin) as Texture2D
		var goal_platform = get_parent().get_node_or_null("GoalPlatform")
		if goal_platform != null and goal_tex != null:
			goal_platform.goal_lizard_tex       = goal_tex
			goal_platform.goal_lizard_happy_tex = goal_happy_tex
			goal_platform.queue_redraw()

	# 只生成第一隻，其他等輪到才出現
	_spawn_and_activate(0)

func _spawn_and_activate(index: int) -> void:
	var sid: String = skin_ids[index]
	var liz = load("res://scenes/lizard.tscn").instantiate()
	liz.position = Vector2(SPAWN_X, SPAWN_Y)
	add_child(liz)
	liz.setup(
		load("res://assets/skin/images/%s_normal.png" % sid),
		load("res://assets/skin/images/%s_faint.png"  % sid),
		load("res://assets/skin/images/%s_happy.png"  % sid),
		load("res://assets/skin/images/%s_sad.png"    % sid)
	)
	spawned_lizards.append(liz)
	liz.activate()

func freeze_current_and_next() -> void:
	if current_index >= spawned_lizards.size():
		return

	spawned_lizards[current_index].freeze()
	current_index += 1

	if current_index >= LIZARD_COUNT:
		get_parent().on_all_lizards_frozen()
	else:
		_spawn_and_activate(current_index)

func remaining() -> int:
	return LIZARD_COUNT - current_index

func show_all_happy() -> void:
	for liz in spawned_lizards:
		liz.show_happy()

func show_all_sad() -> void:
	for liz in spawned_lizards:
		liz.show_sad()
