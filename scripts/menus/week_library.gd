extends RefCounted
class_name FNFWeekLibrary

const WEEK1_PATH := "res://data/weeks/week1.json"
const DIFFICULTY_ORDER := ["easy", "normal", "hard"]

static func week_data() -> Dictionary:
    if not FileAccess.file_exists(WEEK1_PATH):
        return {}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(WEEK1_PATH))
    return value if value is Dictionary else {}

static func all_weeks() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var built_in: Dictionary = week_data()
    if not built_in.is_empty():
        result.append(built_in)
    for week in ModManager.enabled_weeks():
        result.append(week)
    # Ordem numerica crescente; desempate deterministico pelo ID.
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var priority_a := int(a.get("order", 9999))
        var priority_b := int(b.get("order", 9999))
        if priority_a == priority_b:
            return str(a.get("id", "")) < str(b.get("id", ""))
        return priority_a < priority_b
    )
    return result

static func chart_path(song_id: String, difficulty: String) -> String:
    var mod_song: Dictionary = ModManager.get_song(song_id)
    if not mod_song.is_empty():
        return str(mod_song.get("charts", {}).get(difficulty, ""))
    # Namespaced identifiers are never allowed to fall back to the built-in path.
    if song_id.contains(":"):
        return ""
    return "res://assets/songs/%s/%s-%s.json" % [song_id, song_id, difficulty]

static func available_difficulties(song_id: String) -> Array[String]:
    var found: Array[String] = []
    for difficulty in DIFFICULTY_ORDER:
        var path: String = chart_path(song_id, difficulty)
        if not path.is_empty() and FileAccess.file_exists(path):
            found.append(difficulty)
    return found

static func song_is_playable(song_info: Dictionary, difficulty: String) -> bool:
    var path: String = chart_path(str(song_info.get("id", "")), difficulty)
    var audio: String = str(song_info.get("audio", ""))
    return not path.is_empty() and FileAccess.file_exists(path) and not audio.is_empty() and (FileAccess.file_exists(audio) or ResourceLoader.exists(audio))

static func available_songs(week: Dictionary) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for entry in week.get("songs", []):
        if not (entry is Dictionary):
            continue
        var song: Dictionary = entry
        if not available_difficulties(str(song.get("id", ""))).is_empty():
            found.append(song)
    return found

static func available_week_difficulties(week: Dictionary) -> Array[String]:
    var songs: Array[Dictionary] = available_songs(week)
    var found: Array[String] = []
    if songs.is_empty():
        return found
    for difficulty in DIFFICULTY_ORDER:
        var common := true
        for song in songs:
            var path: String = chart_path(str(song.get("id", "")), difficulty)
            if path.is_empty() or not FileAccess.file_exists(path):
                common = false
                break
        if common:
            found.append(difficulty)
    return found

static func all_playable_catalog_songs() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var seen: Dictionary = {}
    for week in all_weeks():
        for song in available_songs(week):
            var song_id: String = str(song.get("id", ""))
            if song_id.is_empty() or seen.has(song_id):
                continue
            seen[song_id] = true
            result.append(song)
    return result
