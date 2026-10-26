extends Node2D
class_name FNFGirlfriend

# GF sempre acompanha weeks nativas; mods podem ocultar com hide_girlfriend.
# Utiliza os frames e os indices de gf.json; o XML ja esta na escala do PNG.
@export var display_scale: float = 1.96
var animations: Dictionary = {}
var current: String = "danceLeft"
var elapsed: float = 0.0
var sequence_time: float = 0.0
var dancing_left := false
var singing := false
var built := false

func _ready() -> void:
    var json_path := "res://assets/characters/girlfriend/gf.json"
    var atlas_basename := "GF_assets"
    var folder := "res://assets/characters/girlfriend/"
    if not Settings.selected_girlfriend_character.is_empty():
        var path := Settings.selected_girlfriend_character
        if FileAccess.file_exists(path):
            json_path = path
            var config_temp: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
            if config_temp is Dictionary:
                var atlas_rel := str(config_temp.get("atlas", ""))
                var pair_path := ModManager.resolve_mod_asset(Settings.selected_mod_id, atlas_rel)
                if not pair_path.is_empty():
                    atlas_basename = pair_path.get_file()
                    folder = pair_path.get_base_dir() + "/"
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
    if not (parsed is Dictionary):
        push_error("GF JSON invalido: " + json_path)
        return
    var config: Dictionary = parsed
    var atlas := SparrowAtlas.new()
    if not atlas.open_pair(atlas_basename, folder):
        return
    for entry_variant in config.get("animations", []):
        if not (entry_variant is Dictionary):
            continue
        var entry: Dictionary = entry_variant
        var name: String = str(entry.get("anim", ""))
        var prefix: String = str(entry.get("name", ""))
        if name == "scared" and prefix == "GF FEAR":
            prefix = "GF FEAR "
        var frames: Array[Dictionary] = atlas.animation_exact(prefix)
        if frames.is_empty():
            continue
        var indices: Array = entry.get("indices", [])
        var chosen: Array[Dictionary] = []
        if indices.is_empty():
            chosen = frames
        else:
            for idx_value in indices:
                var index := int(idx_value)
                if index >= 0 and index < frames.size():
                    chosen.append(frames[index])
        if chosen.is_empty():
            continue
        var offsets: Array = entry.get("offsets", [0, 0])
        var offset := Vector2.ZERO
        if offsets.size() >= 2:
            offset = Vector2(float(offsets[0]), float(offsets[1])) * 0.256
        animations[name] = {
            "frames": chosen,
            "offset": offset,
            "fps": maxf(1.0, float(entry.get("fps", 24.0))),
            "loop": bool(entry.get("loop", false))
        }
    built = animations.has("danceLeft") and animations.has("danceRight")
    queue_redraw()

func dance() -> void:
    if not built or singing:
        return
    dancing_left = not dancing_left
    current = "danceLeft" if dancing_left else "danceRight"
    elapsed = 0.0
    queue_redraw()

func sing(lane: int) -> void:
    if not built:
        return
    var names := ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
    if lane < 0 or lane >= 4 or not animations.has(names[lane]):
        return
    current = names[lane]
    singing = true
    sequence_time = 0.0
    elapsed = 0.0
    queue_redraw()

func reset_dance() -> void:
    singing = false
    elapsed = 0.0
    current = "danceLeft"
    dancing_left = true
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if singing:
        sequence_time += delta
        if sequence_time > 0.32:
            singing = false
            dance()
    queue_redraw()

func _draw() -> void:
    if not built:
        return
    var entry: Dictionary = animations.get(current, animations["danceLeft"])
    var frames: Array = entry["frames"]
    if frames.is_empty():
        return
    var step := int(elapsed * float(entry["fps"]))
    if bool(entry["loop"]):
        step %= frames.size()
    else:
        step = mini(step, frames.size() - 1)
    var frame: Dictionary = frames[step]
    var original: Vector2 = frame["frame_size"]
    var offset: Vector2 = frame["frame_offset"]
    var config_offset: Vector2 = entry["offset"]
    var source: Rect2 = frame["src"]
    var top_left: Vector2 = (Vector2(-original.x * 0.5, -original.y) - offset - config_offset) * display_scale
    draw_texture_rect_region(frame["texture"], Rect2(top_left, source.size * display_scale), source, Color.WHITE)
