extends Control

# Freeplay dinamico: musicas surgem somente quando um chart JSON existe.
const LINE_HEIGHT := 93.0
const LIST_TOP := 185.0
var songs: Array[Dictionary] = []
var selected_index: int = 0
var difficulties: Array[String] = []
var difficulty_index: int = 0
var transitioning: bool = false
var vcr: VCRBitmapText
var bg_texture: Texture2D
var icon_texture: Texture2D
var mod_placeholder_icon: Texture2D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    vcr = VCRBitmapText.new()
    bg_texture = load("res://assets/menus/menuBG_purple.png") as Texture2D
    icon_texture = load("res://assets/health/icon-dad.png") as Texture2D
    mod_placeholder_icon = load("res://assets/health/icon-mod-placeholder.png") as Texture2D
    songs = FNFWeekLibrary.all_playable_catalog_songs()
    _update_difficulties()
    queue_redraw()

func _update_difficulties() -> void:
    difficulties.clear()
    if songs.is_empty():
        return
    difficulties = FNFWeekLibrary.available_difficulties(str(songs[selected_index].get("id", "")))
    difficulty_index = maxi(0, difficulties.find("hard"))

func _draw() -> void:
    var screen: Vector2 = get_viewport_rect().size
    if bg_texture != null:
        draw_texture_rect(bg_texture, Rect2(Vector2.ZERO, screen), false, Color.WHITE)
    # Cor violeta transparente: preserva as linhas e desenhos do fundo original.
    draw_rect(Rect2(Vector2.ZERO, screen), Color(0.19, 0.09, 0.48, 0.28))
    draw_rect(Rect2(Vector2(screen.x * 0.64, 0), Vector2(screen.x * 0.36, 45)), Color(0.09, 0.05, 0.22, 0.64))
    if not difficulties.is_empty():
        var selected_difficulty: String = difficulties[difficulty_index].to_upper()
        var diff_x: float = screen.x * 0.78
        var prefix: String = "‹ " if difficulties.size() > 1 else ""
        var suffix: String = " ›" if difficulties.size() > 1 else ""
        vcr.draw_text(self, prefix + selected_difficulty + suffix, Vector2(diff_x, 33.0), 25.0, Color.WHITE)
    for i in range(songs.size()):
        var song: Dictionary = songs[i]
        var y: float = LIST_TOP + (float(i) - float(selected_index)) * LINE_HEIGHT
        if y < 75.0 or y > screen.y + 40.0:
            continue
        var selected: bool = i == selected_index
        var song_color: Color = Color.WHITE if selected else Color(0.36, 0.25, 0.48, 0.78)
        var label_size: float = 45.0 if selected else 39.0
        vcr.draw_text(self, str(song.get("title", song.get("id", ""))).to_upper(), Vector2(87, y), label_size, song_color)
        _draw_song_icon(song, Vector2(screen.x * 0.40, y - 23.0), selected)

func _draw_song_icon(song: Dictionary, position: Vector2, active: bool) -> void:
    var is_mod_song: bool = not str(song.get("mod_id", "")).is_empty()
    var texture: Texture2D = mod_placeholder_icon if is_mod_song else icon_texture
    var custom_path: String = str(song.get("icon", ""))
    if not custom_path.is_empty():
        var resolved: Texture2D = ModManager.texture_from_file(custom_path)
        if resolved != null:
            texture = resolved
    elif not is_mod_song:
        texture = icon_texture
    if texture == null:
        return
    var frame_width := float(texture.get_width()) * 0.5
    var src := Rect2(0.0, 0.0, frame_width, float(texture.get_height()))
    var image_size := Vector2(74.0, 74.0)
    draw_texture_rect_region(texture, Rect2(position - image_size * 0.5, image_size), src, Color.WHITE if active else Color(0.48,0.33,0.63,0.78))

func _move(direction: int) -> void:
    if transitioning or songs.size() <= 1:
        return
    selected_index = posmod(selected_index + direction, songs.size())
    _update_difficulties()
    MenuSFX.play("scroll", -3.0)
    queue_redraw()

func _change_difficulty(direction: int) -> void:
    if transitioning or difficulties.size() <= 1:
        return
    difficulty_index = posmod(difficulty_index + direction, difficulties.size())
    MenuSFX.play("scroll", -3.0)
    queue_redraw()

func _start_song() -> void:
    if transitioning or songs.is_empty() or difficulties.is_empty():
        return
    var item: Dictionary = songs[selected_index]
    var song_id: String = str(item.get("id", ""))
    var difficulty: String = difficulties[difficulty_index]
    if not FNFWeekLibrary.song_is_playable(item, difficulty):
        push_warning("A musica precisa de chart e audio para iniciar: " + song_id)
        return
    transitioning = true
    Settings.clear_story_playlist() # Freeplay always plays a single song.
    Settings.apply_song(item, difficulty)
    Settings.return_menu_scene = "res://scenes/freeplay_menu.tscn"
    MenuSFX.play("confirm", -4.0)
    SceneTransition.change_to("res://scenes/gameplay.tscn")

func _go_back() -> void:
    if transitioning or SceneTransition.transitioning:
        return
    MenuSFX.play("cancel", -4.0)
    SceneTransition.change_to("res://scenes/main.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_UP, KEY_W]:
        _move(-1)
    elif event.keycode in [KEY_DOWN, KEY_S]:
        _move(1)
    elif event.keycode in [KEY_LEFT, KEY_A]:
        _change_difficulty(-1)
    elif event.keycode in [KEY_RIGHT, KEY_D]:
        _change_difficulty(1)
    elif event.keycode in [KEY_ENTER, KEY_SPACE]:
        _start_song()
    elif event.keycode == KEY_ESCAPE:
        _go_back()
    else:
        return
    get_viewport().set_input_as_handled()

