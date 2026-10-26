extends Node2D

const DIRECTIONS := ["Left", "Down", "Up", "Right"]
const LANE_COLORS := [Color("#bf4da8"), Color("#00dfff"), Color("#20ed24"), Color("#fa3349")]
const RECEPTOR_Y := 125.0
const DOWNSCROLL_BOTTOM_MARGIN := 120.0
const SPACING := 92.0
const LEFT_ORIGIN := 133.0
const RIGHT_ORIGIN := 649.0
const ATLAS_SCALE := 0.53
const BASE_SCROLL_PX := 300.0
const HIT_WINDOW := 0.180
const HOLD_RELEASE_GRACE := 0.075
const CONFIRM_SECONDS := 0.18

var note_animations: Array = []
var receptor_animations: Dictionary = {}
var hold_animations: Dictionary = {}
var splash_animations: Dictionary = {}
var active_splashes: Array[Dictionary] = []
var chart: Array[Dictionary] = []
var score := ScoreSystem.new()
var health := FNFHealthSystem.new()
var music: AudioStreamPlayer
var song_time := -3.0
var audio_started := false
var running := false
var finished := false
var song_audio_finished: bool = false
var countdown := 2.4
var countdown_next_index := 1
var judgement_texture: Dictionary = {}
var last_judgement := ""
var judgement_at_time := -100.0
var selected_title := "BOPEEBO"
var duration := 81.5
var last_note_end := 0.0
var speed := 1.3
var bpm := 100.0
var held: Array[bool] = [false, false, false, false]
var confirmation_times: Array[float] = [-100.0, -100.0, -100.0, -100.0, -100.0, -100.0, -100.0, -100.0]
var opponent_hold_until: Array[float] = [0.0, 0.0, 0.0, 0.0]
var status_text := ""
var player_notes := 0
var opponent_notes := 0
var assets_loaded := false
var last_beat_index := -1
var pose_preview_index := 0
# Hud grafica original e tela de game over.
var vcr_text: VCRBitmapText
var health_bar_texture: Texture2D
var icon_player: Texture2D
var icon_opponent: Texture2D
var death_atlas: SparrowAtlas
var death_animations: Dictionary = {}
var game_over := false
var game_over_confirming := false
var game_over_time := 0.0
const DEATH_FPS := 24.0
var loss_player: AudioStreamPlayer
var game_over_music: AudioStreamPlayer
var game_over_end: AudioStreamPlayer
@onready var dad: FNFCharacter = get_node("../../World/Dad") as FNFCharacter
@onready var girlfriend: FNFGirlfriend = get_node("../../World/Girlfriend") as FNFGirlfriend
@onready var boyfriend: FNFCharacter = get_node("../../World/Boyfriend") as FNFCharacter
@onready var battle_camera: FNFCameraController = get_node("../../World/BattleCamera") as FNFCameraController

func _ready() -> void:
    var data: Dictionary = ChartLoader.load_psych(Settings.selected_chart_path)
    chart = data.get("notes", [])
    speed = float(data.get("speed", 1.3))
    bpm = maxf(1.0, float(data.get("bpm", 100.0)))
    countdown = 4.0 * 60.0 / bpm
    selected_title = str(data.get("title", "BOPEEBO")).to_upper()
    for item in ["ready", "set", "go", "sick", "good", "bad", "shit"]:
        var ui_path: String = "res://assets/gameplay_ui/%s.png" % item
        if ResourceLoader.exists(ui_path):
            judgement_texture[item] = load(ui_path)
    for note in chart:
        last_note_end = maxf(last_note_end, float(note["time"]) + float(note["sustain"]))
        if bool(note["player"]):
            player_notes += 1
        else:
            opponent_notes += 1
    music = AudioStreamPlayer.new()
    music.name = Settings.selected_song_id
    add_child(music)
    music.finished.connect(_on_song_audio_finished)
    music.stream = ModManager.audio_from_file(Settings.selected_audio_path)
    if music.stream != null:
        duration = music.stream.get_length()
    else:
        push_error("Audio nao encontrado: " + Settings.selected_audio_path)
    _load_real_sprites()
    _load_splash_atlas()
    vcr_text = VCRBitmapText.new()
    health_bar_texture = load("res://assets/health/healthBar.png") as Texture2D
    icon_player = load("res://assets/health/icon-bf.png") as Texture2D
    icon_opponent = load("res://assets/health/icon-dad.png") as Texture2D
    var mod_song: Dictionary = ModManager.get_song(Settings.selected_song_id)
    if not mod_song.is_empty():
        var custom_icon_path: String = str(mod_song.get("icon", ""))
        if not custom_icon_path.is_empty():
            var custom_icon: Texture2D = ModManager.texture_from_file(custom_icon_path)
            if custom_icon != null:
                icon_opponent = custom_icon
        else:
            var placeholder_icon := load("res://assets/health/icon-mod-placeholder.png") as Texture2D
            if placeholder_icon != null:
                icon_opponent = placeholder_icon
    _load_death_atlas()
    _init_game_over_audio()
    battle_camera.reset_view()
    _reset() # Story Mode automatically starts the countdown.
    print("%s %s: %d notas (jogador=%d / oponente=%d), BPM %.0f" % [selected_title, Settings.selected_difficulty.to_upper(), chart.size(), player_notes, opponent_notes, bpm])
    queue_redraw()

func _on_song_audio_finished() -> void:
    # AudioStreamPlayer.finished e emitido ao terminar naturalmente, nao ao dar stop().
    song_audio_finished = true

func _complete_song() -> void:
    if finished or game_over:
        return
    finished = true
    running = false
    music.stop()
    # Story Mode proceeds through the imported Week 1 playlist without
    # returning to the week selector between tracks. Freeplay plays one song.
    if Settings.advance_story_song():
        SceneTransition.change_to("res://scenes/gameplay.tscn")
        return
    var destination: String = Settings.return_menu_scene
    if destination.is_empty() or not ResourceLoader.exists(destination):
        destination = "res://scenes/main.tscn"
    SceneTransition.change_to(destination)

func _load_real_sprites() -> void:
    note_animations.clear()
    receptor_animations.clear()
    hold_animations.clear()
    var notes_atlas := SparrowAtlas.new()
    var strum_atlas := SparrowAtlas.new()
    var hold_atlas := SparrowAtlas.new()
    if not notes_atlas.open_pair("notes") or not strum_atlas.open_pair("noteStrumline") or not hold_atlas.open_pair("holdNote"):
        assets_loaded = false
        return
    for lane in range(4):
        var dir: String = DIRECTIONS[lane]
        note_animations.append(notes_atlas.animation("note" + dir))
        hold_animations["body_%d" % lane] = hold_atlas.animation("hold" + dir + "Body")
        hold_animations["end_%d" % lane] = hold_atlas.animation("hold" + dir + "End")
        receptor_animations["static_%d" % lane] = strum_atlas.animation("static" + dir)
        receptor_animations["press_%d" % lane] = strum_atlas.animation("press" + dir)
        receptor_animations["confirm_%d" % lane] = strum_atlas.animation("confirm" + dir + "0")
        receptor_animations["confirm_hold_%d" % lane] = strum_atlas.animation("confirmHold" + dir + "0")
    assets_loaded = true
    for frames in note_animations:
        if frames.is_empty():
            assets_loaded = false
    for lane in range(4):
        for kind in ["body", "end"]:
            if (hold_animations.get("%s_%d" % [kind, lane], []) as Array).is_empty():
                assets_loaded = false
        for kind in ["static", "press", "confirm", "confirm_hold"]:
            if (receptor_animations.get("%s_%d" % [kind, lane], []) as Array).is_empty():
                assets_loaded = false
    if not assets_loaded:
        push_error("Alguns frames nao foram reconhecidos. Confira notes.xml e noteStrumline.xml")

func _load_splash_atlas() -> void:
    splash_animations.clear()
    var splash_atlas := SparrowAtlas.new()
    if not splash_atlas.open_pair("noteSplashes", "res://assets/gameplay_ui/"):
        return
    var colors := ["purple", "blue", "green", "red"]
    for lane in range(4):
        var impact_name: String = "note impact 1  blue" if lane == 1 else "note impact 1 " + str(colors[lane])
        var frames: Array[Dictionary] = splash_atlas.animation_exact(impact_name)
        if frames.is_empty():
            frames = splash_atlas.animation_exact("note impact 2 " + colors[lane])
        splash_animations[lane] = frames

func _spawn_splash(lane: int) -> void:
    if (splash_animations.get(lane, []) as Array).is_empty():
        return
    active_splashes.append({"lane": lane, "elapsed": 0.0})

func _load_death_atlas() -> void:
    death_animations.clear()
    death_atlas = SparrowAtlas.new()
    if not death_atlas.open_pair("BOYFRIEND_DEAD", "res://assets/gameover/"):
        push_error("Nao foi possivel carregar o atlas do Game Over")
        return
    death_animations["dies"] = death_atlas.animation_exact("BF dies")
    death_animations["loop"] = death_atlas.animation_exact("BF Dead Loop")
    death_animations["confirm"] = death_atlas.animation_exact("BF Dead confirm")

# Trilha de Game Over em tres etapas, independente do MP3 da musica.
func _init_game_over_audio() -> void:
    loss_player = AudioStreamPlayer.new()
    loss_player.name = "LossSFX"
    add_child(loss_player)
    game_over_music = AudioStreamPlayer.new()
    game_over_music.name = "GameOverMusic"
    add_child(game_over_music)
    game_over_end = AudioStreamPlayer.new()
    game_over_end.name = "GameOverEndSFX"
    add_child(game_over_end)
    var loss_path := "res://assets/sfx/fnf_loss_sfx.ogg"
    var loop_path := "res://assets/sfx/gameOver.ogg"
    var end_path := "res://assets/sfx/gameOverEnd.ogg"
    if ResourceLoader.exists(loss_path):
        loss_player.stream = load(loss_path) as AudioStream
    if ResourceLoader.exists(loop_path):
        game_over_music.stream = load(loop_path) as AudioStream
    if ResourceLoader.exists(end_path):
        game_over_end.stream = load(end_path) as AudioStream
    loss_player.finished.connect(_on_loss_finished)
    game_over_music.finished.connect(_on_game_over_music_finished)
    game_over_end.finished.connect(_on_game_over_end_finished)

func _on_loss_finished() -> void:
    if game_over and not game_over_confirming:
        _play_game_over_music()

func _play_game_over_music() -> void:
    if game_over_music.stream != null:
        game_over_music.play()

func _on_game_over_music_finished() -> void:
    if game_over and not game_over_confirming:
        _play_game_over_music()

func _on_game_over_end_finished() -> void:
    if game_over and game_over_confirming:
        _reset()

func _trigger_game_over() -> void:
    if game_over:
        return
    game_over = true
    game_over_confirming = false
    game_over_time = 0.0
    finished = false
    running = false
    music.stop()
    game_over_music.stop()
    game_over_end.stop()
    if loss_player.stream != null:
        loss_player.play()
    else:
        _play_game_over_music()
    boyfriend.visible = false
    dad.visible = false
    girlfriend.visible = false
    battle_camera.reset_view()
    queue_redraw()

func _start_game_over_confirm() -> void:
    if game_over_confirming:
        return
    game_over_confirming = true
    game_over_time = 0.0
    loss_player.stop()
    game_over_music.stop()
    if game_over_end.stream != null:
        game_over_end.play()
    else:
        _reset()

func _death_frames_and_index() -> Dictionary:
    var frames: Array = []
    var frame_id := 0
    if game_over_confirming:
        frames = death_animations.get("confirm", [])
        frame_id = mini(int(game_over_time * DEATH_FPS), maxi(0, frames.size() - 1))
    else:
        var dies: Array = death_animations.get("dies", [])
        var intro_time: float = float(dies.size()) / DEATH_FPS
        if game_over_time < intro_time:
            frames = dies
            frame_id = mini(int(game_over_time * DEATH_FPS), maxi(0, frames.size() - 1))
        else:
            frames = death_animations.get("loop", [])
            frame_id = int((game_over_time - intro_time) * DEATH_FPS) % maxi(1, frames.size())
    return {"frames": frames, "index": frame_id}

func _reset() -> void:
    music.stop()
    if loss_player != null:
        loss_player.stop()
    if game_over_music != null:
        game_over_music.stop()
    if game_over_end != null:
        game_over_end.stop()
    game_over = false
    game_over_confirming = false
    game_over_time = 0.0
    boyfriend.visible = true
    dad.visible = true
    girlfriend.visible = not Settings.selected_hide_girlfriend
    health.reset()
    active_splashes.clear()
    girlfriend.reset_dance()
    song_time = -countdown
    running = true
    finished = false
    audio_started = false
    song_audio_finished = false
    held = [false, false, false, false]
    confirmation_times = [-100.0, -100.0, -100.0, -100.0, -100.0, -100.0, -100.0, -100.0]
    opponent_hold_until = [0.0, 0.0, 0.0, 0.0]
    score = ScoreSystem.new()
    countdown_next_index = 1
    last_judgement = ""
    judgement_at_time = -100.0
    MenuSFX.play("intro1", -3.0)
    last_beat_index = -1
    pose_preview_index = 0
    dad.reset_idle()
    boyfriend.reset_idle()
    battle_camera.reset_view()
    status_text = ""
    for note in chart:
        note["head_hit"] = false
        note["holding"] = false
        note["complete"] = false
        note["missed"] = false
    queue_redraw()

func _process(delta: float) -> void:
    if game_over:
        game_over_time += delta
        queue_redraw()
        return
    if not running or finished:
        return
    for splash in active_splashes:
        splash["elapsed"] = float(splash["elapsed"]) + delta
    active_splashes = active_splashes.filter(func(s: Dictionary) -> bool: return float(s["elapsed"]) < 0.25)
    if not audio_started:
        song_time += delta
        if song_time >= 0.0:
            song_time = 0.0
            audio_started = true
            if music.stream != null:
                music.play()
    elif music.playing:
        song_time = maxf(0.0, music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
    else:
        song_time += delta

    # Psych countdown: intro1 (no image), intro2 READY, intro3 SET, introGo GO.
    # Start the MP3 after 4 beats, rather than after a hard-coded 3 seconds.
    var beat_duration := 60.0 / bpm
    while countdown_next_index < 4 and song_time >= -beat_duration * float(4 - countdown_next_index):
        var clip_names := ["intro1", "intro2", "intro3", "introGo"]
        MenuSFX.play(clip_names[countdown_next_index], -3.0)
        countdown_next_index += 1

    if song_time >= 0.0:
        var beat_index := int(floor(song_time * bpm / 60.0))
        if beat_index != last_beat_index:
            last_beat_index = beat_index
            dad.bop()
            boyfriend.bop()
            girlfriend.dance()
            battle_camera.pulse_beat()

    for note in chart:
        if bool(note["complete"]) or bool(note["missed"]):
            continue
        var start: float = float(note["time"])
        var length: float = float(note["sustain"])
        var end: float = start + length
        var lane: int = int(note["lane"])
        if bool(note["player"]):
            if bool(note["holding"]):
                if song_time >= end - HOLD_RELEASE_GRACE:
                    note["complete"] = true
                    note["holding"] = false
                    status_text = "HOLD OK"
                elif not held[lane] and song_time < end - HOLD_RELEASE_GRACE:
                    note["holding"] = false
                    note["missed"] = true
                    score.miss()
                    health.on_hold_break()
                    MenuSFX.play_miss()
                    boyfriend.miss(lane)
                    status_text = "HOLD MISS"
            elif not bool(note["head_hit"]) and song_time > start + HIT_WINDOW:
                note["missed"] = true
                score.miss()
                health.on_miss()
                MenuSFX.play_miss()
                boyfriend.miss(lane)
                status_text = score.rating
        else:
            if not bool(note["head_hit"]) and song_time >= start:
                note["head_hit"] = true
                confirmation_times[lane] = song_time
                if Settings.selected_song_id.get_slice(":", 1 if Settings.selected_song_id.contains(":") else 0) == "tutorial" and girlfriend.visible:
                    girlfriend.sing(lane)
                else:
                    dad.sing(lane, length)
                battle_camera.focus_character(false, lane)
                opponent_hold_until[lane] = maxf(opponent_hold_until[lane], end)
                if length <= 0.0:
                    note["complete"] = true
            elif bool(note["head_hit"]) and song_time >= end:
                note["complete"] = true

    if health.depleted():
        _trigger_game_over()
        return

    # Ao terminar naturalmente, volta ao menu de origem, sem exigir Enter.
    # Se o MP3 terminar ligeiramente antes de um sustain final, aguarda seu fim.
    var chart_completed: bool = song_time >= last_note_end + 0.15
    var reached_audio_end: bool = song_audio_finished and chart_completed
    var reached_fallback_end: bool = song_time >= maxf(duration + 0.35, last_note_end + 0.5)
    if audio_started and (reached_audio_end or reached_fallback_end):
        _complete_song()
        return
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if SceneTransition.transitioning:
        return
    if not (event is InputEventKey):
        return
    if game_over:
        if event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]:
            _start_game_over_confirm()
            get_viewport().set_input_as_handled()
        elif event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
            MenuSFX.play("cancel", -4.0)
            Settings.clear_story_playlist()
            SceneTransition.change_to(Settings.return_menu_scene)
        return
    # F2: debug das animacoes sem precisar tocar a musica.
    if event.pressed and not event.echo and event.keycode == KEY_F2:
        pose_preview_index = (pose_preview_index + 1) % 5
        if pose_preview_index == 0:
            dad.reset_idle()
            boyfriend.reset_idle()
            status_text = "ANIMACAO: IDLE"
        else:
            dad.sing(pose_preview_index - 1, 3.0)
            boyfriend.sing(pose_preview_index - 1, 3.0)
            status_text = "ANIMACAO: " + DIRECTIONS[pose_preview_index - 1].to_upper()
        queue_redraw()
        return
    if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        music.stop()
        MenuSFX.play("cancel", -4.0)
        Settings.clear_story_playlist()
        SceneTransition.change_to(Settings.return_menu_scene)
        return
    if event.pressed and not event.echo and event.keycode == KEY_C and Settings.find_lane(KEY_C) < 0:
        battle_camera.toggle_follow()
        status_text = "CAMERA AUTOMATICA" if battle_camera.auto_follow else "CAMERA CENTRAL"
        return
    if event.pressed and not event.echo and event.keycode == KEY_BRACKETLEFT:
        battle_camera.adjust_zoom(-0.05)
        return
    if event.pressed and not event.echo and event.keycode == KEY_BRACKETRIGHT:
        battle_camera.adjust_zoom(0.05)
        return
    if event.pressed and not event.echo and event.keycode == KEY_R and Settings.find_lane(KEY_R) < 0:
        battle_camera.reset_view()
        return
    if event.pressed and not event.echo and event.keycode == KEY_ENTER:
        return
    if not running or finished or song_time < -HIT_WINDOW:
        return
    var lane: int = Settings.find_lane(event.keycode)
    if lane == -1:
        return
    if event.pressed and not event.echo:
        held[lane] = true
        _attempt_hit(lane)
    elif not event.pressed:
        held[lane] = Input.is_key_pressed(Settings.get_binding(lane)) or Input.is_key_pressed(Settings.get_binding(lane, true))
    queue_redraw()

func _attempt_hit(lane: int) -> void:
    var candidate: Dictionary = {}
    var best_error := HIT_WINDOW + 1.0
    for note in chart:
        if not bool(note["player"]) or bool(note["head_hit"]) or bool(note["missed"]) or int(note["lane"]) != lane:
            continue
        var error := absf(song_time - float(note["time"]))
        if error <= HIT_WINDOW and error < best_error:
            candidate = note
            best_error = error
    if candidate.is_empty():
        return
    candidate["head_hit"] = true
    score.hit(song_time - float(candidate["time"]))
    if score.rating == "SICK!":
        _spawn_splash(lane)
    health.on_hit()
    last_judgement = score.rating.to_lower().replace("!", "")
    judgement_at_time = song_time
    confirmation_times[4 + lane] = song_time
    boyfriend.sing(lane, float(candidate["sustain"]))
    battle_camera.focus_character(true, lane)
    status_text = score.rating
    if float(candidate["sustain"]) > 0.0:
        candidate["holding"] = true
    else:
        candidate["complete"] = true

func _receptor_state(side: int, lane: int) -> String:
    if not running:
        return "static"
    var index: int = side * 4 + lane
    if side == 0 and song_time < opponent_hold_until[lane] and song_time >= 0.0:
        return "confirm_hold"
    if side == 1 and held[lane] and _player_holding_lane(lane):
        return "confirm_hold"
    if song_time - confirmation_times[index] < CONFIRM_SECONDS and song_time >= confirmation_times[index]:
        return "confirm"
    if side == 1 and held[lane]:
        return "press"
    return "static"

func _player_holding_lane(lane: int) -> bool:
    for note in chart:
        if bool(note["player"]) and int(note["lane"]) == lane and bool(note["holding"]):
            return true
    return false


func _lane_x(player: bool, lane: int) -> float:
    var width := get_viewport_rect().size.x
    if Settings.middlescroll:
        var player_first: float = width * 0.5 - 1.5 * SPACING
        if player:
            return player_first + float(lane) * SPACING
        # Duas setas pequenas de cada lado da strumline central do jogador.
        var opponent_offsets := [-165.0, -102.0, 3.0 * SPACING + 102.0, 3.0 * SPACING + 165.0]
        return player_first + opponent_offsets[lane]
    var screen_offset: float = (width - 1100.0) * 0.5
    return (RIGHT_ORIGIN if player else LEFT_ORIGIN) + float(lane) * SPACING + screen_offset

func _lane_sprite_scale(player: bool) -> float:
    return ATLAS_SCALE * (0.56 if Settings.middlescroll and not player else 1.0)

func _receptor_position_y() -> float:
    return get_viewport_rect().size.y - DOWNSCROLL_BOTTOM_MARGIN if Settings.downscroll else RECEPTOR_Y

func _scroll_sign() -> float:
    return -1.0 if Settings.downscroll else 1.0

func _note_y(note_time: float, pixels_per_second: float) -> float:
    return _receptor_position_y() + _scroll_sign() * (note_time - song_time) * pixels_per_second

func _draw() -> void:
    var viewport_size := get_viewport_rect().size
    var receiver_y := _receptor_position_y()
    var pixels_per_second := BASE_SCROLL_PX * speed
    var top_limit := 78.0
    var bottom_limit := viewport_size.y - 70.0

    for side in range(2):
        var player := side == 1
        for lane in range(4):
            var x: float = _lane_x(player, lane)
            var factor: float = 0.56 if Settings.middlescroll and not player else 1.0
            draw_rect(Rect2(x - 43.0 * factor, top_limit, 86.0 * factor, bottom_limit - top_limit), Color(0.0, 0.0, 0.0, 0.12))

    # CAMADA 1: receptors atras das notas. As notas estao em CanvasLayer e
    # nunca se movem com Camera2D (apenas o palco e personagens se movem).
    for side in range(2):
        var player := side == 1
        for lane in range(4):
            var x: float = _lane_x(player, lane)
            var state := _receptor_state(side, lane)
            var frames: Array = receptor_animations.get("%s_%d" % [state, lane], [])
            var animation_frame := 0
            if state == "confirm":
                animation_frame = mini(int(maxf(0.0, song_time - confirmation_times[side * 4 + lane]) * 24.0), frames.size() - 1)
            elif state == "confirm_hold":
                animation_frame = int(maxf(0.0, song_time) * 16.0) % maxi(1, frames.size())
            elif state == "press":
                animation_frame = 1 if frames.size() > 1 else 0
            _draw_frame(frames, Vector2(x, receiver_y), animation_frame, _lane_sprite_scale(player))

    # CAMADA 2: caudas das notas; CAMADA 3: cabecas sobre os receptors.
    if running:
        for note in chart:
            if bool(note["complete"]) or bool(note["missed"]) or float(note["sustain"]) <= 0.0:
                continue
            var player: bool = bool(note["player"])
            var lane: int = int(note["lane"])
            var x: float = _lane_x(player, lane)
            var start_y: float = _note_y(float(note["time"]), pixels_per_second)
            var end_y: float = _note_y(float(note["time"]) + float(note["sustain"]), pixels_per_second)
            _draw_hold(lane, x, start_y, end_y, receiver_y, top_limit, bottom_limit, _lane_sprite_scale(player))

        for note in chart:
            if bool(note["head_hit"]) or bool(note["complete"]) or bool(note["missed"]):
                continue
            var player: bool = bool(note["player"])
            var lane: int = int(note["lane"])
            var x: float = _lane_x(player, lane)
            var y: float = _note_y(float(note["time"]), pixels_per_second)
            if y < top_limit - 40.0 or y > bottom_limit + 40.0:
                continue
            _draw_frame(note_animations[lane], Vector2(x, y), 0, _lane_sprite_scale(player))

    # Splashes ficam presos ao receptor do jogador (HUD, nao camera).
    for splash in active_splashes:
        var lane: int = int(splash["lane"])
        var frames: Array = splash_animations.get(lane, [])
        if frames.is_empty():
            continue
        var elapsed: float = float(splash["elapsed"])
        var index := mini(int(elapsed * 22.0), frames.size() - 1)
        _draw_frame(frames, Vector2(_lane_x(true, lane), receiver_y), index, 0.40)

    # HUD limpa: barra/ícones, estatísticas em VCR e julgamentos em PNG.
    _draw_health_hud(viewport_size)
    if game_over:
        _draw_game_over(viewport_size)
    elif running and song_time < 0.0:
        _draw_countdown(viewport_size)
    elif running and not finished:
        _draw_judgement(viewport_size)

func _draw_health_hud(viewport_size: Vector2) -> void:
    var bar_width: float = minf(600.0, viewport_size.x - 180.0)
    var bar_height := 19.0
    var bar_x: float = (viewport_size.x - bar_width) * 0.5
    var bar_y: float = viewport_size.y - 95.0
    var border: float = 5.0
    var inside_left := bar_x + border
    var inside_width := bar_width - border * 2.0
    var fraction := clampf(health.health / FNFHealthSystem.MAX_HEALTH, 0.0, 1.0)
    var divider_x: float = inside_left + inside_width * (1.0 - fraction)
    # Barra vermelha no lado esquerdo (Dad), verde no direito (BF).
    draw_rect(Rect2(inside_left, bar_y + 4.0, inside_width, bar_height - 8.0), Color("#f32731"))
    draw_rect(Rect2(divider_x, bar_y + 4.0, inside_left + inside_width - divider_x, bar_height - 8.0), Color("#16ea24"))
    if health_bar_texture != null:
        draw_texture_rect(health_bar_texture, Rect2(bar_x, bar_y, bar_width, bar_height), false)
    else:
        draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color.BLACK, false, 4.0)

    # Icones repousam NA barra (sobrepoem a linha divisoria), como no FNF.
    # Dad, a esquerda, olha para a direita. BF, a direita, olha para a esquerda.
    # O centro dos dois sprites coincide com o centro da barra de vida,
    # em vez de flutuar acima da borda superior.
    var icon_y := bar_y + bar_height * 0.5
    # Icones de 110 px se encontram na divisao e olham um para o outro.
    _draw_health_icon(icon_opponent, Vector2(divider_x - 55.0, icon_y), health.health >= 1.60, false)
    _draw_health_icon(icon_player, Vector2(divider_x + 55.0, icon_y), health.health <= 0.40, true)

    var info := "Pontos: %d  |  Erros: %d  |  Precisão: %.1f%%  |  Combo: %d" % [score.score, score.misses, score.accuracy(), score.combo]
    if vcr_text != null:
        vcr_text.draw_text(self, info, Vector2(14.0, viewport_size.y - 10.0), 22.0, Color.WHITE)

func _draw_health_icon(texture: Texture2D, center: Vector2, losing: bool, mirror: bool = false) -> void:
    if texture == null:
        return
    # Dad enfrenta a direita, BF e espelhado para enfrentar Dad.
    var frame_width: float = texture.get_width() * 0.5
    var source := Rect2(frame_width if losing else 0.0, 0.0, frame_width, texture.get_height())
    var target_size := Vector2(110.0, 110.0)
    if mirror:
        draw_set_transform(Vector2(center.x * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
    draw_texture_rect_region(texture, Rect2(center - target_size * 0.5, target_size), source, Color.WHITE)
    if mirror:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_game_over(viewport_size: Vector2) -> void:
    # Preto opaco: nenhum pedaço do stage aparece atras do BF morto.
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color.BLACK)
    var state: Dictionary = _death_frames_and_index()
    var frames: Array = state.get("frames", [])
    if frames.is_empty():
        return
    _draw_frame(frames, Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5), int(state.get("index", 0)), 1.1)

func _draw_hold(lane: int, x: float, start_y: float, end_y: float, receptor_y: float, top_limit: float, bottom_limit: float, note_scale: float) -> void:
    var body_frames: Array = hold_animations.get("body_%d" % lane, [])
    var end_frames: Array = hold_animations.get("end_%d" % lane, [])
    if body_frames.is_empty() or end_frames.is_empty():
        return
    var body: Dictionary = body_frames[0]
    var ending: Dictionary = end_frames[0]
    var texture: Texture2D = body["texture"]
    var body_region: Rect2 = body["src"]
    var end_region: Rect2 = ending["src"]
    var width: float = body_region.size.x * note_scale
    var cap_height: float = end_region.size.y * note_scale

    if not Settings.downscroll:
        # Upscroll: cabeca em start_y, parte arredondada abaixo em end_y.
        var clipping_top: float = maxf(top_limit, receptor_y + 4.0)
        var body_top: float = maxf(clipping_top, start_y + 8.0)
        var body_bottom: float = minf(bottom_limit, end_y - cap_height)
        if body_bottom > body_top:
            draw_texture_rect_region(texture, Rect2(x - width * 0.5, body_top, width, body_bottom - body_top), body_region, Color.WHITE)
        var cap_top: float = end_y - cap_height
        var visible_top: float = maxf(clipping_top, cap_top)
        var visible_bottom: float = minf(bottom_limit, end_y)
        if visible_bottom > visible_top:
            var fraction: float = (visible_top - cap_top) / cap_height
            var fraction_length: float = (visible_bottom - visible_top) / cap_height
            var crop := Rect2(end_region.position.x, end_region.position.y + end_region.size.y * fraction, end_region.size.x, end_region.size.y * fraction_length)
            draw_texture_rect_region(texture, Rect2(x - width * 0.5, visible_top, width, visible_bottom - visible_top), crop, Color.WHITE)
    else:
        # Downscroll: a cauda sobe da cabeca em direcao ao topo da tela.
        var clipping_bottom: float = minf(bottom_limit, receptor_y - 4.0)
        var body_top: float = maxf(top_limit, end_y + cap_height)
        var body_bottom: float = minf(clipping_bottom, start_y - 8.0)
        if body_bottom > body_top:
            draw_texture_rect_region(texture, Rect2(x - width * 0.5, body_top, width, body_bottom - body_top), body_region, Color.WHITE)
        # Inverte verticalmente a tampa arredondada: ponta no TOPO no downscroll.
        var cap_top: float = maxf(top_limit, end_y)
        var cap_bottom: float = minf(clipping_bottom, end_y + cap_height)
        if cap_bottom > cap_top:
            var source_begin: float = (cap_top - end_y) / cap_height
            var source_end: float = (cap_bottom - end_y) / cap_height
            var crop := Rect2(end_region.position.x, end_region.position.y + end_region.size.y * (1.0 - source_end), end_region.size.x, end_region.size.y * (source_end - source_begin))
            draw_set_transform(Vector2(0.0, cap_top + cap_bottom), 0.0, Vector2(1.0, -1.0))
            draw_texture_rect_region(texture, Rect2(x - width * 0.5, cap_top, width, cap_bottom - cap_top), crop, Color.WHITE)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_frame(animation: Array, center: Vector2, frame_index: int, note_scale: float = ATLAS_SCALE) -> void:
    if animation.is_empty():
        return
    var frame: Dictionary = animation[clampi(frame_index, 0, animation.size() - 1)]
    var src: Rect2 = frame["src"]
    var logical_size: Vector2 = frame["frame_size"]
    var frame_offset: Vector2 = frame["frame_offset"]
    # Reconstroi o ponto certo do frame sem trimming a partir de frameX/Y.
    var top_left := center - logical_size * note_scale * 0.5 - frame_offset * note_scale
    draw_texture_rect_region(frame["texture"], Rect2(top_left, src.size * note_scale), src, Color.WHITE)

func _center_text(message: String, viewport_size: Vector2) -> void:
    draw_rect(Rect2(viewport_size.x * 0.5 - 180.0, viewport_size.y * 0.48 - 42.0, 360.0, 65.0), Color(0, 0, 0, 0.55))
    draw_string(ThemeDB.fallback_font, Vector2(viewport_size.x * 0.5 - 170.0, viewport_size.y * 0.48), message, HORIZONTAL_ALIGNMENT_CENTER, 340, 27, Color.WHITE)

# Countdown and accuracy feedback are PNGs provided by user, not generic text.
func _draw_countdown(viewport_size: Vector2) -> void:
    var beat_duration := 60.0 / bpm
    var phase := -song_time / beat_duration
    var key := ""
    if phase <= 1.0:
        key = "go"
    elif phase <= 2.0:
        key = "set"
    elif phase <= 3.0:
        key = "ready"
    # The first beat is intro1: intentionally no image.
    if key.is_empty() or not judgement_texture.has(key):
        return
    var tex: Texture2D = judgement_texture[key]
    var scale := 0.45
    var extent := tex.get_size() * scale
    var center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
    var alpha := clampf(phase - floor(phase), 0.25, 1.0)
    draw_texture_rect(tex, Rect2(center - extent * 0.5, extent), false, Color(1.0, 1.0, 1.0, alpha))

func _draw_judgement(viewport_size: Vector2) -> void:
    var elapsed := song_time - judgement_at_time
    if elapsed < 0.0 or elapsed > 0.65 or not judgement_texture.has(last_judgement):
        return
    var tex: Texture2D = judgement_texture[last_judgement]
    var scale := 0.55
    var extent := tex.get_size() * scale
    var center := Vector2(viewport_size.x * 0.5 - 35.0, viewport_size.y * 0.50 - elapsed * 40.0)
    var alpha := clampf((0.65 - elapsed) / 0.28, 0.0, 1.0)
    draw_texture_rect(tex, Rect2(center - extent * 0.5, extent), false, Color(1.0, 1.0, 1.0, alpha))
