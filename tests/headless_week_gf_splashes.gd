extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if ok:
        print("[PASS] " + message)
    else:
        failures += 1
        push_error("[FAIL] " + message)

func goto(path: String) -> void:
    check(change_scene_to_file(path) == OK, "load " + path)
    await scene_changed
    await process_frame
    await process_frame

func _run() -> void:
    var lib: GDScript = load("res://scripts/menus/week_library.gd")
    var weeks: Array[Dictionary] = lib.all_weeks()
    check(weeks.size() >= 1, "at least the built-in Week 1 exists")
    check(int(weeks[0].get("order", -1)) == 0, "native week order 0")
    await goto("res://scenes/week_select.tscn")
    var selector := current_scene
    check(str(selector.get("data").get("id", "")) == "week1", "Week 1 is first")
    if weeks.size() > 1:
        selector.call("_switch_week", 1)
        check(bool(selector.get("switching")), "week transition in progress")
        check(int(selector.get("switch_direction")) == 1, "scroll down makes week move up")
        await create_timer(0.45).timeout
        check(not bool(selector.get("switching")), "week animation finished")
        selector.call("_switch_week", -1)
        check(int(selector.get("switch_direction")) == -1, "scroll up reverses transition")
        await create_timer(0.45).timeout
        check(str(selector.get("data").get("id", "")) == "week1", "week 1 selected again")
    else:
        check(true, "no example mod/week installed by default")

    var settings: Node = root.get_node("Settings")
    settings.apply_song({"id": "bopeebo", "audio": "res://assets/songs/bopeebo/Bopeebo.mp3"}, "hard")
    await goto("res://scenes/gameplay.tscn")
    var play: Node = current_scene.get_node("UI/PlayState")
    var gf: Node = current_scene.get_node("World/Girlfriend")
    check(bool(gf.get("built")), "GF atlas frames loaded")
    check(bool(gf.visible), "GF visible in built-in week")
    check(gf.get("animations").get("danceLeft", {}).get("frames", []).size() >= 14, "GF danceLeft indices loaded")
    check(gf.get("animations").get("danceRight", {}).get("frames", []).size() >= 14, "GF danceRight indices loaded")
    check(float(current_scene.get_node("World/BattleCamera").get("default_zoom")) > 1.05, "camera zoom increased")
    for lane in range(4):
        check(play.get("splash_animations").get(lane, []).size() == 4, "note splash frames lane " + str(lane))
    check(play.get("active_splashes").is_empty(), "no splashes at song start")
    var first_player_note: Dictionary = {}
    for entry in play.get("chart"):
        if bool(entry["player"]):
            first_player_note = entry
            break
    check(not first_player_note.is_empty(), "chart contains player notes")
    play.set("song_time", float(first_player_note["time"]))
    play.call("_attempt_hit", int(first_player_note["lane"]))
    check(play.get("score").rating == "SICK!", "exact hit is Sick")
    check(play.get("active_splashes").size() == 1, "only Sick creates note splash")
    play.call("_reset")
    check(play.get("active_splashes").is_empty(), "reset removes splashes")
    play.set("song_time", float(first_player_note["time"]) + 0.070)
    play.call("_attempt_hit", int(first_player_note["lane"]))
    check(play.get("score").rating == "GOOD", "70 ms hit is Good")
    check(play.get("active_splashes").is_empty(), "Good never creates splash")
    play.call("_reset")
    # Simula os dados de uma musica de mod sem instalar uma demo na engine.
    var song: Dictionary = {"id": "bopeebo", "mod_id": "fixture_mod", "audio": "res://assets/songs/bopeebo/Bopeebo.mp3", "hide_girlfriend": true}
    settings.apply_song(song, "hard")
    await goto("res://scenes/gameplay.tscn")
    check(not current_scene.get_node("World/Girlfriend").visible, "mod can hide girlfriend")
    print("WEEK_GF_SPLASH_FAILURES=", failures)
    quit(1 if failures else 0)
