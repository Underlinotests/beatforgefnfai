extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run_tests")

func check(condition: bool, label: String) -> void:
    if condition:
        print("[PASS] ", label)
    else:
        failures += 1
        push_error("[FAIL] " + label)

func load_scene(path: String) -> void:
    var result := change_scene_to_file(path)
    check(result == OK, "open " + path)
    if result == OK:
        await scene_changed
        await process_frame

func wait_for_fade() -> void:
    await create_timer(1.15).timeout
    await process_frame

func run_tests() -> void:
    await process_frame
    var settings := root.get_node("Settings")
    var transition := root.get_node("SceneTransition")
    var library := load("res://scripts/menus/week_library.gd")
    var week: Dictionary = library.week_data()
    var songs: Array[Dictionary] = library.available_songs(week)
    check(songs.size() == 3, "Story Week 1 3 playable songs")
    var expected_ids := ["bopeebo", "fresh", "dadbattle"]
    var expected_bpm := [100.0, 120.0, 180.0]
    var expected_count := [124, 264, 323]
    for i in range(3):
        var song_id: String = str(songs[i]["id"])
        check(song_id == expected_ids[i], "ordered track " + str(i+1) + ": " + song_id)
        var path: String = library.chart_path(song_id, "hard")
        var chart: Dictionary = ChartLoader.load_psych(path)
        var notes: Array = chart.get("notes", [])
        check(notes.size() == expected_count[i], song_id + " note count")
        check(is_equal_approx(float(chart.get("bpm", 0)), expected_bpm[i]), song_id + " BPM")
        check(library.available_difficulties(song_id) == ["hard"], song_id + " chart difficulty")
        check(ResourceLoader.exists(str(songs[i]["audio"])), song_id + " audio exists")
    check(library.all_playable_catalog_songs().size() == 3, "Freeplay has the 3 built-in songs")
    await load_scene("res://scenes/week_select.tscn")
    check(current_scene.name == "WeekSelect", "Week select scene instantiated")
    check(current_scene.get("difficulties") == ["hard"], "Week difficulty HARD only")
    check(settings.start_story_playlist(songs, "hard"), "Start 3-track Story playlist")
    for i in range(3):
        check(str(settings.selected_song_id) == expected_ids[i], "Selected Story song " + str(i+1))
        await load_scene("res://scenes/gameplay.tscn")
        var play: Node = current_scene.get_node("UI/PlayState")
        check(play.get("selected_title") == ["BOPEEBO", "FRESH", "DAD BATTLE"][i], "Gameplay loads track " + str(i+1))
        check(play.get("music") != null, "Audio player loaded " + str(i+1))
        check(play.get("running") == true, "Gameplay countdown active " + str(i+1))
        play.call("_complete_song")
        await wait_for_fade()
        if i < 2:
            check(str(settings.selected_song_id) == expected_ids[i + 1], "Story auto advances to " + str(i+2))
            check(current_scene.scene_file_path == "res://scenes/gameplay.tscn", "Next Story gameplay scene loaded")
        else:
            check(current_scene.scene_file_path == "res://scenes/week_select.tscn", "Story returns to week select")
    await load_scene("res://scenes/freeplay_menu.tscn")
    check(current_scene.get("songs").size() == 3, "Freeplay loaded the built-in catalog")
    current_scene.call("_move", 1)
    check(current_scene.get("selected_index") == 1, "Freeplay music selection")
    current_scene.call("_start_song")
    await wait_for_fade()
    check(current_scene.scene_file_path == "res://scenes/gameplay.tscn", "Freeplay loads chosen song")
    check(str(settings.selected_song_id) == "fresh", "Freeplay independent Fresh selection")
    var play: Node = current_scene.get_node("UI/PlayState")
    play.call("_complete_song")
    await wait_for_fade()
    check(current_scene.scene_file_path == "res://scenes/freeplay_menu.tscn", "Freeplay returns to Freeplay")
    await load_scene("res://scenes/gameplay.tscn")
    play = current_scene.get_node("UI/PlayState")
    play.call("_trigger_game_over")
    check(play.get("game_over") == true, "Game Over enters death state")
    check(play.get("loss_player").stream != null, "Game Over loss SFX available")
    check(play.get("game_over_music").stream != null, "Game Over loop available")
    check(play.get("game_over_end").stream != null, "Game Over end SFX available")
    play.call("_start_game_over_confirm")
    check(play.get("game_over_confirming") == true, "Game Over Enter confirmation")
    play.call("_on_game_over_end_finished")
    check(play.get("game_over") == false, "Game Over restarts on end SFX")
    await load_scene("res://scenes/options_menu.tscn")
    check(current_scene.scene_file_path == "res://scenes/options_menu.tscn", "Options scene loads")
    print("=== TESTS FINISHED; failures=", failures, " ===")
    quit(1 if failures > 0 else 0)
