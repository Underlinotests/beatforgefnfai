extends RefCounted
class_name SparrowAtlas

# Le os SubTexture de XML Sparrow/Starling e mantem recorte + trimming originais.
var texture: Texture2D
var frames: Dictionary = {}
var names: Array[String] = []

func open_pair(basename: String, folder: String = "res://assets/images/original/") -> bool:
    var image_path := folder + basename + ".png"
    var xml_path := folder + basename + ".xml"
    if not FileAccess.file_exists(xml_path) or not FileAccess.file_exists(image_path):
        push_error("Atlas nao encontrado: " + image_path + " / " + xml_path)
        return false
    texture = ModManager.texture_from_file(image_path)
    if texture == null:
        push_error("Nao foi possivel carregar PNG " + image_path)
        return false
    var reader := XMLParser.new()
    if reader.open(xml_path) != OK:
        push_error("XML invalido: " + xml_path)
        return false
    names.clear()
    frames.clear()
    while reader.read() == OK:
        if reader.get_node_type() != XMLParser.NODE_ELEMENT or reader.get_node_name() != "SubTexture":
            continue
        var attributes: Dictionary = {}
        for i in range(reader.get_attribute_count()):
            attributes[reader.get_attribute_name(i)] = reader.get_attribute_value(i)
        var frame_name := str(attributes.get("name", ""))
        var width := float(attributes.get("width", "0"))
        var height := float(attributes.get("height", "0"))
        if frame_name.is_empty() or width <= 0.0 or height <= 0.0:
            continue
        frames[frame_name] = {
            "texture": texture,
            "src": Rect2(float(attributes.get("x", "0")), float(attributes.get("y", "0")), width, height),
            "frame_size": Vector2(float(attributes.get("frameWidth", width)), float(attributes.get("frameHeight", height))),
            "frame_offset": Vector2(float(attributes.get("frameX", "0")), float(attributes.get("frameY", "0")))
        }
        names.append(frame_name)
    names.sort()
    return not names.is_empty()

func animation(prefix: String) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for name in names:
        if name.begins_with(prefix):
            found.append(frames[name])
    if found.is_empty():
        push_warning("Animacao nao encontrada no XML: " + prefix)
    return found

# Correspondencia exata: evita incluir frames "MISS" em "BF NOTE LEFT".
func animation_exact(prefix: String) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for name in names:
        if not name.begins_with(prefix):
            continue
        var suffix: String = name.substr(prefix.length())
        if suffix.is_valid_int():
            found.append(frames[name])
    if found.is_empty():
        push_warning("Animacao exata nao encontrada no XML: " + prefix)
    return found
