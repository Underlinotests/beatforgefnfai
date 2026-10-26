extends SceneTree

var fails := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        fails += 1
        push_error("[FAIL] " + message)
    else:
        print("[PASS] " + message)

func go(scene: String) -> void:
    check(change_scene_to_file(scene) == OK, "Load " + scene)
    await scene_changed
    await process_frame
    await process_frame

func key_press(keycode: int) -> void:
    var evt := InputEventKey.new()
    evt.keycode = keycode
    evt.pressed = true
    Input.parse_input_event(evt)
    await process_frame
    var release := InputEventKey.new()
    release.keycode = keycode
    release.pressed = false
    Input.parse_input_event(release)
    await process_frame

func mouse_motion(pos: Vector2) -> void:
    var evt := InputEventMouseMotion.new()
    evt.position = pos
    Input.parse_input_event(evt)
    await process_frame

func _run() -> void:
    await go("res://scenes/main.tscn")
    var mm := current_scene
    check(mm.get("sprites").size() == 4, "4 menu sprites")
    var mods_sprite: Node = mm.get("sprites")[2]
    check(mods_sprite.get("animations").get("idle", []).size() == 9, "Mods button has 9 idle frames")
    check(mods_sprite.get("animations").get("selected", []).size() == 3, "Mods button has 3 selected frames")
    check(mm.get("current_index") == 0, "Menu initial selection")
    await mouse_motion(Vector2(550, 425))
    check(mm.get("current_index") == 0, "Mouse hover no longer changes main menu selection")
    await key_press(KEY_DOWN)
    check(mm.get("current_index") == 1, "Main menu keyboard selection")
    check(mm.get("bg_target_y") == 16.0, "Main menu background target follows selection")
    await go("res://scenes/freeplay_menu.tscn")
    var fp := current_scene
    check(fp.get("songs").size() >= 3, "Freeplay songs preserved")
    await mouse_motion(Vector2(90, 380))
    check(fp.get("selected_index") == 0, "Freeplay mouse selection disabled")
    await key_press(KEY_DOWN)
    check(fp.get("selected_index") == 1, "Freeplay keyboard navigation")
    await go("res://scenes/options_menu.tscn")
    var opt := current_scene
    check(opt.get("options").size() == 12, "Options contains toggles, two bindings for each lane, restore and back")
    check(opt.get("vcr") != null, "Options VCR renderer present")
    var settings := root.get_node("Settings")
    var original_down: bool = settings.downscroll
    await key_press(KEY_ENTER)
    check(settings.downscroll != original_down, "Toggle Downscroll with Enter")
    await key_press(KEY_ENTER)
    check(settings.downscroll == original_down, "Toggle back Downscroll")
    await key_press(KEY_DOWN)
    check(opt.get("selected_index") == 1, "Options keyboard selects Middlescroll")
    check(opt.get("target_y") > -40.0, "Options background tracks selected row")
    await key_press(KEY_DOWN)
    check(opt.get("selected_index") == 2, "Options keyboard selects binding")
    await key_press(KEY_ENTER)
    check(opt.get("capture_lane") == 0, "Enter begins binding capture")
    await key_press(KEY_ESCAPE)
    check(opt.get("capture_lane") == -1, "Escape cancels binding capture")
    await go("res://scenes/mods_menu.tscn")
    var mods := current_scene
    check(mods.get("vcr") != null, "Mods keyboard menu VCR renderer")
    var prior: int = mods.get("selection")
    await mouse_motion(Vector2(80, 430))
    check(mods.get("selection") == prior, "Mods ignores mouse hover")
    await key_press(KEY_DOWN)
    check(mods.get("selection") == prior + 1, "Mods keyboard navigation")
    await go("res://scenes/week_select.tscn")
    check(current_scene.get("weeks").size() >= 1, "Story menu loads")
    print("MENU_KEYBOARD_TEST_FAILURES=", fails)
    quit(1 if fails > 0 else 0)
