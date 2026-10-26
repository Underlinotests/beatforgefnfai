extends RefCounted
class_name ChartLoader

# psych_v1_convert uses absolute columns; native Psych charts use mustHitSection.
static func load_psych(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Nao foi possivel ler o chart: " + path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        push_error("JSON invalido: " + path)
        return {}
    var song: Dictionary = parsed.get("song", parsed)
    var notes: Array[Dictionary] = []
    var absolute_lanes: bool = str(song.get("format", "")) == "psych_v1_convert"
    for section_variant in song.get("notes", []):
        if not (section_variant is Dictionary):
            continue
        var section: Dictionary = section_variant
        for entry_variant in section.get("sectionNotes", []):
            if not (entry_variant is Array):
                continue
            var entry: Array = entry_variant
            if entry.size() < 3:
                continue
            var id := int(entry[1])
            if id < 0 or id > 7:
                continue
            var is_player: bool = id < 4
            if not absolute_lanes:
                # Native Psych section layout: low lanes belong to the current singer,
                # 4-7 belong to the other singer. Keep converted charts unchanged.
                is_player = (id < 4) == bool(section.get("mustHitSection", false))
            notes.append({
                "time": maxf(0.0, float(entry[0]) / 1000.0),
                "lane": id % 4,
                "player": is_player,
                "sustain": maxf(0.0, float(entry[2]) / 1000.0),
                "head_hit": false,
                "holding": false,
                "complete": false,
                "missed": false
            })
    notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["time"]) < float(b["time"])
    )
    return {
        "title": str(song.get("song", "Unknown")),
        "bpm": float(song.get("bpm", 120.0)),
        "speed": float(song.get("speed", 1.0)),
        "notes": notes
    }
