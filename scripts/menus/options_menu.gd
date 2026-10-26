extends Control

# Menu Options no mesmo estilo da lista do Freeplay: VCR + teclado.
# Apenas teclado: setas/W/S movem, Enter/Space selecionam, Esc volta.
const ROW_GAP := 68.0
const CENTER_Y := 290.0
const LABEL_X := 78.0
const VALUE_X := 675.0
const DIRECTIONS := ["ESQUERDA", "BAIXO", "CIMA", "DIREITA"]

var options: Array[Dictionary] = []
var selected_index := 0
var capture_lane := -1
var capture_secondary := false
var capture_notice := ""
var vcr: VCRBitmapText
var bg_texture: Texture2D
var bg_x := 0.0
var bg_y := 0.0
var target_x := 0.0
var target_y := 0.0
var transitioning := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    vcr = VCRBitmapText.new()
    bg_texture = load("res://assets/menus/menuBG.png") as Texture2D
    options = [
        {"kind": "downscroll", "title": "DOWNSCROLL"},
        {"kind": "middlescroll", "title": "MIDDLESCROLL"}
    ]
    for lane in range(4):
        options.append({"kind": "binding", "title": "TECLA " + DIRECTIONS[lane], "lane": lane, "secondary": false})
        options.append({"kind": "binding", "title": "ALT " + DIRECTIONS[lane], "lane": lane, "secondary": true})
    options.append({"kind": "restore", "title": "RESTAURAR PADROES"})
    options.append({"kind": "back", "title": "VOLTAR"})
    _update_background_target()
    bg_x = target_x
    bg_y = target_y
    queue_redraw()

func _process(delta: float) -> void:
    var weight := 1.0 - exp(-7.5 * delta)
    bg_x = lerpf(bg_x, target_x, weight)
    bg_y = lerpf(bg_y, target_y, weight)
    queue_redraw()

func _draw() -> void:
    var screen := get_viewport_rect().size
    if bg_texture != null:
        var margin := Vector2(78.0, 78.0)
        draw_texture_rect(bg_texture, Rect2(-margin + Vector2(bg_x, bg_y), screen + margin * 2.0), false)
    # Tons violeta, como Freeplay. Sem paineis de formularios nem botoes padrao.
    draw_rect(Rect2(Vector2.ZERO, screen), Color(0.17, 0.08, 0.40, 0.45))
    draw_rect(Rect2(Vector2.ZERO, Vector2(screen.x, 57.0)), Color(0.09, 0.05, 0.20, 0.68))
    vcr.draw_text(self, "OPTIONS", Vector2(38.0, 42.0), 33.0, Color.WHITE)

    if capture_lane >= 0:
        draw_rect(Rect2(0.0, screen.y - 63.0, screen.x, 63.0), Color(0.07, 0.04, 0.15, 0.76))
        vcr.draw_text(self, "PRESSIONE UMA TECLA  -  ESC CANCELA", Vector2(48.0, screen.y - 20.0), 23.0, Color.WHITE)
    elif not capture_notice.is_empty():
        draw_rect(Rect2(0.0, screen.y - 51.0, screen.x, 51.0), Color(0.07, 0.04, 0.15, 0.70))
        vcr.draw_text(self, capture_notice, Vector2(48.0, screen.y - 16.0), 22.0, Color.WHITE)

    for index in range(options.size()):
        var y: float = CENTER_Y + float(index - selected_index) * ROW_GAP
        if y < 105.0 or y > screen.y - 58.0:
            continue
        var option: Dictionary = options[index]
        var active := index == selected_index
        var color := Color.WHITE if active else Color(0.38, 0.29, 0.52, 0.90)
        var font_size := 35.0 if active else 30.0
        var title: String = str(option["title"])
        var value := _option_value(option)
        vcr.draw_text(self, title, Vector2(LABEL_X, y), font_size, color)
        if not value.is_empty():
            var value_color := Color(0.99, 0.89, 0.95) if active else Color(0.35, 0.27, 0.50, 0.86)
            vcr.draw_text(self, value, Vector2(VALUE_X, y), 30.0 if active else 26.0, value_color)

func _option_value(option: Dictionary) -> String:
    match str(option.get("kind", "")):
        "downscroll":
            return "ON" if Settings.downscroll else "OFF"
        "middlescroll":
            return "ON" if Settings.middlescroll else "OFF"
        "binding":
            var lane: int = int(option.get("lane", 0))
            var alternate: bool = bool(option.get("secondary", false))
            if capture_lane == lane and capture_secondary == alternate:
                return "..."
            return Settings.key_name(Settings.get_binding(lane, alternate)).to_upper()
    return ""

func _update_background_target() -> void:
    # Camera do fundo segue a opcao selecionada, como no menu principal.
    var ratio: float = float(selected_index) / maxf(1.0, float(options.size() - 1))
    target_y = lerpf(40.0, -40.0, ratio)
    target_x = sin(ratio * PI) * 19.0

func _move(direction: int) -> void:
    if transitioning or capture_lane >= 0:
        return
    selected_index = posmod(selected_index + direction, options.size())
    capture_notice = ""
    _update_background_target()
    MenuSFX.play("scroll", -3.0)
    queue_redraw()

func _confirm() -> void:
    if transitioning or capture_lane >= 0:
        return
    var option: Dictionary = options[selected_index]
    var kind: String = str(option["kind"])
    match kind:
        "downscroll":
            Settings.downscroll = not Settings.downscroll
            Settings.save_settings()
        "middlescroll":
            Settings.middlescroll = not Settings.middlescroll
            Settings.save_settings()
        "binding":
            capture_lane = int(option["lane"])
            capture_secondary = bool(option["secondary"])
        "restore":
            Settings.restore_defaults()
            capture_notice = "CONFIGURACOES RESTAURADAS"
        "back":
            _go_back()
            return
    MenuSFX.play("confirm", -5.0)
    queue_redraw()

func _go_back() -> void:
    if transitioning or SceneTransition.transitioning:
        return
    transitioning = true
    MenuSFX.play("cancel", -4.0)
    SceneTransition.change_to("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    var key: int = event.keycode
    if capture_lane >= 0:
        get_viewport().set_input_as_handled()
        if key == KEY_ESCAPE:
            capture_lane = -1
            capture_notice = "EDICAO CANCELADA"
            MenuSFX.play("cancel", -4.0)
        elif Settings.set_binding(capture_lane, capture_secondary, key):
            capture_lane = -1
            capture_notice = "TECLA SALVA"
            MenuSFX.play("confirm", -5.0)
        else:
            capture_notice = "TECLA RESERVADA OU EM USO"
        queue_redraw()
        return
    if key in [KEY_UP, KEY_W]:
        _move(-1)
    elif key in [KEY_DOWN, KEY_S]:
        _move(1)
    elif key in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
        if selected_index <= 1:
            _confirm()
    elif key in [KEY_ENTER, KEY_SPACE]:
        _confirm()
    elif key == KEY_ESCAPE:
        _go_back()
    else:
        return
    get_viewport().set_input_as_handled()
