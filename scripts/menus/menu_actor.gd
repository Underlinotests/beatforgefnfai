extends Node2D
class_name FNFMenuActor

# Sparrow animation from the menu character JSONs supplied by the user.
@export_enum("bf", "dad", "gf") var actor_id: String = "bf"
@export var actor_scale := 1.0
var atlas: SparrowAtlas
var clips: Dictionary = {}
var active := "idle"
var elapsed := 0.0
var anim_fps := 24.0
var animation_loaded := false

func _ready() -> void:
    var atlas_name: String = {"bf": "Menu_BF", "dad": "Menu_Dad", "gf": "Menu_GF"}.get(actor_id, "Menu_BF")
    atlas = SparrowAtlas.new()
    animation_loaded = atlas.open_pair(atlas_name, "res://assets/menus/")
    if not animation_loaded:
        return
    var config: Dictionary = {}
    var json_path: String = "res://assets/menus/%s.json" % actor_id
    if FileAccess.file_exists(json_path):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
        if parsed is Dictionary:
            config = parsed
    var idle_prefix: String = str(config.get("idle_anim", "M GF Idle"))
    if actor_id == "gf":
        idle_prefix = "M GF Idle"
    var confirm_prefix: String = str(config.get("confirm_anim", idle_prefix))
    clips["idle"] = atlas.animation_exact(idle_prefix)
    clips["confirm"] = atlas.animation_exact(confirm_prefix)
    animation_loaded = not (clips["idle"] as Array).is_empty()
    if not animation_loaded:
        push_error("Menu character idle not found: " + actor_id)
    queue_redraw()

func trigger_confirm() -> void:
    active = "confirm" if not (clips.get("confirm", []) as Array).is_empty() else "idle"
    elapsed = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    if not animation_loaded:
        return
    elapsed += delta
    if active == "confirm" and elapsed > 0.75:
        active = "idle"
        elapsed = 0.0
    queue_redraw()

func _draw() -> void:
    if not animation_loaded:
        return
    var list: Array = clips.get(active, [])
    if list.is_empty():
        return
    var index: int = int(elapsed * anim_fps)
    index = index % list.size() if active == "idle" else mini(index, list.size()-1)
    var frame: Dictionary = list[index]
    var original: Vector2 = frame["frame_size"]
    var offset: Vector2 = frame["frame_offset"]
    var rect: Rect2 = frame["src"]
    # Fixed reference coordinates: center horizontally, feet aligned at the anchor.
    var at := Vector2(-original.x * 0.5 - offset.x, -original.y - offset.y) * actor_scale
    draw_texture_rect_region(frame["texture"], Rect2(at, rect.size * actor_scale), rect, Color.WHITE)
