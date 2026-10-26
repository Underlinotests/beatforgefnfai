extends SceneTree
var fails := 0
func check(value: bool, label: String) -> void:
    if value:
        print("[PASS] " + label)
    else:
        push_error("[FAIL] " + label)
        fails += 1

func _initialize() -> void:
    call_deferred("run_test")

func run_test() -> void:
    var settings := root.get_node("Settings")
    settings.apply_song({"id":"bopeebo", "audio":"res://assets/songs/bopeebo/Bopeebo.mp3"}, "hard")
    check(change_scene_to_file("res://scenes/gameplay.tscn") == OK, "load gameplay")
    await scene_changed
    await process_frame
    await process_frame
    var dad := current_scene.get_node("World/Dad")
    var bf := current_scene.get_node("World/Boyfriend")
    var gf := current_scene.get_node("World/Girlfriend")
    var camera := current_scene.get_node("World/BattleCamera")
    check(is_equal_approx(dad.sprite_scale, 0.96), "Dad custom stage scale")
    check(is_equal_approx(bf.sprite_scale, 1.95), "BF custom stage scale")
    check(is_equal_approx(gf.display_scale, 2.05), "GF adjusted for stage")
    check(camera.dad_focus.x < camera.neutral_focus.x - 100.0, "opponent camera actually pans toward Dad")
    check(camera.bf_focus.x > camera.neutral_focus.x + 100.0, "player camera actually pans toward BF")
    check(absf(bf.position.y - dad.position.y) < 1.0, "Dad e BF compartilham a linha inferior")
    check(gf.position.y < dad.position.y - 50.0, "GF fica na linha superior")
    check(is_equal_approx(gf.position.x, 502.5), "GF alinhada horizontalmente ao palco")
    var play := current_scene.get_node("UI/PlayState")
    check(play.icon_player != null and play.icon_opponent != null, "health icons loaded")
    # Test per-stage visual overrides on a separate mod stage, without changing scene defaults.
    print("PROPORTIONS_FAILURES=", fails)
    quit(1 if fails > 0 else 0)
