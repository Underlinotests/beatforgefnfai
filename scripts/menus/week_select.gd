extends Control

# Psych-inspired Story Mode, week1 menu art, character animations and available charts.
const TOP_HEIGHT := 336.0
const BOTTOM_START := 340.0
const DIFFICULTY_X := 915.0
const DIFFICULTY_Y := 435.0
const ARROW_LEFT_X := 781.0
const ARROW_RIGHT_X := 1050.0
var data: Dictionary = {}
var weeks: Array[Dictionary] = []
var difficulties: Array[String] = []
var difficulty_index := 0
var selected_week := 0
var locked := false
var title_texture: Texture2D
var difficulty_images: Dictionary = {}
var menu_arrow_frames: Dictionary = {}
var bf: FNFMenuActor
var dad: FNFMenuActor
var gf: FNFMenuActor
var started := false
var vcr_text: VCRBitmapText
# Movimento da lista de weeks: a proxima sobe; a anterior some em fade.
const SWITCH_SECONDS := 0.36
const SWITCH_DISTANCE := 115.0
var switch_elapsed := SWITCH_SECONDS
var switch_direction := 1
var previous_data: Dictionary = {}
var previous_title: Texture2D
var switching := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    vcr_text = VCRBitmapText.new()
    weeks = FNFWeekLibrary.all_weeks()
    if weeks.is_empty():
        push_error("Nenhuma week encontrada")
        return
    _choose_week(0)
    for kind in FNFWeekLibrary.DIFFICULTY_ORDER:
        difficulty_images[kind] = load("res://assets/menus/%s.png" % kind)
    var ui_atlas := SparrowAtlas.new()
    if ui_atlas.open_pair("campaign_menu_UI_assets", "res://assets/menus/"):
        menu_arrow_frames["left"] = ui_atlas.animation_exact("arrow left")
        menu_arrow_frames["right"] = ui_atlas.animation_exact("arrow right")
        menu_arrow_frames["push_left"] = ui_atlas.animation_exact("arrow push left")
        menu_arrow_frames["push_right"] = ui_atlas.animation_exact("arrow push right")
        menu_arrow_frames["lock"] = ui_atlas.animation_exact("lock")

    var stage := TextureRect.new()
    stage.texture = load("res://assets/menus/menu_stage.png")
    stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stage.stretch_mode = TextureRect.STRETCH_SCALE
    stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    stage.offset_bottom = TOP_HEIGHT
    stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(stage)

    dad = FNFMenuActor.new()
    dad.actor_id = "dad"
    dad.actor_scale = 0.78
    dad.position = Vector2(240, 324)
    add_child(dad)
    gf = FNFMenuActor.new()
    gf.actor_id = "gf"
    gf.actor_scale = 0.86
    gf.position = Vector2(857, 326)
    add_child(gf)
    bf = FNFMenuActor.new()
    bf.actor_id = "bf"
    bf.actor_scale = 0.79
    bf.position = Vector2(557, 326)
    add_child(bf)
    queue_redraw()

func _choose_week(index: int) -> void:
    if weeks.is_empty():
        return
    selected_week = posmod(index, weeks.size())
    data = weeks[selected_week]
    difficulties = FNFWeekLibrary.available_week_difficulties(data)
    difficulty_index = maxi(0, difficulties.find("hard"))
    title_texture = null
    var path: String = str(data.get("menu_image", ""))
    if not path.is_empty():
        title_texture = ModManager.texture_from_file(path)
    elif str(data.get("id", "")) == "week1":
        title_texture = load("res://assets/menus/week1.png") as Texture2D
    queue_redraw()

func _switch_week(direction: int) -> void:
    if started or weeks.size() <= 1:
        return
    previous_data = data.duplicate(true)
    previous_title = title_texture
    switch_elapsed = 0.0
    switch_direction = direction
    switching = true
    _choose_week(selected_week + direction)
    MenuSFX.play("scroll", -3.0)

func _process(delta: float) -> void:
    if switching:
        switch_elapsed += delta
        if switch_elapsed >= SWITCH_SECONDS:
            switch_elapsed = SWITCH_SECONDS
            switching = false
            previous_data.clear()
            previous_title = null
        queue_redraw()


func _draw() -> void:
    var size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(0.0, BOTTOM_START, size.x, size.y - BOTTOM_START), Color.BLACK)
    if switching:
        var fraction: float = clampf(switch_elapsed / SWITCH_SECONDS, 0.0, 1.0)
        # Sine ease-in-out para ambas as direcoes.
        var smooth := fraction * fraction * (3.0 - 2.0 * fraction)
        _draw_week_content(previous_data, previous_title, 1.0 - smooth, -float(switch_direction) * SWITCH_DISTANCE * smooth, false)
        _draw_week_content(data, title_texture, smooth, float(switch_direction) * SWITCH_DISTANCE * (1.0 - smooth), true)
    else:
        _draw_week_content(data, title_texture, 1.0, 0.0, true)

func _draw_week_content(week: Dictionary, title: Texture2D, alpha: float, dy: float, current: bool) -> void:
    if week.is_empty() or alpha <= 0.0:
        return
    draw_set_transform(Vector2(0.0, dy), 0.0, Vector2.ONE)
    var white := Color(1.0, 1.0, 1.0, alpha)
    if title != null:
        _draw_texture_center(title, Vector2(585, 420), 0.90, white)
    elif vcr_text != null:
        vcr_text.draw_text(self, str(week.get("name", "WEEK")).to_upper(), Vector2(405, 427), 42.0, white)
    var songs: Array[Dictionary] = FNFWeekLibrary.available_songs(week)
    if vcr_text != null:
        var label_color := Color("#e65884")
        label_color.a = alpha
        vcr_text.draw_text(self, "MÚSICAS", Vector2(98, 408), 26.0, label_color)
        for i in range(songs.size()):
            var song: Dictionary = songs[i]
            var song_color := Color("#f26c97")
            song_color.a = alpha
            vcr_text.draw_text(self, str(song.get("title", "")).to_upper(), Vector2(130, 446 + i * 31), 23.0, song_color)
    # Dificuldade acompanha a entrada da week selecionada.
    if current and not difficulties.is_empty():
        _draw_texture_center(difficulty_images.get(_current_difficulty()), Vector2(DIFFICULTY_X, DIFFICULTY_Y), 0.79, white)
        if difficulties.size() > 1:
            _draw_atlas_icon("left", Vector2(ARROW_LEFT_X, DIFFICULTY_Y), 0.86, white)
            _draw_atlas_icon("right", Vector2(ARROW_RIGHT_X, DIFFICULTY_Y), 0.86, white)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_texture_center(tex: Texture2D, center: Vector2, scale: float, tint: Color = Color.WHITE) -> void:
    if tex == null:
        return
    var actual_size: Vector2 = tex.get_size() * scale
    draw_texture_rect(tex, Rect2(center - actual_size * 0.5, actual_size), false, tint)

func _draw_atlas_icon(key: String, center: Vector2, scale: float, tint: Color) -> void:
    var frames: Array = menu_arrow_frames.get(key, [])
    if frames.is_empty():
        return
    var frame: Dictionary = frames[0]
    var src: Rect2 = frame["src"]
    var size: Vector2 = src.size * scale
    draw_texture_rect_region(frame["texture"], Rect2(center - size * 0.5, size), src, tint)

func _current_difficulty() -> String:
    return difficulties[difficulty_index] if not difficulties.is_empty() else ""

func _switch_difficulty(direction: int) -> void:
    if difficulties.size() <= 1 or started:
        return
    difficulty_index = posmod(difficulty_index + direction, difficulties.size())
    MenuSFX.play("scroll", -3.0)
    queue_redraw()

func _start_week() -> void:
    if started or difficulties.is_empty():
        return
    # Play every imported and playable song in the order given by week1.json.
    # The difficulty menu only offers difficulties available across the week.
    var week_songs: Array[Dictionary] = FNFWeekLibrary.available_songs(data)
    if not Settings.start_story_playlist(week_songs, _current_difficulty()):
        return
    started = true
    MenuSFX.play("confirm", -4.0)
    bf.trigger_confirm()
    Settings.return_menu_scene = "res://scenes/week_select.tscn"
    # Small delay allows BF's 'M bf HEY' to play before scene transition.
    await get_tree().create_timer(0.48).timeout
    SceneTransition.change_to("res://scenes/gameplay.tscn")

func _go_back() -> void:
    if started or SceneTransition.transitioning:
        return
    MenuSFX.play("cancel", -4.0)
    SceneTransition.change_to("res://scenes/main.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_UP, KEY_W]:
        _switch_week(-1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_DOWN, KEY_S]:
        _switch_week(1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_LEFT, KEY_A]:
        _switch_difficulty(-1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_RIGHT, KEY_D]:
        _switch_difficulty(1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_ENTER, KEY_SPACE]:
        _start_week()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_ESCAPE:
        _go_back()
        get_viewport().set_input_as_handled()

