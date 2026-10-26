extends Node2D
class_name FNFMainMenuSprite

# Frames Sparrow oficiais do botao: idle e selected.
@export_enum("story_mode", "freeplay", "mods", "options") var item_id: String = "story_mode"
@export var display_scale: float = 0.70
var selected: bool = false
var atlas: SparrowAtlas
var animations: Dictionary = {}
var elapsed: float = 0.0

func _ready() -> void:
    atlas = SparrowAtlas.new()
    if not atlas.open_pair("menu_" + item_id, "res://assets/menus/"):
        return
    animations["idle"] = atlas.animation_exact(item_id + " idle")
    animations["selected"] = atlas.animation_exact(item_id + " selected")
    queue_redraw()

func set_selected(value: bool) -> void:
    if selected == value:
        return
    selected = value
    elapsed = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func hit_test(global_point: Vector2) -> bool:
    var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1.0, 1.0))
    var frames: Array = animations.get("selected" if selected else "idle", [])
    if not frames.is_empty():
        var max_extent: Vector2 = Vector2.ZERO
        for f in frames:
            var logical: Vector2 = f["frame_size"]
            max_extent.x = maxf(max_extent.x, logical.x)
            max_extent.y = maxf(max_extent.y, logical.y)
        rect = Rect2(-max_extent * display_scale * 0.5, max_extent * display_scale)
    return rect.grow(15.0).has_point(to_local(global_point))

func _draw() -> void:
    var frames: Array = animations.get("selected" if selected else "idle", [])
    if frames.is_empty():
        return
    var fps := 12.0
    var index := int(elapsed * fps) % frames.size()
    var frame: Dictionary = frames[index]
    var src: Rect2 = frame["src"]
    var logical: Vector2 = frame["frame_size"]
    var offset: Vector2 = frame["frame_offset"]
    # Reconstroi o atlas original com trimming e frameX/frameY.
    var draw_position: Vector2 = (-logical * 0.5 - offset) * display_scale
    draw_texture_rect_region(frame["texture"], Rect2(draw_position, src.size * display_scale), src, Color.WHITE)
