extends Control

# Gerenciador de mods sem botoes de mouse. Lista VCR navegada por teclado.
const CENTER_Y := 295.0
const ROW_GAP := 70.0
var mods: Array[Dictionary] = []
var selection := 0
var vcr: VCRBitmapText
var bg_texture: Texture2D
var bg_offset := 0.0
var target_offset := 0.0
var notice := ""
var transitioning := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    vcr = VCRBitmapText.new()
    bg_texture = load("res://assets/menus/menuBG.png") as Texture2D
    _refresh_mods()

func _refresh_mods() -> void:
    mods = ModManager.get_mod_list()
    selection = mini(selection, mods.size() + 2)
    _update_target()
    queue_redraw()

func _process(delta: float) -> void:
    bg_offset = lerpf(bg_offset, target_offset, 1.0 - exp(-7.5 * delta))
    queue_redraw()

func _update_target() -> void:
    target_offset = lerpf(-38.0, 38.0, float(selection) / maxf(1.0, float(mods.size() + 2)))

func _draw() -> void:
    var screen := get_viewport_rect().size
    if bg_texture != null:
        var margin := Vector2(78.0, 78.0)
        draw_texture_rect(bg_texture, Rect2(-margin + Vector2(-15.0, bg_offset), screen + margin * 2.0), false)
    draw_rect(Rect2(Vector2.ZERO, screen), Color(0.15, 0.08, 0.37, 0.50))
    draw_rect(Rect2(Vector2.ZERO, Vector2(screen.x, 57.0)), Color(0.08, 0.05, 0.20, 0.68))
    vcr.draw_text(self, "MODS", Vector2(42, 42), 33.0, Color.WHITE)
    if mods.is_empty():
        vcr.draw_text(self, "NENHUM MOD INSTALADO", Vector2(80, 153), 28.0, Color(0.68, 0.55, 0.80))
    for i in range(mods.size() + 3):
        var y: float = CENTER_Y + float(i - selection) * ROW_GAP
        if y < 104.0 or y > screen.y - 50.0:
            continue
        var active := i == selection
        var color := Color.WHITE if active else Color(0.39, 0.29, 0.52, 0.9)
        if i < mods.size():
            var mod: Dictionary = mods[i]
            vcr.draw_text(self, str(mod.get("name", mod.get("id", "MOD"))).to_upper(), Vector2(75, y), 34.0 if active else 29.0, color)
            var status := "ON" if bool(mod.get("enabled", true)) else "OFF"
            vcr.draw_text(self, status, Vector2(screen.x * 0.80, y), 30.0, color)
        else:
            var action: String = ["ABRIR PASTA", "RECARREGAR", "VOLTAR"][i - mods.size()]
            vcr.draw_text(self, action, Vector2(75, y), 34.0 if active else 29.0, color)
    if not notice.is_empty():
        vcr.draw_text(self, notice, Vector2(65, screen.y - 19), 19.0, Color.WHITE)

func _move(delta: int) -> void:
    if transitioning:
        return
    selection = posmod(selection + delta, mods.size() + 3)
    notice = ""
    _update_target()
    MenuSFX.play("scroll", -3.0)
    queue_redraw()

func _confirm() -> void:
    if transitioning:
        return
    if selection < mods.size():
        var mod: Dictionary = mods[selection]
        ModManager.set_enabled(str(mod["id"]), not bool(mod["enabled"]))
        MenuSFX.play("confirm", -4.0)
        _refresh_mods()
    elif selection == mods.size():
        OS.shell_open(ModManager.mods_folder())
        MenuSFX.play("confirm", -4.0)
    elif selection == mods.size() + 1:
        ModManager.rescan()
        _refresh_mods()
        notice = "MODS RECARREGADOS"
        MenuSFX.play("confirm", -4.0)
    else:
        _back()
    queue_redraw()

func _back() -> void:
    if transitioning or SceneTransition.transitioning:
        return
    transitioning = true
    MenuSFX.play("cancel", -4.0)
    SceneTransition.change_to("res://scenes/main.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode in [KEY_UP, KEY_W]:
        _move(-1)
    elif event.keycode in [KEY_DOWN, KEY_S]:
        _move(1)
    elif event.keycode in [KEY_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT]:
        _confirm()
    elif event.keycode == KEY_ESCAPE:
        _back()
    else:
        return
    get_viewport().set_input_as_handled()
