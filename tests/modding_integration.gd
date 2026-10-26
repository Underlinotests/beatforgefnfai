extends SceneTree

# Este teste cria UM mod temporario no user://, testa carregamento real e
# apaga a pasta ao final. O projeto distribuido nao possui mod de demo.
const FIXTURE_ID := "__beatforge_fixture_test"
const FIXTURE_ROOT := "user://mods/" + FIXTURE_ID
var failures := 0

func _initialize() -> void:
    call_deferred("_test")

func check(ok: bool, title: String) -> void:
    if not ok:
        failures += 1
        push_error("FAIL: " + title)
    else:
        print("[PASS] ", title)

func go(path: String) -> void:
    check(change_scene_to_file(path) == OK, "load " + path)
    await scene_changed
    await process_frame

func save_text(path: String, data: Dictionary) -> bool:
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(data, "  "))
    f.close()
    return true

func copy_file(src: String, dst: String) -> bool:
    var input_file: FileAccess = FileAccess.open(src, FileAccess.READ)
    if input_file == null:
        return false
    var contents: PackedByteArray = input_file.get_buffer(input_file.get_length())
    input_file.close()
    var out: FileAccess = FileAccess.open(dst, FileAccess.WRITE)
    if out == null:
        return false
    out.store_buffer(contents)
    out.close()
    return true

func delete_tree(path: String) -> void:
    var directory := DirAccess.open(path)
    if directory == null:
        return
    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while not entry.is_empty():
        var child := path.path_join(entry)
        if directory.current_is_dir():
            delete_tree(child)
        else:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
        entry = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func fixture_create() -> bool:
    if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)):
        push_warning("Found a previous test fixture; resetting it")
        delete_tree(FIXTURE_ROOT)
    var song_dir: String = FIXTURE_ROOT.path_join("songs/test_song")
    var week_dir: String = FIXTURE_ROOT.path_join("weeks")
    var stage_dir: String = FIXTURE_ROOT.path_join("stages")
    for directory in [song_dir, week_dir, stage_dir]:
        if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
            return false
    var manifest := {
        "api_version": 1,
        "id": FIXTURE_ID,
        "name": "Temporary Test Fixture",
        "version": "1.0",
        "weeks": ["weeks/fixture_week.json"]
    }
    var week := {
        "id": "fixture_week", "name": "TEST ONLY", "order": 1,
        "opponent": "PLACEHOLDER",
        "songs": [{
            "id": "test_song", "title": "TEST SONG",
            "audio": "songs/test_song/Inst.mp3",
            "charts": {"hard": "songs/test_song/test_song-hard.json"},
            "stage": "stages/test_stage.json", "hide_girlfriend": true
        }]
    }
    var chart := {"song": {
        "song": "Test Song", "bpm": 100, "speed": 1.3,
        "format": "psych_v1_convert", "notes": [
            {"mustHitSection": true, "sectionNotes": [[1000, 0, 0], [1500, 4, 0]]}
        ]
    }}
    var stage := {
        "defaultZoom": 1.0, "opponent": [100, 100],
        "boyfriend": [770, 100], "girlfriend": [400, 130], "layers": []
    }
    return (save_text(FIXTURE_ROOT.path_join("mod.json"), manifest)
        and save_text(week_dir.path_join("fixture_week.json"), week)
        and save_text(song_dir.path_join("test_song-hard.json"), chart)
        and save_text(stage_dir.path_join("test_stage.json"), stage)
        and copy_file("res://assets/songs/bopeebo/Bopeebo.mp3", song_dir.path_join("Inst.mp3")))

func _test() -> void:
    await process_frame
    var manager: Node = root.get_node("ModManager")
    var settings: Node = root.get_node("Settings")
    var lib: GDScript = load("res://scripts/menus/week_library.gd")
    # Resumo inicial nao deve incluir sobra de um teste interrompido.
    if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FIXTURE_ROOT)):
        delete_tree(FIXTURE_ROOT)
    manager.rescan()
    check(not manager.mods.has("_template"), "template is not an installed mod")
    check(not FileAccess.file_exists("res://mods/_template/mod.json"), "template has no active manifest")
    var initial_catalog: int = lib.all_playable_catalog_songs().size()
    check(initial_catalog >= 3, "base songs available")
    var installed: bool = fixture_create()
    check(installed, "create a temporary standalone mod")
    if not installed:
        delete_tree(FIXTURE_ROOT)
        quit(1)
        return
    manager.rescan()
    check(manager.mods.has(FIXTURE_ID), "temporary mod discovered")
    var song: Dictionary = manager.get_song(FIXTURE_ID + ":test_song")
    check(not song.is_empty(), "temporary mod song indexed")
    check(lib.available_difficulties(FIXTURE_ID + ":test_song") == ["hard"], "mod difficulty available")
    check(lib.all_playable_catalog_songs().size() == initial_catalog + 1, "Freeplay adds temporary song")
    check(lib.all_weeks().any(func(w: Dictionary) -> bool: return str(w.get("id", "")) == FIXTURE_ID + ":fixture_week"), "Story Mode sees temporary week")
    var notes: Dictionary = ChartLoader.load_psych(lib.chart_path(FIXTURE_ID + ":test_song", "hard"))
    check(notes.get("notes", []).size() == 2, "external chart loaded")
    check(manager.audio_from_file(str(song.get("audio", ""))) != null, "external MP3 loaded")
    check(str(song.get("icon", "")).is_empty(), "icon omitted so the placeholder is used")
    check(manager.resolve_mod_asset(FIXTURE_ID, "../bad.png") == "", "reject directory traversal")
    await go("res://scenes/freeplay_menu.tscn")
    check(current_scene.get("songs").size() == initial_catalog + 1, "Freeplay lists temporary mod")
    check(current_scene.get("mod_placeholder_icon") != null, "Freeplay placeholder loaded")
    var mod_playlist: Array[Dictionary] = [song]
    settings.start_story_playlist(mod_playlist, "hard")
    await go("res://scenes/gameplay.tscn")
    var play: Node = current_scene.get_node("UI/PlayState")
    check(play.get("music").stream != null, "custom music player has audio")
    check(play.get("chart").size() == 2, "custom music gameplay notes present")
    check(not current_scene.get_node("World/Girlfriend").visible, "mod can hide Girlfriend")
    check(play.get("icon_opponent") == load("res://assets/health/icon-mod-placeholder.png"), "opponent icon defaults to placeholder")
    await go("res://scenes/main.tscn")
    manager.set_enabled(FIXTURE_ID, false)
    check(manager.get_song(FIXTURE_ID + ":test_song").is_empty(), "disabling mod hides song")
    manager.set_enabled(FIXTURE_ID, true)
    check(not manager.get_song(FIXTURE_ID + ":test_song").is_empty(), "reenabling mod restores song")
    delete_tree(FIXTURE_ROOT)
    manager.rescan()
    check(not manager.mods.has(FIXTURE_ID), "temporary test mod removed")
    check(lib.all_playable_catalog_songs().size() == initial_catalog, "song catalog returns to baseline")
    await go("res://scenes/mods_menu.tscn")
    check(current_scene.scene_file_path == "res://scenes/mods_menu.tscn", "Mods menu loads without demo")
    print("MOD_TEST_FAILURES=", failures)
    quit(1 if failures else 0)
