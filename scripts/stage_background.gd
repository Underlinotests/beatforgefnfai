extends Node2D
class_name FNFStage

# Usa stage.json da Week 1 e os personagens JSON para converter o layout
# original (coordenadas Psych) ao viewport de teste 960x540.
@export var stage_units_scale: float = 0.75
@export var floor_y: float = 515.0
@export var stage_reference_x: float = 490.0
@export var screen_reference_x: float = 550.0

func _ready() -> void:
    var stage_config := _read_json("res://assets/stages/week1/stage.json")
    if not Settings.selected_stage_path.is_empty() and FileAccess.file_exists(Settings.selected_stage_path):
        stage_config = _read_json(Settings.selected_stage_path)
        _apply_mod_layers(stage_config)
    var bf_config := _read_json("res://assets/characters/json/bf.json")
    var dad_config := _read_json("res://assets/characters/json/dad.json")
    if not Settings.selected_player_character.is_empty():
        bf_config = _read_json(Settings.selected_player_character)
    if not Settings.selected_opponent_character.is_empty():
        dad_config = _read_json(Settings.selected_opponent_character)
    # GF faz parte de todas as weeks originais; mods podem suprimi-la.
    var girlfriend: FNFGirlfriend = get_node("../Girlfriend") as FNFGirlfriend
    girlfriend.visible = not Settings.selected_hide_girlfriend
    var gf_position: Array = stage_config.get("girlfriend", [400, 130])
    if gf_position.size() >= 2:
        girlfriend.position = _to_stage_position(gf_position, [0, 0], Vector2.ZERO) + Vector2(65.0, -28.0)
    var opponent: Array = stage_config.get("opponent", [100, 100])
    var boyfriend: Array = stage_config.get("boyfriend", [770, 100])
    var opp_offset: Array = dad_config.get("position", [0, 0])
    var bf_offset: Array = bf_config.get("position", [0, 350])
    # Psych usa offsets das ancoragens distintos por personagem.
    # Centralizamos cada pivot nos pes para desenhar as poses sem tremor.
    var dad: Node2D = get_node("../Dad") as Node2D
    var bf: Node2D = get_node("../Boyfriend") as Node2D
    dad.position = _to_stage_position(opponent, opp_offset, Vector2(0, 0))
    bf.position = _to_stage_position(boyfriend, bf_offset, Vector2(0, 350) if Settings.selected_player_character.is_empty() else Vector2.ZERO)
    # Escalas visuais sao independentes do zoom. Cada stage pode ajustar
    # os personagens sem distorcer o tamanho do fundo ou de outros mods.
    var visual_scales: Dictionary = stage_config.get("beatforge_display_scales", {})
    if visual_scales.has("opponent"):
        (dad as FNFCharacter).sprite_scale = maxf(0.1, float(visual_scales["opponent"]))
    if visual_scales.has("boyfriend"):
        (bf as FNFCharacter).sprite_scale = maxf(0.1, float(visual_scales["boyfriend"]))
    if visual_scales.has("girlfriend"):
        girlfriend.display_scale = maxf(0.1, float(visual_scales["girlfriend"]))
    # Ajustes finos independentes em coordenadas de mundo.
    # Um mod pode definir suas proprias posicoes sem afetar outras weeks.
    var display_offsets: Dictionary = stage_config.get("beatforge_display_offsets", {})
    for role in ["opponent", "girlfriend", "boyfriend"]:
        var amount: Array = display_offsets.get(role, [0, 0])
        if amount.size() < 2:
            continue
        var actor: Node2D = dad if role == "opponent" else (girlfriend if role == "girlfriend" else bf)
        actor.position += Vector2(float(amount[0]), float(amount[1]))
    var camera: FNFCameraController = get_node("../BattleCamera") as FNFCameraController
    camera.configure_stage(stage_config, dad, bf)

func _to_stage_position(coords: Array, char_offset: Array, char_reference: Vector2) -> Vector2:
    var origin := Vector2(float(coords[0]), float(coords[1]))
    var displacement := Vector2(float(char_offset[0]), float(char_offset[1])) - char_reference
    return Vector2(
        screen_reference_x + (origin.x - stage_reference_x + displacement.x) * stage_units_scale,
        floor_y + (origin.y - 100.0 + displacement.y) * stage_units_scale
    )

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Configuracao nao encontrada: " + path)
        return {}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return value if value is Dictionary else {}

# Mod stage format: {"defaultZoom":0.9,"opponent":[100,100],
# "boyfriend":[770,100],"layers":[{"image":"stages/bg.png",
# "position":[550,305],"scale":[1,1],"z_index":-10}]}.
func _apply_mod_layers(stage_config: Dictionary) -> void:
    var layers: Array = stage_config.get("layers", [])
    if layers.is_empty():
        return
    for child in get_children():
        if child is Sprite2D:
            child.visible = false
    for item_variant in layers:
        if not (item_variant is Dictionary):
            continue
        var layer: Dictionary = item_variant
        var image_path: String = ModManager.resolve_mod_asset(Settings.selected_mod_id, str(layer.get("image", "")))
        var texture: Texture2D = ModManager.texture_from_file(image_path)
        if texture == null:
            continue
        var sprite := Sprite2D.new()
        sprite.texture = texture
        var coords: Array = layer.get("position", [550, 305])
        var scale_values: Array = layer.get("scale", [1.0, 1.0])
        if coords.size() >= 2:
            sprite.position = Vector2(float(coords[0]), float(coords[1]))
        if scale_values.size() >= 2:
            sprite.scale = Vector2(float(scale_values[0]), float(scale_values[1]))
        sprite.z_index = clampi(int(layer.get("z_index", -10)), -100, 100)
        add_child(sprite)
