extends RefCounted
class_name FNFMenuUI

const INK := Color("#1e1728")
const PINK := Color("#e86ebd")
const AQUA := Color("#75e7f3")
const MUTED := Color("#b9afcb")

static func make_layout(root: Control, header: String, description: String) -> VBoxContainer:
    var background := TextureRect.new()
    background.texture = load("res://assets/menus/menuBG.png")
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_SCALE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(background)
    var veil := ColorRect.new()
    veil.color = Color(0.15, 0.10, 0.19, 0.80)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(veil)

    var accent := ColorRect.new()
    accent.color = Color("#5b315e")
    accent.anchor_right = 1.0
    accent.offset_bottom = 9.0
    accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(accent)

    var centered := CenterContainer.new()
    centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(centered)
    var panel := PanelContainer.new()
    var box_style := StyleBoxFlat.new()
    box_style.bg_color = Color("#31273c")
    box_style.border_color = Color("#80527d")
    box_style.set_border_width_all(2)
    box_style.set_corner_radius_all(16)
    box_style.content_margin_left = 35
    box_style.content_margin_right = 35
    box_style.content_margin_top = 24
    box_style.content_margin_bottom = 25
    panel.add_theme_stylebox_override("panel", box_style)
    centered.add_child(panel)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(540, 0)
    column.add_theme_constant_override("separation", 13)
    panel.add_child(column)

    var title := Label.new()
    title.text = header
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", PINK)
    title.add_theme_font_size_override("font_size", 35)
    column.add_child(title)
    if not description.is_empty():
        var caption := Label.new()
        caption.text = description
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.add_theme_color_override("font_color", MUTED)
        caption.add_theme_font_size_override("font_size", 15)
        column.add_child(caption)
    var separator := HSeparator.new()
    column.add_child(separator)
    return column

static func menu_button(label_text: String) -> Button:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(180, 48)
    button.add_theme_font_size_override("font_size", 21)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", AQUA)
    button.add_theme_color_override("font_pressed_color", AQUA)
    return button

static func info(label_text: String) -> Label:
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", MUTED)
    return label
