extends SceneTree

var failures := 0
func _initialize() -> void:
    call_deferred("run_tests")

func check(ok: bool, message: String) -> void:
    if ok:
        print("[PASS] ", message)
    else:
        failures += 1
        push_error("[FAIL] " + message)

func run_tests() -> void:
    await process_frame
    var settings := root.get_node("Settings")
    var library := load("res://scripts/menus/week_library.gd")
    settings.clear_story_playlist()
    for song_info in library.available_songs(library.week_data()):
        var song_id: String = str(song_info["id"])
        var path: String = library.chart_path(song_id, "hard")
        var data: Dictionary = ChartLoader.load_psych(path)
        settings.selected_song_id = song_id
        settings.selected_chart_path = path
        settings.selected_difficulty = "hard"
        settings.selected_audio_path = str(song_info["audio"])
        var result := change_scene_to_file("res://scenes/gameplay.tscn")
        check(result == OK, "Load scene for " + song_id)
        await scene_changed
        var play := current_scene.get_node("UI/PlayState")
        var countdown: float = float(play.get("countdown"))
        await create_timer(countdown + 0.32).timeout
        check(play.get("audio_started") == true, song_id + " countdown completed")
        var audio: AudioStreamPlayer = play.get("music")
        check(audio.playing, song_id + " MP3 playback started")
        check(float(play.get("song_time")) >= 0.0, song_id + " song clock >= 0")
    print("=== AUDIO SMOKE; failures=", failures, " ===")
    quit(1 if failures else 0)
