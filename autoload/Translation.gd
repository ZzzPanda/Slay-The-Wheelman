## Translation Manager - Simple CSV-based translation system
## Usage: Translation.tr("key") or tr("key")
extends Node

var translations: Dictionary = {}
var current_locale: String = "en"

## Supported locales
const LOCALES: Array[String] = ["en", "zh_CN"]

func _ready() -> void:
	# Load all translation files
	_load_translations()
	
	# Set default locale based on system or user preference
	var saved_locale = _get_saved_locale()
	if saved_locale != "" and saved_locale in LOCALES:
		current_locale = saved_locale
	elif TranslationServer.get_locale().begins_with("zh"):
		current_locale = "zh_CN"
	
	print("[Translation] Loaded with locale: ", current_locale)

func _get_saved_locale() -> String:
	# Could load from user settings in the future
	return ""

## Load all CSV translation files from res://translations/
func _load_translations() -> void:
	var translations_dir = DirAccess.open("res://translations/")
	if translations_dir == null:
		push_error("[Translation] Could not open translations directory")
		return
	
	var files = translations_dir.get_files()
	for file in files:
		if file.ends_with(".txt"):
			var locale = file.get_basename()  # e.g., "zh_CN" from "zh_CN.txt"
			var path = "res://translations/" + file
			translations[locale] = _parse_csv(path)
			print("[Translation] Loaded ", path, " with ", translations[locale].size(), " entries")

## Parse a CSV file into a dictionary
## CSV format: key,translation
func _parse_csv(path: String) -> Dictionary:
	var result = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Translation] Could not open file: ", path)
		return result
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# Simple CSV parsing (handles basic cases)
		var comma_pos = line.find(",")
		if comma_pos > 0:
			var key = line.substr(0, comma_pos).strip_edges()
			var value = line.substr(comma_pos + 1).strip_edges()
			# Remove surrounding quotes if present
			if value.begins_with('"') and value.ends_with('"'):
				value = value.substr(1, value.length() - 2)
			result[key] = value
	
	file.close()
	return result

## Main translation function
## Usage: Translation.t("key")
func t(key: String) -> String:
	# If translations not loaded yet, return key as-is
	if translations.is_empty():
		return key
	
	# First try current locale
	if translations.has(current_locale):
		if translations[current_locale].has(key):
			return translations[current_locale][key]
	
	# Fallback to English
	if translations.has("en"):
		if translations["en"].has(key):
			return translations["en"][key]
	
	# Return original key if no translation found
	return key

## Set the current locale
func set_locale(locale: String) -> void:
	if locale in LOCALES:
		current_locale = locale
		print("[Translation] Locale changed to: ", locale)
	else:
		push_warning("[Translation] Unknown locale: ", locale)

## Get current locale
func get_locale() -> String:
	return current_locale

## Get available locales
func get_available_locales() -> Array[String]:
	return LOCALES.duplicate()

## Reload translations (useful for development)
func reload_translations() -> void:
	translations.clear()
	_load_translations()
