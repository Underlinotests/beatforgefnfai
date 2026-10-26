extends TextureRect
class_name FNFCheckboxSprite

var atlas: SparrowAtlas
var checked := false
var clips: Dictionary = {}
var current_animation := "unchecked"
var animation_progress := 0.0
var playing := false
var available := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(62, 51)
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    atlas = SparrowAtlas.new()
    available = atlas.open_pair("checkboxanim", "res://assets/menus/")
    if not available:
        return
    clips["unchecked"] = atlas.animation_exact("checkbox")
    clips["checked"] = atlas.animation_exact("checkbox finish")
    clips["check"] = atlas.animation_exact("checkbox anim")
    clips["uncheck"] = atlas.animation_exact("checkbox anim reverse")
    _render_frame()

func set_checked_state(value: bool, animate: bool = false) -> void:
    if checked == value and not playing:
        return
    checked = value
    current_animation = ("check" if checked else "uncheck") if animate else ("checked" if checked else "unchecked")
    animation_progress = 0.0
    playing = animate
    _render_frame()

func _process(delta: float) -> void:
    if not playing:
        return
    animation_progress += delta
    var frames: Array = clips.get(current_animation, [])
    if animation_progress * 18.0 >= float(frames.size()):
        playing = false
        current_animation = "checked" if checked else "unchecked"
    _render_frame()

func _render_frame() -> void:
    var frames: Array = clips.get(current_animation, [])
    if frames.is_empty():
        return
    var frame: Dictionary = frames[mini(int(animation_progress * 18.0), frames.size() - 1)]
    var texture_ref := AtlasTexture.new()
    texture_ref.atlas = frame["texture"]
    texture_ref.region = frame["src"]
    texture = texture_ref
