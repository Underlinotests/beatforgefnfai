extends RefCounted
class_name VCRBitmapText

# Rasterizacao do VCR enviado pelo usuario, empacotada como textura PNG.
# Mantem o visual da fonte sem exigir o arquivo TTF dentro do projeto.
var atlas: Texture2D
var glyphs: Dictionary = {}
var source_size: float = 52.0

func _init() -> void:
    atlas = load("res://assets/fonts/vcr_glyphs.png") as Texture2D
    var path := "res://assets/fonts/vcr_glyphs.json"
    if FileAccess.file_exists(path):
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if parsed is Dictionary:
            glyphs = parsed.get("glyphs", {})
            source_size = float(parsed.get("source_size", 52.0))

func draw_text(target: CanvasItem, text: String, baseline: Vector2, size: float, color: Color = Color.WHITE) -> void:
    if atlas == null or glyphs.is_empty():
        return
    var factor: float = size / source_size
    var cursor: Vector2 = baseline
    for ch in text:
        if ch == "\n":
            cursor.x = baseline.x
            cursor.y += size * 1.15
            continue
        var info: Dictionary = glyphs.get(ch, glyphs.get("?", {}))
        if info.is_empty():
            cursor.x += size * 0.3
            continue
        var w: float = float(info["w"])
        var h: float = float(info["h"])
        var dest := Rect2(cursor.x + float(info["bx"]) * factor, cursor.y + float(info["by"]) * factor, w * factor, h * factor)
        var region := Rect2(float(info["x"]), float(info["y"]), w, h)
        target.draw_texture_rect_region(atlas, dest, region, color)
        cursor.x += float(info["advance"]) * factor
