extends Node2D

const TURN_TIME       := 7.0
const R_HOLD_DURATION := 2.0
const _CUBIC11 := preload("res://assets/fonts/Cubic_11.woff2")

@onready var overlay:            ColorRect   = $CanvasLayer/Overlay
@onready var timer_label:        Label       = $CanvasLayer/TimerPanel/TimerLabel
@onready var timer_bar:          ProgressBar = $CanvasLayer/TimerPanel/TimerBar
@onready var counter_label:      Label       = $CanvasLayer/CounterPanel/CounterLabel
@onready var lizard_icon:        TextureRect = $CanvasLayer/CounterPanel/LizardIcon
@onready var hint_label:         Label       = $CanvasLayer/HintPanel/HintLabel
@onready var rules_hint_btn:     Button      = $CanvasLayer/RulesHintBtn
@onready var r_hold_bar:         ProgressBar = $CanvasLayer/RHoldBar
@onready var emoji_layer:        Control     = $CanvasLayer/EmojiLayer
@onready var result_panel:       Panel       = $CanvasLayer/ResultPanel
@onready var result_title:       Label       = $CanvasLayer/ResultPanel/ResultTitle
@onready var retry_btn:          Button      = $CanvasLayer/ResultPanel/RetryButton
@onready var home_btn:           Button      = $CanvasLayer/ResultPanel/HomeButton
@onready var treasure_btn:       Button      = $CanvasLayer/ResultPanel/TreasureButton
@onready var treasure_container: Control     = $CanvasLayer/TreasureContainer
@onready var rules_container:    Control     = $CanvasLayer/RulesContainer
@onready var volume_btn:         Button      = $CanvasLayer/VolumeBtn
@onready var volume_panel:       Panel       = $CanvasLayer/VolumePanel
@onready var volume_slider:      HSlider     = $CanvasLayer/VolumePanel/VolumeSlider
@onready var volume_label:       Label       = $CanvasLayer/VolumePanel/VolumeLabel
@onready var restart_btn:        Button      = $CanvasLayer/RestartBtn
@onready var lang_btn:           Button      = $CanvasLayer/LangBtn
@onready var rules_title_label:  Label       = $CanvasLayer/RulesContainer/RulesPanel/RulesTitleLabel
@onready var rules_label:        Label       = $CanvasLayer/RulesContainer/RulesPanel/RulesLabel
@onready var rules_close_btn:    Button      = $CanvasLayer/RulesContainer/RulesPanel/CloseButton
@onready var treasure_label:     Label       = $CanvasLayer/TreasureContainer/TreasurePanel/TreasureLabel
@onready var treasure_ok_btn:    Button      = $CanvasLayer/TreasureContainer/TreasurePanel/OkButton
@onready var touch_left:         Control     = $CanvasLayer/TouchLeft
@onready var touch_right:        Control     = $CanvasLayer/TouchRight
@onready var jump_btn:           Button      = $CanvasLayer/TouchRight/JumpBtn
@onready var left_btn:           Button      = $CanvasLayer/TouchLeft/LeftBtn
@onready var right_btn:          Button      = $CanvasLayer/TouchLeft/RightBtn
@onready var speed_btn:          Button      = $CanvasLayer/TouchRight/SpeedBtn
@onready var goal_platform                   = $GoalPlatform
@onready var goal_area:          Area2D      = $GoalArea
@onready var lizard_stack                    = $LizardStack
@onready var bgm_player:         AudioStreamPlayer = $BGMPlayer
@onready var sfx_player:         AudioStreamPlayer = $SFXPlayer

var time_left:   float = TURN_TIME
var game_active: bool  = false
var rules_open:  bool  = false
var r_hold_time: float = 0.0
var anim_active: bool  = false
var cubic11: FontFile  = null
var _muted: bool       = false
var _touch_actions: Dictionary = {}   # finger_index → action String

# GameOver emoji 位置追蹤（防重疊）
var active_emoji_pos: Array = []

func _ready() -> void:
	lizard_icon.texture = load("res://assets/skin/images/N000_normal.png")
	var bgm_stream := load("res://assets/audio/Sun_Baked_Leap.mp3") as AudioStreamMP3
	bgm_stream.loop   = true
	bgm_player.stream = bgm_stream
	sfx_player.stream = load("res://assets/audio/Yabi.mp3")
	jump_btn.icon = load("res://assets/icons/backflip.png")
	var is_touch := DisplayServer.is_touchscreen_available()
	touch_left.visible  = is_touch
	touch_right.visible = is_touch
	_load_font()

	overlay.modulate.a         = 1.0
	result_panel.visible       = false
	treasure_btn.visible       = false
	treasure_container.visible = false
	r_hold_bar.visible         = false
	r_hold_bar.max_value       = R_HOLD_DURATION
	r_hold_bar.value           = 0.0
	timer_bar.max_value        = TURN_TIME
	rules_container.visible    = false
	volume_panel.visible       = false

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		game_active = true
		bgm_player.play()
	)
	Lang.locale_changed.connect(_refresh_texts)
	_refresh_texts()
	_update_ui()

# ── 字型 ──────────────────────────────────────────────

func _load_font() -> void:
	cubic11 = _CUBIC11 as FontFile
	if cubic11 == null:
		return
	# Windows 系統字型 fallback：seguiemj=emoji，seguisym=符號(↺等)
	# 把這兩個檔從 C:\Windows\Fonts\ 複製到 assets/fonts/ 即可自動生效。
	var _fallbacks: Array[Font] = []
	for _path in ["res://assets/fonts/NotoColorEmoji-Regular.ttf", "res://assets/fonts/seguisym.ttf"]:
		var _f := load(_path) as Font
		if _f:
			_fallbacks.append(_f)
	if not _fallbacks.is_empty():
		cubic11.set_fallbacks(_fallbacks)
	# 全域套用，platform.gd 的 draw_string 也會用到正確字型。
	ThemeDB.fallback_font = cubic11
	for node in [timer_label, counter_label, hint_label, rules_hint_btn,
				 result_title, retry_btn, home_btn, treasure_btn,
				 left_btn, right_btn, volume_btn, restart_btn, lang_btn]:
		if node:
			node.add_theme_font_override("font", cubic11)
	# 補上所有含文字的容器（VolumePanel 的「音量」標籤、TouchRight 的 3S 等）
	_apply_font_recursive(volume_panel)
	_apply_font_recursive(touch_right)
	_apply_font_recursive(rules_container)
	_apply_font_recursive(treasure_container)

func _apply_font_recursive(node: Node) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_override("font", cubic11)
	for child in node.get_children():
		_apply_font_recursive(child)

# ── 輸入 ──────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if volume_panel.visible:
		if event is InputEventMouseButton and event.pressed:
			volume_panel.visible = false
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			volume_panel.visible = false
	if treasure_container.visible:
		return
	if rules_open:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_rules()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and game_active and time_left > 3.0:
			time_left = 3.0

# ── 主循環 ────────────────────────────────────────────

func _process(delta: float) -> void:
	if volume_panel.visible:
		var mp := get_viewport().get_mouse_position()
		if not volume_btn.get_global_rect().has_point(mp) and \
		   not volume_panel.get_global_rect().has_point(mp):
			volume_panel.visible = false

	if rules_open or treasure_container.visible or not game_active:
		if not game_active:
			r_hold_bar.visible = false
			r_hold_time = 0.0
		return

	if Input.is_key_pressed(KEY_R):
		r_hold_time += delta
		r_hold_bar.visible = true
		r_hold_bar.value   = r_hold_time
		if r_hold_time >= R_HOLD_DURATION:
			get_tree().reload_current_scene()
			return
	else:
		r_hold_time = 0.0
		r_hold_bar.visible = false

	time_left -= delta
	_update_ui()
	if time_left <= 0.0:
		time_left = TURN_TIME
		# Check goal area BEFORE freeze — freeze() changes collision_layer and
		# would remove the lizard from the area's detection before body_entered fires.
		for body in goal_area.get_overlapping_bodies():
			if body.is_in_group("lizard"):
				_win()
				return
		lizard_stack.freeze_current_and_next()

func _refresh_texts() -> void:
	lang_btn.text          = Lang.btn_label()
	hint_label.text        = tr("HINT_CONTROLS")
	rules_hint_btn.text    = tr("BTN_RULES_SHORT")
	volume_label.text      = tr("LABEL_VOLUME")
	rules_title_label.text = tr("RULES_TITLE")
	rules_label.text       = tr("RULES_BODY")
	rules_close_btn.text   = tr("BTN_CLOSE")
	retry_btn.text         = tr("BTN_RETRY")
	home_btn.text          = tr("BTN_HOME")
	treasure_btn.text      = tr("BTN_TREASURE")
	treasure_label.text    = tr("TREASURE_TEXT")
	treasure_ok_btn.text   = tr("BTN_OK")

func _on_lang_btn_pressed() -> void:
	Lang.toggle()
	lang_btn.release_focus()

func _update_ui() -> void:
	timer_label.text   = tr("TIMER_FMT") % ceili(time_left)
	timer_bar.value    = time_left
	counter_label.text = tr("COUNTER_FMT") % (22 - lizard_stack.remaining())

# ── 視窗焦點（失焦凍結）────────────────────────────────

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			Input.action_release("ui_accept")
			get_tree().paused        = true
			bgm_player.stream_paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			get_tree().paused       = false
			bgm_player.stream_paused = false

# ── 音量 ──────────────────────────────────────────────

func _on_volume_btn_mouse_entered() -> void:
	volume_panel.visible = true

func _on_volume_btn_pressed() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(0, _muted)
	volume_btn.text = "🔇" if _muted else "🔊"
	volume_btn.release_focus()

func _on_volume_slider_value_changed(value: float) -> void:
	var db := linear_to_db(value) if value > 0.001 else -80.0
	AudioServer.set_bus_volume_db(0, db)
	if _muted:
		_muted = false
		AudioServer.set_bus_mute(0, false)
		volume_btn.text = "🔊"

# ── 虛擬按鍵多點觸控 ──────────────────────────────────

func _input(event: InputEvent) -> void:
	if not touch_left.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var act := _touch_action_at(event.position)
			if act != "":
				_touch_actions[event.index] = act
				_apply_virtual_action(act, true)
		else:
			if _touch_actions.has(event.index):
				_apply_virtual_action(_touch_actions[event.index], false)
				_touch_actions.erase(event.index)
	elif event is InputEventScreenDrag:
		var new_act := _touch_action_at(event.position)
		var old_act: String = _touch_actions.get(event.index, "")
		if new_act != old_act:
			if old_act != "":
				_apply_virtual_action(old_act, false)
				_touch_actions.erase(event.index)
			if new_act != "":
				_touch_actions[event.index] = new_act
				_apply_virtual_action(new_act, true)

func _touch_action_at(pos: Vector2) -> String:
	if left_btn.get_global_rect().has_point(pos):  return "ui_left"
	if right_btn.get_global_rect().has_point(pos): return "ui_right"
	if jump_btn.get_global_rect().has_point(pos):  return "ui_accept"
	if speed_btn.get_global_rect().has_point(pos): return "speed_btn"
	return ""

func _apply_virtual_action(act: String, pressed: bool) -> void:
	match act:
		"ui_left":
			if pressed: 
				Input.action_press("ui_left")
			else: 
				Input.action_release("ui_left")
		"ui_right":
			if pressed: 
				Input.action_press("ui_right")
			else: 
				Input.action_release("ui_right")
		"ui_accept":
			if pressed: 
				Input.action_press("ui_accept")
			else: 
				Input.action_release("ui_accept")
		"speed_btn":
			if pressed: 
				_on_speed_btn_pressed()

# ── 虛擬按鍵 ──────────────────────────────────────────

func _on_restart_btn_pressed() -> void:
	get_tree().reload_current_scene()

func _on_left_btn_down() -> void:
	Input.action_press("ui_left")

func _on_left_btn_up() -> void:
	Input.action_release("ui_left")

func _on_right_btn_down() -> void:
	Input.action_press("ui_right")

func _on_right_btn_up() -> void:
	Input.action_release("ui_right")

func _on_jump_btn_down() -> void:
	Input.action_press("ui_accept")

func _on_jump_btn_up() -> void:
	Input.action_release("ui_accept")

func _on_speed_btn_pressed() -> void:
	if game_active and time_left > 3.0:
		time_left = 3.0

# ── 規則 ──────────────────────────────────────────────

func _on_rules_button_pressed() -> void:
	rules_open = true
	rules_container.visible = true

func _on_rules_close_pressed() -> void:
	_close_rules()

func _close_rules() -> void:
	rules_open = false
	rules_container.visible = false

# ── 大秘寶 ────────────────────────────────────────────

func _on_treasure_pressed() -> void:
	treasure_container.visible = true

func _on_treasure_ok_pressed() -> void:
	treasure_container.visible = false

# ── 過關 ──────────────────────────────────────────────

func _on_goal_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("lizard"):
		_win()

func _win() -> void:
	if not game_active:
		return
	game_active = false
	anim_active = true
	lizard_stack.show_all_happy()
	goal_platform.say_win()
	sfx_player.play()
	result_title.text    = tr("RESULT_WIN")
	treasure_btn.visible = true
	_layout_result(true)
	result_panel.visible = true
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.45, 1.5)
	tween.tween_callback(_start_win_animation)

# ── 失敗 ──────────────────────────────────────────────

func on_all_lizards_frozen() -> void:
	if not game_active:
		return
	game_active = false
	anim_active = true
	lizard_stack.show_all_sad()
	goal_platform.say_lose()
	result_title.text    = tr("RESULT_LOSE")
	_layout_result(false)
	result_panel.visible = true
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.45, 1.5)
	tween.tween_callback(_start_gameover_animation)

# ── 結果版面（flex 均分高度） ─────────────────────────

func _layout_result(is_win: bool) -> void:
	if is_win:
		# 3 列：標題 / 兩按鈕 / 大秘寶
		_set_ctrl(result_title,  0,   16, 600,  96)   # 80px
		_set_ctrl(retry_btn,     28, 118, 272, 168)   # 50px
		_set_ctrl(home_btn,     328, 118, 572, 168)
		_set_ctrl(treasure_btn, 100, 192, 500, 242)   # 50px
	else:
		# 2 列：標題 / 兩按鈕（垂直置中）
		_set_ctrl(result_title,  0,   35, 600, 115)   # 80px
		_set_ctrl(retry_btn,     28, 165, 272, 215)   # 50px
		_set_ctrl(home_btn,     328, 165, 572, 215)

func _set_ctrl(node: Control, l: float, t: float, r: float, b: float) -> void:
	node.offset_left   = l
	node.offset_top    = t
	node.offset_right  = r
	node.offset_bottom = b

# ── 結果按鈕 ──────────────────────────────────────────

func _on_retry_pressed() -> void:
	anim_active = false
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	anim_active = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")

# ── 通關動畫（持續循環）───────────────────────────────

func _start_win_animation() -> void:
	_loop_falling_lizard()
	_loop_confetti_left()
	_loop_confetti_right()

func _loop_falling_lizard() -> void:
	if not anim_active or not is_instance_valid(emoji_layer):
		return
	_create_falling_emoji("🦎", randf_range(40.0, 1240.0))
	create_tween().tween_interval(randf_range(0.4, 0.75)).connect("finished",
		func(): _loop_falling_lizard())

func _loop_confetti_left() -> void:
	if not anim_active or not is_instance_valid(emoji_layer):
		return
	var emojis := ["🎊", "🎉", "🙏", "✨"]
	# 從左下角向右上方噴出
	_create_corner_emoji(emojis[randi() % emojis.size()],
		Vector2(30, 640),
		Vector2(randf_range(60, 260), randf_range(-430, -180)))
	create_tween().tween_interval(randf_range(0.20, 0.45)).connect("finished",
		func(): _loop_confetti_left())

func _loop_confetti_right() -> void:
	if not anim_active or not is_instance_valid(emoji_layer):
		return
	var emojis := ["🎊", "🎉", "🙏", "✨"]
	# 從右下角向左上方噴出
	_create_corner_emoji(emojis[randi() % emojis.size()],
		Vector2(1210, 640),
		Vector2(randf_range(-260, -60), randf_range(-430, -180)))
	create_tween().tween_interval(randf_range(0.20, 0.45)).connect("finished",
		func(): _loop_confetti_right())

func _create_falling_emoji(emoji: String, x: float) -> void:
	if not is_instance_valid(emoji_layer):
		return
	var lbl := Label.new()
	lbl.text = emoji
	if cubic11: lbl.add_theme_font_override("font", cubic11)
	lbl.add_theme_font_size_override("font_size", 50)
	lbl.position = Vector2(x, -70.0)
	emoji_layer.add_child(lbl)

	var land_y := randf_range(140.0, 600.0)
	var tween   := create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "position:y", land_y, randf_range(1.4, 2.2))
	tween.tween_interval(3.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(lbl.queue_free)

func _create_corner_emoji(emoji: String, start: Vector2, vel: Vector2) -> void:
	if not is_instance_valid(emoji_layer):
		return
	var lbl := Label.new()
	lbl.text = emoji
	if cubic11: lbl.add_theme_font_override("font", cubic11)
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.position = start
	emoji_layer.add_child(lbl)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(lbl, "position", start + vel, 1.1)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.1)
	tween.chain().tween_callback(lbl.queue_free)

# ── GameOver 動畫（持續循環，防重疊，避開結果區）─────

func _start_gameover_animation() -> void:
	_loop_gameover_emoji()

func _loop_gameover_emoji() -> void:
	if not anim_active or not is_instance_valid(emoji_layer):
		return
	var sad_emojis := ["😭", "🥲", "🫠"]
	_create_growing_emoji(sad_emojis[randi() % sad_emojis.size()])
	create_tween().tween_interval(randf_range(1.0, 1.8)).connect("finished",
		func(): _loop_gameover_emoji())

func _create_growing_emoji(emoji: String) -> void:
	if not is_instance_valid(emoji_layer):
		return

	# 尋找不重疊、不在結果面板區的位置
	# ResultPanel 螢幕區域：(340,230)~(940,500)
	var pos := Vector2.ZERO
	var min_dist := 130.0
	for _i in range(20):
		var candidate := Vector2(randf_range(30.0, 1180.0), randf_range(30.0, 640.0))
		var in_panel := (candidate.x > 310 and candidate.x < 970
						 and candidate.y > 200 and candidate.y < 530)
		var too_close := false
		for ep in active_emoji_pos:
			if candidate.distance_to(ep) < min_dist:
				too_close = true
				break
		if not in_panel and not too_close:
			pos = candidate
			break

	if pos == Vector2.ZERO:   # 找不到空位就跳過
		return

	active_emoji_pos.append(pos)

	var lbl := Label.new()
	lbl.text = emoji
	if cubic11: lbl.add_theme_font_override("font", cubic11)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.scale    = Vector2(0.2, 0.2)
	lbl.position = pos
	emoji_layer.add_child(lbl)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "scale", Vector2(1.8, 1.8), 2.2)
	tween.tween_interval(3.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(func():
		active_emoji_pos.erase(pos)
		lbl.queue_free()
	)
