extends Node

# BeatForge Modding v1: DATA mods only (no code execution).
# Supports res://mods/<id> for development and user://mods/<id> for exported games.
# All paths written in a mod manifest are relative to its own directory.
const ROOTS := ["user://mods", "res://mods"]
const STATE_PATH := "user://beatforge_mods.json"
const API_VERSION := 1

var mods: Dictionary = {}
var song_catalog: Dictionary = {}
var mod_weeks: Array[Dictionary] = []
var disabled_ids: Array[String] = []
var texture_cache: Dictionary = {}
var messages: Array[String] = []

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute("user://mods")
    _load_state()
    rescan()

func _load_state() -> void:
    disabled_ids.clear()
    if not FileAccess.file_exists(STATE_PATH):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
    if parsed is Dictionary:
        for item in parsed.get("disabled", []):
            disabled_ids.append(str(item))

func _save_state() -> void:
    var file: FileAccess = FileAccess.open(STATE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({"disabled": disabled_ids}, "  "))

func _valid_id(value: String) -> bool:
    if value.is_empty() or value.length() > 64:
        return false
    for c in value:
        if not (c in "abcdefghijklmnopqrstuvwxyz0123456789_-" ):
            return false
    return true

# Block directory traversal, absolute paths and paths with schemes inside mod metadata.
func _safe_path(root: String, relative: String) -> String:
    var candidate: String = relative.replace("\\", "/")
    if candidate.is_empty() or candidate.begins_with("/") or candidate.find(":") >= 0:
        return ""
    for component in candidate.split("/"):
        if component == "." or component == ".." or component.is_empty():
            return ""
    return root.path_join(candidate)

func rescan() -> void:
    mods.clear()
    song_catalog.clear()
    mod_weeks.clear()
    texture_cache.clear()
    messages.clear()
    for root_path in ROOTS:
        var directory: DirAccess = DirAccess.open(root_path)
        if directory == null:
            continue
        var candidates: Array[String] = []
        directory.list_dir_begin()
        var entry: String = directory.get_next()
        while not entry.is_empty():
            if directory.current_is_dir() and not entry.begins_with(".") and _valid_id(entry):
                candidates.append(entry)
            entry = directory.get_next()
        directory.list_dir_end()
        candidates.sort()
        for dir_name in candidates:
            if mods.has(dir_name):
                continue # user:// takes precedence over bundled developer mods.
            _read_mod(root_path.path_join(dir_name), dir_name)
    for mod_id in mods:
        if not bool(mods[mod_id].get("enabled", false)):
            continue
        _index_mod(str(mod_id))

func _read_mod(root_path: String, dirname: String) -> void:
    var manifest_path: String = root_path.path_join("mod.json")
    if not FileAccess.file_exists(manifest_path):
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
    if not (parsed is Dictionary):
        messages.append("mod.json invalido: " + dirname)
        return
    var manifest: Dictionary = parsed
    if str(manifest.get("id", "")) != dirname or int(manifest.get("api_version", 0)) != API_VERSION:
        messages.append("ID ou versao de API incorreta: " + dirname)
        return
    mods[dirname] = {
        "id": dirname,
        "name": str(manifest.get("name", dirname)).substr(0, 80),
        "author": str(manifest.get("author", "")).substr(0, 80),
        "version": str(manifest.get("version", "1.0")),
        "root": root_path,
        "enabled": not disabled_ids.has(dirname),
        "week_files": manifest.get("weeks", [])
    }

func _index_mod(mod_id: String) -> void:
    var mod: Dictionary = mods[mod_id]
    for relative_variant in mod.get("week_files", []):
        var week_path: String = _safe_path(str(mod["root"]), str(relative_variant))
        if week_path.is_empty() or not week_path.ends_with(".json") or not FileAccess.file_exists(week_path):
            messages.append("Week ausente no mod " + mod_id)
            continue
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(week_path))
        if not (parsed is Dictionary):
            messages.append("Week invalida: " + week_path)
            continue
        var raw_week: Dictionary = parsed
        if not raw_week.has("order"):
            push_warning("Week sem campo order no mod %s: sera exibida apos as weeks ordenadas" % mod_id)
        var normalized: Dictionary = {
            "id": mod_id + ":" + str(raw_week.get("id", "week")),
            "name": str(raw_week.get("name", mod["name"])),
            "opponent": str(raw_week.get("opponent", "")),
            "mod_id": mod_id,
            "order": int(raw_week.get("order", 9999)),
            "songs": []
        }
        var title_path: String = _safe_path(str(mod["root"]), str(raw_week.get("menu_image", "")))
        if not title_path.is_empty() and FileAccess.file_exists(title_path):
            normalized["menu_image"] = title_path
        for song_variant in raw_week.get("songs", []):
            if not (song_variant is Dictionary):
                continue
            var raw_song: Dictionary = song_variant
            var local_song_id: String = str(raw_song.get("id", ""))
            if not _valid_id(local_song_id):
                continue
            var full_id: String = mod_id + ":" + local_song_id
            var audio_path: String = _safe_path(str(mod["root"]), str(raw_song.get("audio", "")))
            if audio_path.is_empty() or not FileAccess.file_exists(audio_path):
                messages.append("Audio ausente: " + full_id)
                continue
            if not (audio_path.to_lower().ends_with(".ogg") or audio_path.to_lower().ends_with(".mp3")):
                continue
            var raw_charts: Variant = raw_song.get("charts", {})
            if not (raw_charts is Dictionary):
                continue
            var charts: Dictionary = {}
            for difficulty_variant in raw_charts:
                var diff: String = str(difficulty_variant).to_lower()
                if not (diff in ["easy", "normal", "hard"]):
                    continue
                var chart_path: String = _safe_path(str(mod["root"]), str(raw_charts[difficulty_variant]))
                if not chart_path.is_empty() and chart_path.ends_with(".json") and FileAccess.file_exists(chart_path):
                    charts[diff] = chart_path
            if charts.is_empty():
                continue
            var song: Dictionary = {
                "id": full_id,
                "title": str(raw_song.get("title", local_song_id)),
                "audio": audio_path,
                "charts": charts,
                "mod_id": mod_id
            }
            song["hide_girlfriend"] = bool(raw_song.get("hide_girlfriend", false))
            for extra in ["icon", "stage", "player_character", "opponent_character", "girlfriend_character"]:
                var relative: String = str(raw_song.get(extra, ""))
                if relative.is_empty():
                    continue
                var resource_path: String = _safe_path(str(mod["root"]), relative)
                if not resource_path.is_empty() and FileAccess.file_exists(resource_path):
                    song[extra] = resource_path
            # First valid registration wins; protects against duplicate song IDs.
            if song_catalog.has(full_id):
                continue
            song_catalog[full_id] = song
            normalized["songs"].append(song)
        if not normalized["songs"].is_empty():
            mod_weeks.append(normalized)

func resolve_mod_asset(mod_id: String, relative: String) -> String:
    if not mods.has(mod_id):
        return ""
    return _safe_path(str(mods[mod_id]["root"]), relative)

func enabled_weeks() -> Array[Dictionary]:
    return mod_weeks.duplicate(true)

func get_song(song_id: String) -> Dictionary:
    return song_catalog.get(song_id, {})

func get_mod_list() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var ids: Array = mods.keys()
    ids.sort()
    for mod_id in ids:
        result.append(mods[mod_id].duplicate())
    return result

func set_enabled(mod_id: String, enabled: bool) -> void:
    if not mods.has(mod_id):
        return
    disabled_ids.erase(mod_id)
    if not enabled:
        disabled_ids.append(mod_id)
    _save_state()
    rescan()

# Use these APIs rather than ResourceLoader.load for external files in user://.
func texture_from_file(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if texture_cache.has(path):
        return texture_cache[path]
    var result: Texture2D
    if path.begins_with("res://") and ResourceLoader.exists(path):
        result = load(path) as Texture2D
    if result == null and FileAccess.file_exists(path):
        var image: Image = Image.load_from_file(path)
        if image != null and not image.is_empty():
            result = ImageTexture.create_from_image(image)
    if result != null:
        texture_cache[path] = result
    return result

func audio_from_file(path: String) -> AudioStream:
    if path.is_empty():
        return null
    if path.begins_with("res://") and ResourceLoader.exists(path):
        return load(path) as AudioStream
    if not FileAccess.file_exists(path):
        return null
    if path.to_lower().ends_with(".mp3"):
        return AudioStreamMP3.load_from_file(path)
    if path.to_lower().ends_with(".ogg"):
        return AudioStreamOggVorbis.load_from_file(path)
    return null

func mods_folder() -> String:
    return ProjectSettings.globalize_path("user://mods")
