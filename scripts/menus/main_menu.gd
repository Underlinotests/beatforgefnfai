extends Control

const ITEMS := ["story_mode", "freeplay", "mods", "options"]
const DESTINATIONS := [
    "res://scenes/week_select.tscn",
    "res://scenes/freeplay_menu.tscn",
    "res://scenes/mods_menu.tscn",
    "res://scenes/options_menu.tscn"
]
var sprites: Array[FNFMainMenuSprite] = []
var current_index: int = 0
var transitioning: bool = false
var bg_texture: Texture2D
var bg_y := 38.0
var bg_target_y := 38.0
var vcr: VCRBitmapText
var engine_label := "BeatForge Engine"

func _process(delta: float) -> void:
    bg_y = lerpf(bg_y, bg_target_y, 1.0 - exp(-7.5 * delta))
    queue_redraw()

func _draw() -> void:
    if bg_texture == null:
        return
    var screen: Vector2 = get_viewport_rect().size
    # Fundo ampliado: deslocamento acompanha a opcao sem revelar bordas.
    var margin := Vector2(75.0, 75.0)
    var offset := Vector2(-18.0, bg_y)
    draw_texture_rect(bg_texture, Rect2(-margin + offset, screen + margin * 2.0), false)
    if vcr != null:
        vcr.draw_text(self, engine_label.to_upper(), Vector2(18.0, screen.y - 20.0), 18.0, Color.WHITE)


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    vcr = VCRBitmapText.new()
    var app_name: String = str(ProjectSettings.get_setting("application/config/name", "BeatForge Engine"))
    var version: String = str(ProjectSettings.get_setting("application/config/version", "Modding v1"))
    engine_label = app_name + "  |  " + version
    bg_texture = load("res://assets/menus/menuBG.png") as Texture2D
    var size: Vector2 = get_viewport_rect().size
    var configs := [
        {"id": "story_mode", "pos": Vector2(size.x * 0.50, size.y * 0.23), "scale": 0.70},
        {"id": "freeplay",   "pos": Vector2(size.x * 0.50, size.y * 0.46), "scale": 0.74},
        {"id": "mods",       "pos": Vector2(size.x * 0.50, size.y * 0.68), "scale": 0.78},
        {"id": "options",    "pos": Vector2(size.x * 0.86, size.y * 0.84), "scale": 0.78}
    ]
    for cfg in configs:
        var item := FNFMainMenuSprite.new()
        item.item_id = cfg["id"]
        item.display_scale = cfg["scale"]
        item.position = cfg["pos"]
        add_child(item)
        sprites.append(item)
    _highlight()

func _highlight() -> void:
    for index in range(sprites.size()):
        sprites[index].set_selected(index == current_index)

func _select(index: int) -> void:
    if transitioning or current_index == index:
        return
    current_index = index
    MenuSFX.play("scroll", -3.0)
    bg_target_y = [38.0, 16.0, -12.0, -36.0][current_index]
    _highlight()

func _change(direction: int) -> void:
    _select(posmod(current_index + direction, ITEMS.size()))

func _confirm() -> void:
    if transitioning:
        return
    transitioning = true
    MenuSFX.play("confirm", -4.0)
    SceneTransition.change_to(DESTINATIONS[current_index])

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_UP, KEY_W]:
        _change(-1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_DOWN, KEY_S]:
        _change(1)
        get_viewport().set_input_as_handled()
    elif event.keycode in [KEY_ENTER, KEY_SPACE]:
        _confirm()
        get_viewport().set_input_as_handled()

