extends SceneTree

func _initialize() -> void:
    call_deferred("render")

func render() -> void:
    var settings := root.get_node("Settings")
    settings.apply_song({"id":"bopeebo","audio":"res://assets/songs/bopeebo/Bopeebo.mp3"},"hard")
    change_scene_to_file("res://scenes/gameplay.tscn")
    await scene_changed
    await process_frame
    await process_frame
    var cam = current_scene.get_node("World/BattleCamera")
    var play = current_scene.get_node("UI/PlayState")
    play.running = false
    cam.auto_follow = false
    var modes: Array = ["neutral", "dad", "bf"]
    var positions: Array = [cam.neutral_focus, cam.dad_focus, cam.bf_focus]
    for i in range(modes.size()):
        cam.position = positions[i]
        cam.force_update_scroll()
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        var output: String = "res://align_render_%s.png" % modes[i]
        var err = root.get_viewport().get_texture().get_image().save_png(output)
        print("RENDER_",modes[i], " ",err," cam=",positions[i], " dad=",current_scene.get_node("World/Dad").position," gf=",current_scene.get_node("World/Girlfriend").position," bf=",current_scene.get_node("World/Boyfriend").position)
    quit()
