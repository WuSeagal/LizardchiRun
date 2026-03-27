extends Node2D

@onready var overlay:        ColorRect  = $CanvasLayer/Overlay
@onready var lizard_sleep:   TextureRect = $CanvasLayer/LizardSleep
@onready var lizard_normal:  TextureRect = $CanvasLayer/LizardNormal
@onready var lizard_happy:   TextureRect = $CanvasLayer/LizardHappy
@onready var title_label:    Label       = $CanvasLayer/TitleLabel
@onready var subtitle_label: Label       = $CanvasLayer/SubtitleLabel
@onready var start_btn:      Button      = $CanvasLayer/StartButton
@onready var any_key_hint:   Label       = $CanvasLayer/AnyKeyHint
@onready var rules_btn:        Button    = $CanvasLayer/RulesButton
@onready var rules_container:  Control  = $CanvasLayer/RulesContainer
@onready var lang_btn:         Button   = $CanvasLayer/LangBtn
@onready var rules_title_label: Label  = $CanvasLayer/RulesContainer/RulesPanel/RulesTitleLabel
@onready var rules_label:      Label    = $CanvasLayer/RulesContainer/RulesPanel/RulesLabel
@onready var close_btn:        Button   = $CanvasLayer/RulesContainer/RulesPanel/CloseButton

var title_ready: bool = false  # 淡入完成後才接受任意鍵
const _CUBIC11 := preload("res://assets/fonts/Cubic_11.woff2")

var going_to_game: bool = false
var cubic11: FontFile = null

func _ready() -> void:
	_load_lizard_textures()
	_load_font()

	overlay.modulate.a = 1.0
	rules_container.visible = false

	Lang.locale_changed.connect(_refresh_texts)
	_refresh_texts()

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		title_ready = true
		_start_hint_pulse()
	)

func _load_lizard_textures() -> void:
	var sid: String = GameData.ALL_SKINS[randi() % GameData.ALL_SKINS.size()]
	lizard_sleep.texture  = load("res://assets/skin/images/%s_sleep.png"  % sid)
	lizard_normal.texture = load("res://assets/skin/images/%s_normal.png" % sid)
	lizard_happy.texture  = load("res://assets/skin/images/%s_happy.png"  % sid)

func _load_font() -> void:
	cubic11 = _CUBIC11 as FontFile
	if cubic11 == null:
		return
	var _fallbacks: Array[Font] = []
	for _path in ["res://assets/fonts/NotoColorEmoji-Regular.ttf", "res://assets/fonts/seguisym.ttf"]:
		var _f := load(_path) as Font
		if _f:
			_fallbacks.append(_f)
	if not _fallbacks.is_empty():
		cubic11.set_fallbacks(_fallbacks)
	ThemeDB.fallback_font = cubic11
	_apply_font_to(title_label)
	_apply_font_to(subtitle_label)
	_apply_font_to(start_btn)
	_apply_font_to(any_key_hint)
	_apply_font_to(rules_btn)
	_apply_font_to(lang_btn)
	_apply_font_recursive(rules_container)

func _apply_font_to(node: Control) -> void:
	if cubic11 and node:
		node.add_theme_font_override("font", cubic11)

func _apply_font_recursive(node: Node) -> void:
	if node is Label or node is Button:
		_apply_font_to(node as Control)
	for child in node.get_children():
		_apply_font_recursive(child)

func _input(event: InputEvent) -> void:
	if not title_ready or going_to_game:
		return
	if rules_container.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			rules_container.visible = false
		return
	# 任意鍵開始（排除單獨修飾鍵）
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var kc := key_event.keycode
		if kc in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META, KEY_CAPSLOCK,
				  KEY_NUMLOCK, KEY_SCROLLLOCK, KEY_ESCAPE]:
			return
		_go_to_game()

func _on_start_button_pressed() -> void:
	_go_to_game()

func _on_rules_button_pressed() -> void:
	rules_container.visible = true

func _on_rules_close_pressed() -> void:
	rules_container.visible = false

func _refresh_texts() -> void:
	lang_btn.text          = Lang.btn_label()
	subtitle_label.text    = tr("SUBTITLE")
	start_btn.text         = tr("BTN_START")
	any_key_hint.text      = tr("HINT_ANY_KEY")
	rules_btn.text         = tr("BTN_RULES")
	rules_title_label.text = tr("RULES_TITLE")
	rules_label.text       = tr("RULES_BODY")
	close_btn.text         = tr("BTN_CLOSE")

func _on_lang_btn_pressed() -> void:
	Lang.toggle()
	lang_btn.release_focus()

func _start_hint_pulse() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(any_key_hint, "modulate:a", 0.35, 0.75)
	tween.tween_property(any_key_hint, "modulate:a", 1.0, 0.75)

func _go_to_game() -> void:
	if going_to_game:
		return
	going_to_game = true
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
