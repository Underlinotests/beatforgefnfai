extends Node2D
class_name FNFAlphabetText

# Real alphabet.png + alphabet.xml, one original Sparrow glyph per letter.
# Does not depend on any OS font.
const FONT_DIR := "res://assets/menus/"
var text_value := ""
var glyph_scale := 0.93
var glyph_spacing := -5.0
var selected := false
var idle_time := 0.0
var glyphs: Dictionary = {}
var atlas: SparrowAtlas

func _ready() -> void:
    atlas = SparrowAtlas.new()
    if atlas.open_pair("alphabet", FONT_DIR):
        for code in "abcdefghijklmnopqrstuvwxyz0123456789!?-":
            var frame_key := code + " bold instance 10000"
            if atlas.frames.has(frame_key):
                glyphs[code] = atlas.frames[frame_key]
    queue_redraw()

func set_title(value: String) -> void:
    text_value = value
    queue_redraw()

func set_highlight(value: bool) -> void:
    selected = value
    queue_redraw()

func _process(delta: float) -> void:
    idle_time += delta
    if selected:
        queue_redraw()

func _draw() -> void:
    if glyphs.is_empty():
        draw_string(ThemeDB.fallback_font, Vector2(-180, 0), text_value, HORIZONTAL_ALIGNMENT_CENTER, 360, 54, Color.BLACK)
        return
    var glyph_widths: Array[float] = []
    var total_width := 0.0
    for letter in text_value.to_lower():
        var width := 27.0
        if glyphs.has(letter):
            width = float(glyphs[letter]["frame_size"].x) + glyph_spacing
        glyph_widths.append(width * glyph_scale)
        total_width += width * glyph_scale
    var cursor := -total_width * 0.5
    var bounce := sin(idle_time * 4.0) * 2.0 if selected else 0.0
    var ink := Color("#171019")
    var border := Color.WHITE if selected else Color(1, 1, 1, 0.55)
    for index in range(text_value.length()):
        var letter := text_value.to_lower().substr(index, 1)
        if glyphs.has(letter):
            var frame: Dictionary = glyphs[letter]
            var region: Rect2 = frame["src"]
            var logical: Vector2 = frame["frame_size"]
            var offset: Vector2 = frame["frame_offset"]
            var location := Vector2(cursor - offset.x * glyph_scale, -logical.y * glyph_scale * 0.5 - offset.y * glyph_scale + bounce)
            var dest := Rect2(location, region.size * glyph_scale)
            for outline in [Vector2(-3,-3), Vector2(3,-3), Vector2(-3,3), Vector2(3,3), Vector2(-4,0), Vector2(4,0), Vector2(0,-4), Vector2(0,4)]:
                draw_texture_rect_region(frame["texture"], Rect2(dest.position + outline, dest.size), region, border)
            draw_texture_rect_region(frame["texture"], dest, region, ink)
        cursor += glyph_widths[index]
