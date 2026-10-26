extends Node2D
class_name FNFCharacter

# Recebe animacoes do JSON Psych Engine e as imagens de frames preprocessadas
# sem bleeding/jitter de coordenadas fracionarias do atlas original reduzido.
# IMPORTANT: a ancora visual e FIXA em TODAS as animacoes (idle como referencia).
# O JSON define deslocamentos por animacao. O trim Sparrow foi resolvido offline.
@export_enum("bf", "dad") var actor_id: String = "bf"
@export var sprite_scale: float = 1.0

const DIRECTIONS := ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
const ORIG_SCALE := {"bf": 0.25, "dad": 0.519}

var animations: Dictionary = {}
var active_animation := "idle"
var elapsed := 0.0
var sing_time_left := 0.0
var is_singing := false
var ready_to_draw := false
var flip_horizontal := false
var character_scale := 1.0
var base_idle_size := Vector2.ZERO
var animation_fps := 24.0

func _ready() -> void:
    var config_path: String = "res://assets/characters/json/%s.json" % actor_id
    var override_path: String = Settings.selected_player_character if actor_id == "bf" else Settings.selected_opponent_character
    var modded: bool = not override_path.is_empty() and FileAccess.file_exists(override_path)
    if modded:
        config_path = override_path
    if not FileAccess.file_exists(config_path):
        push_error("JSON ausente: " + config_path)
        return
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(config_path))
    if not (value is Dictionary):
        push_error("JSON invalido: " + config_path)
        return
    var config: Dictionary = value
    character_scale = float(config.get("scale", 1.0))
    # BF deste PNG ja olha para a esquerda; inverter novamente o colocaria
    # de costas para Dad, embora o JSON Psych use flip_x=true no atlas de origem.
    flip_horizontal = bool(config.get("flip_x", false)) if modded else (bool(config.get("flip_x", false)) and actor_id != "bf")
    var atlas := SparrowAtlas.new()
    if modded:
        var atlas_relative: String = str(config.get("atlas", ""))
        var atlas_base: String = ModManager.resolve_mod_asset(Settings.selected_mod_id, atlas_relative)
        if atlas_base.is_empty() or not atlas.open_pair(atlas_base.get_file(), atlas_base.get_base_dir() + "/"):
            push_error("Atlas externo invalido: " + atlas_relative)
            return
    else:
        var name: String = "BOYFRIEND" if actor_id == "bf" else "DADDY_DEAREST"
        if not atlas.open_pair(name + "_clean", "res://assets/characters/compiled/"):
            return
    animations.clear()
    for a in config.get("animations", []):
        if not (a is Dictionary):
            continue
        var key: String = str(a.get("anim", ""))
        var prefix: String = str(a.get("name", ""))
        if key.is_empty() or prefix.is_empty():
            continue
        # O chart de animacoes do BF chama esta pose "BF HEY", mas o
        # spritesheet compilado a identifica como "BF HEY!!".
        # Resolver o alias antes da busca evita o aviso e usa os frames certos.
        if key == "hey" and prefix == "BF HEY":
            prefix = "BF HEY!!"
        var frames: Array[Dictionary] = atlas.animation_exact(prefix)
        if frames.is_empty():
            push_warning("Animacao ausente: " + actor_id + "/" + key)
            continue
        var selected: Array[Dictionary] = []
        var indices: Array = a.get("indices", [])
        if indices.is_empty():
            selected = frames
        else:
            for value_index in indices:
                var index: int = int(value_index)
                if index >= 0 and index < frames.size():
                    selected.append(frames[index])
        if selected.is_empty():
            push_warning("Indices invalidos: " + actor_id + "/" + key)
            continue
        var offset_raw: Array = a.get("offsets", [0, 0])
        var offset := Vector2.ZERO
        if offset_raw.size() >= 2:
            var offset_scale: float = float(config.get("offset_scale", 1.0)) if modded else float(ORIG_SCALE[actor_id])
            offset = Vector2(float(offset_raw[0]), float(offset_raw[1])) * offset_scale
        animations[key] = {
            "frames": selected,
            "offset": offset,
            "loop": bool(a.get("loop", false)),
            "fps": maxf(1.0, float(a.get("fps", 24)))
        }
    ready_to_draw = animations.has("idle")
    if not ready_to_draw:
        push_error("Animacao idle nao encontrada para " + actor_id)
        return
    var idle_frames: Array = animations["idle"]["frames"]
    base_idle_size = idle_frames[0]["frame_size"]
    reset_idle()

func sing(lane: int, hold_duration: float = 0.0) -> void:
    if not ready_to_draw or lane < 0 or lane >= DIRECTIONS.size():
        return
    _play_animation(DIRECTIONS[lane])
    sing_time_left = maxf(0.28, hold_duration + 0.08)
    is_singing = true

func miss(lane: int) -> void:
    if actor_id != "bf" or lane < 0 or lane >= DIRECTIONS.size():
        return
    _play_animation(DIRECTIONS[lane] + "miss")
    sing_time_left = 0.32
    is_singing = true

func bop() -> void:
    if ready_to_draw and not is_singing:
        reset_idle()

func reset_idle() -> void:
    is_singing = false
    sing_time_left = 0.0
    _play_animation("idle")

func _play_animation(name: String) -> void:
    if not animations.has(name):
        return
    active_animation = name
    elapsed = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    if not ready_to_draw:
        return
    elapsed += delta
    if is_singing:
        sing_time_left -= delta
        if sing_time_left <= 0.0:
            reset_idle()
            return
    var info: Dictionary = animations.get(active_animation, {})
    var frames: Array = info.get("frames", [])
    if frames.is_empty():
        return
    if not bool(info.get("loop", false)):
        if elapsed * float(info.get("fps", 24.0)) >= float(frames.size()):
            var loop_name: String = active_animation + "-loop"
            if animations.has(loop_name):
                _play_animation(loop_name)
    queue_redraw()

func _draw() -> void:
    if not ready_to_draw:
        return
    var info: Dictionary = animations.get(active_animation, animations["idle"])
    var frames: Array = info.get("frames", [])
    if frames.is_empty():
        return
    var fps: float = float(info.get("fps", 24.0))
    var frame_index: int = int(floor(elapsed * fps))
    if bool(info.get("loop", false)):
        frame_index %= frames.size()
    else:
        frame_index = mini(frame_index, frames.size() - 1)
    var frame: Dictionary = frames[frame_index]
    var rect: Rect2 = frame["src"]
    var offset: Vector2 = info.get("offset", Vector2.ZERO)
    var total_scale: float = sprite_scale * character_scale

    # Ancora FIXA em todos os frames, nao usamos o tamanho variavel da pose.
    # Caso contrario, BF e Dad saltam quando muda idle -> sing ou de frame.
    var baseline: Vector2 = Vector2(-base_idle_size.x * 0.5, -base_idle_size.y)
    var frame_trim: Vector2 = frame.get("frame_offset", Vector2.ZERO)
    var draw_position: Vector2 = (baseline - offset - frame_trim) * total_scale
    if flip_horizontal:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
    draw_texture_rect_region(frame["texture"], Rect2(draw_position, rect.size * total_scale), rect, Color.WHITE)
    if flip_horizontal:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
