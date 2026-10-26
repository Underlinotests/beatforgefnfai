extends CanvasLayer

# Transicao global persistente entre todas as cenas (menus e gameplay).
# A camada preta fica acima do CanvasLayer da HUD e nao ocupa input quando inativa.
const FADE_OUT_SECONDS := 0.30
const FADE_IN_SECONDS := 0.32

var transitioning: bool = false
var cover: ColorRect

func _ready() -> void:
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    cover = ColorRect.new()
    cover.name = "FadeCover"
    cover.color = Color.BLACK
    cover.modulate.a = 0.0
    cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(cover)
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_to(scene_path: String) -> void:
    if transitioning:
        return
    if not ResourceLoader.exists(scene_path):
        push_error("Cena de destino nao encontrada: " + scene_path)
        return

    transitioning = true
    cover.mouse_filter = Control.MOUSE_FILTER_STOP
    var fade_out: Tween = create_tween()
    fade_out.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    fade_out.tween_property(cover, "modulate:a", 1.0, FADE_OUT_SECONDS)
    await fade_out.finished

    var error: Error = get_tree().change_scene_to_file(scene_path)
    if error != OK:
        push_error("Falha ao carregar cena %s: %s" % [scene_path, error_string(error)])
    else:
        # O sinal so e emitido quando a nova cena terminou de inicializar.
        await get_tree().scene_changed

    var fade_in: Tween = create_tween()
    fade_in.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    fade_in.tween_property(cover, "modulate:a", 0.0, FADE_IN_SECONDS)
    await fade_in.finished
    cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
    transitioning = false
