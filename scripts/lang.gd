extends Node

signal locale_changed

const _SAVE_PATH      := "user://settings.cfg"
const _DEFAULT_LOCALE := "zh_TW"

var current_locale: String = _DEFAULT_LOCALE

func _ready() -> void:
	_load_pref()
	TranslationServer.set_locale(current_locale)

func toggle() -> void:
	current_locale = "en" if current_locale == "zh_TW" else "zh_TW"
	TranslationServer.set_locale(current_locale)
	_save_pref()
	locale_changed.emit()

## 顯示「切換後」的語言標示（目前中文 → 顯示 EN，反之亦然）
func btn_label() -> String:
	return "EN" if current_locale == "zh_TW" else "中"

func _save_pref() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("lang", "locale", current_locale)
	cfg.save(_SAVE_PATH)

func _load_pref() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) == OK:
		current_locale = cfg.get_value("lang", "locale", _DEFAULT_LOCALE)
