extends Camera2D
class_name FNFCameraController

@export var focus_speed: float = 3.0
@export var zoom_speed: float = 4.0
@export var default_zoom: float = 1.40
@export var beat_zoom: float = 0.012
var auto_follow: bool = true
var focus_on_player: bool = false
var focus_lane: int = -1
var focus_timer: float = 0.0
var zoom_offset: float = 0.0
var pulse: float = 0.0
var dad_focus: Vector2 = Vector2(480, 300)
var bf_focus: Vector2 = Vector2(620, 300)
var neutral_focus: Vector2 = Vector2(550, 300)

func _ready() -> void:
    position = neutral_focus
    zoom = Vector2.ONE * default_zoom
    make_current()

func configure_stage(config: Dictionary, dad: Node2D, boyfriend: Node2D) -> void:
    default_zoom = clampf(float(config.get("defaultZoom", 0.9)) * 1.56, 0.8, 1.55)
    focus_speed = maxf(0.5, float(config.get("camera_speed", 1.0)) * 3.0)
    var offsets_dad: Array = config.get("camera_opponent", [0, 0])
    var offsets_bf: Array = config.get("camera_boyfriend", [0, 0])
    # Psych: foco no personagem que canta. A camera mira para o lado dele,
    # preservando a GF no centro quando o palco permite.
    # Basear nas posicoes reais tambem permite stages de mods personalizados.
    var midpoint: Vector2 = (dad.position + boyfriend.position) * 0.5
    neutral_focus = midpoint + Vector2(0.0, -180.0)
    dad_focus = dad.position + Vector2(105.0, -185.0) + Vector2(float(offsets_dad[0]), float(offsets_dad[1])) * 0.4
    bf_focus = boyfriend.position + Vector2(-105.0, -185.0) + Vector2(float(offsets_bf[0]), float(offsets_bf[1])) * 0.4
    reset_view()

func focus_character(player: bool, lane: int) -> void:
    if not auto_follow:
        return
    focus_on_player = player
    focus_lane = lane
    focus_timer = 0.95

func pulse_beat() -> void:
    pulse = beat_zoom

func toggle_follow() -> void:
    auto_follow = not auto_follow
    if not auto_follow:
        focus_lane = -1
        focus_timer = 0.0

func adjust_zoom(amount: float) -> void:
    zoom_offset = clampf(zoom_offset + amount, -0.20, 0.35)

func reset_view() -> void:
    auto_follow = true
    focus_timer = 0.0
    focus_lane = -1
    focus_on_player = false
    zoom_offset = 0.0
    pulse = 0.0
    position = neutral_focus
    zoom = Vector2.ONE * default_zoom

func _process(delta: float) -> void:
    var desired: Vector2 = neutral_focus
    if auto_follow and focus_timer > 0.0:
        focus_timer -= delta
        desired = bf_focus if focus_on_player else dad_focus
        if focus_lane == 0:
            desired.x -= 20.0
        elif focus_lane == 3:
            desired.x += 20.0
        elif focus_lane == 1:
            desired.y += 15.0
        elif focus_lane == 2:
            desired.y -= 15.0
    position = position.lerp(desired, 1.0 - exp(-focus_speed * delta))
    pulse = move_toward(pulse, 0.0, delta * 0.17)
    var target_zoom := Vector2.ONE * (default_zoom + zoom_offset + pulse)
    zoom = zoom.lerp(target_zoom, 1.0 - exp(-zoom_speed * delta))
