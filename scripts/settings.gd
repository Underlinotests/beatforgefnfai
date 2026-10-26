extends Node

# Configuracoes persistentes entre cenas e sessoes.
const SAVE_PATH := "user://fnf_settings.json"
const DEFAULT_PRIMARY = [KEY_A, KEY_S, KEY_W, KEY_D]
const DEFAULT_SECONDARY = [KEY_LEFT, KEY_DOWN, KEY_UP, KEY_RIGHT]
const RESERVED = [KEY_ENTER, KEY_ESCAPE, KEY_F2]

var primary_keys: Array = DEFAULT_PRIMARY.duplicate()
var secondary_keys: Array = DEFAULT_SECONDARY.duplicate()
var downscroll: bool = false
var middlescroll: bool = false
# Runtime Story Mode selection. Only difficulty JSON files actually present can be selected.
var selected_song_id: String = "bopeebo"
var selected_difficulty: String = "hard"
var selected_chart_path: String = "res://assets/songs/bopeebo/bopeebo-hard.json"
var selected_audio_path: String = "res://assets/songs/bopeebo/Bopeebo.mp3"
var selected_mod_id: String = ""
var selected_stage_path: String = ""
var selected_player_character: String = ""
var selected_opponent_character: String = ""
var selected_girlfriend_character: String = ""
var selected_hide_girlfriend: bool = false

func apply_song(song: Dictionary, difficulty: String) -> void:
    selected_song_id = str(song.get("id", ""))
    selected_difficulty = difficulty
    selected_chart_path = FNFWeekLibrary.chart_path(selected_song_id, difficulty)
    selected_audio_path = str(song.get("audio", ""))
    selected_mod_id = str(song.get("mod_id", ""))
    selected_stage_path = str(song.get("stage", ""))
    selected_player_character = str(song.get("player_character", ""))
    selected_opponent_character = str(song.get("opponent_character", ""))
    selected_girlfriend_character = str(song.get("girlfriend_character", ""))
    selected_hide_girlfriend = not selected_mod_id.is_empty() and bool(song.get("hide_girlfriend", false))

# Return to the mode the player chose (Story Mode or Freeplay).
var return_menu_scene: String = "res://scenes/week_select.tscn"
# Runtime Story Mode playlist. Not saved to user:// settings.
# Freeplay explicitly clears it so songs remain independent.
var story_playlist: Array[Dictionary] = []
var story_song_index: int = -1

func clear_story_playlist() -> void:
    story_playlist.clear()
    story_song_index = -1

func start_story_playlist(week_songs: Array[Dictionary], difficulty: String) -> bool:
    clear_story_playlist()
    for song in week_songs:
        if not FNFWeekLibrary.song_is_playable(song, difficulty):
            push_warning("Musica indisponivel no Story Mode: " + str(song.get("id", "")))
            continue
        var playlist_entry: Dictionary = song.duplicate(true)
        playlist_entry["difficulty"] = difficulty
        story_playlist.append(playlist_entry)
    if story_playlist.is_empty():
        return false
    story_song_index = 0
    apply_story_song()
    return true

func apply_story_song() -> void:
    if story_song_index < 0 or story_song_index >= story_playlist.size():
        return
    var entry: Dictionary = story_playlist[story_song_index]
    apply_song(entry, str(entry.get("difficulty", "hard")))

# Returns true if another Story Mode song was queued.
func advance_story_song() -> bool:
    if story_song_index < 0 or story_playlist.is_empty():
        return false
    if story_song_index + 1 >= story_playlist.size():
        clear_story_playlist()
        return false
    story_song_index += 1
    apply_story_song()
    return true


func _ready() -> void:
    load_settings()

func load_settings() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not (result is Dictionary):
        push_warning("Configuracoes danificadas. Usando padroes.")
        return
    var data: Dictionary = result
    var incoming_primary: Variant = data.get("primary_keys", [])
    var incoming_secondary: Variant = data.get("secondary_keys", [])
    if incoming_primary is Array and incoming_primary.size() == 4:
        for i in range(4):
            primary_keys[i] = int(incoming_primary[i])
    if incoming_secondary is Array and incoming_secondary.size() == 4:
        for i in range(4):
            secondary_keys[i] = int(incoming_secondary[i])
    downscroll = bool(data.get("downscroll", false))
    middlescroll = bool(data.get("middlescroll", false))

func save_settings() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Nao foi possivel salvar as configuracoes: " + SAVE_PATH)
        return
    var data := {
        "primary_keys": primary_keys,
        "secondary_keys": secondary_keys,
        "downscroll": downscroll,
        "middlescroll": middlescroll
    }
    file.store_string(JSON.stringify(data, "  "))
    file.close()

func find_lane(keycode: int) -> int:
    for i in range(4):
        if primary_keys[i] == keycode or secondary_keys[i] == keycode:
            return i
    return -1

func get_binding(lane: int, secondary: bool = false) -> int:
    return secondary_keys[lane] if secondary else primary_keys[lane]

func key_name(keycode: int) -> String:
    var name: String = OS.get_keycode_string(keycode)
    return name if not name.is_empty() else str(keycode)

func set_binding(lane: int, secondary: bool, keycode: int) -> bool:
    if lane < 0 or lane >= 4 or keycode <= 0 or RESERVED.has(keycode):
        return false
    for i in range(4):
        if i == lane:
            continue
        if primary_keys[i] == keycode or secondary_keys[i] == keycode:
            return false
    if secondary:
        secondary_keys[lane] = keycode
    else:
        primary_keys[lane] = keycode
    save_settings()
    return true

func restore_defaults() -> void:
    primary_keys = DEFAULT_PRIMARY.duplicate()
    secondary_keys = DEFAULT_SECONDARY.duplicate()
    downscroll = false
    middlescroll = false
    save_settings()
