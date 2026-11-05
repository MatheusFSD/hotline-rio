extends RefCounted
## Languages. Portuguese is the source text everywhere (labels, level files); the other languages
## come from assets/lang/<code>.json, keyed by the Portuguese line. Controls translate their own
## text when it is a key, so the game calls tr() only where it pastes words together. The choice is
## kept in user://settings.cfg; with none, the computer's language decides. Tests never call setup,
## so they always read Portuguese.
const LANGUAGES := [["pt","PORTUGUÊS"],["en","ENGLISH"]]
const TABLES := {"en":"res://assets/lang/en.json"}
const SETTINGS := "user://settings.cfg"
static var loaded := false

static func setup() -> void:
	if not loaded:
		loaded = true
		for code in TABLES:
			var table := Translation.new()
			table.locale = code
			var lines: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TABLES[code]))
			for source in lines: table.add_message(source,lines[source])
			TranslationServer.add_translation(table)
	var config := ConfigFile.new()
	var saved: String = config.get_value("game","language","") if config.load(SETTINGS) == OK else ""
	TranslationServer.set_locale(saved if saved != "" else ("pt" if OS.get_locale_language() == "pt" else "en"))

static func current() -> String:
	return TranslationServer.get_locale().substr(0,2)

static func choose(code: String) -> void:
	TranslationServer.set_locale(code)
	var config := ConfigFile.new()
	config.load(SETTINGS)
	config.set_value("game","language",code)
	config.save(SETTINGS)
