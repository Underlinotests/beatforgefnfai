extends Node

# One-shot SFX survive scene transitions because this script is an Autoload.
const SFX_DIR := "res://assets/sfx/"
const FILES := {
    "confirm": "confirmMenu.ogg",
    "cancel": "cancelMenu.ogg",
    "scroll": "scrollMenu.ogg",
    "intro1": "intro1.ogg",
    "intro2": "intro2.ogg",
    "intro3": "intro3.ogg",
    "introGo": "introGo.ogg",
    "miss1": "missnote1.ogg",
    "miss2": "missnote2.ogg",
    "miss3": "missnote3.ogg"
}
var streams: Dictionary = {}

func _ready() -> void:
    for key in FILES.keys():
        var path: String = SFX_DIR + str(FILES[key])
        if ResourceLoader.exists(path):
            streams[key] = load(path)

func play(sound_name: String, volume: float = 0.0) -> void:
    if not streams.has(sound_name):
        return
    var player := AudioStreamPlayer.new()
    player.stream = streams[sound_name]
    player.volume_db = volume
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_miss() -> void:
    play("miss%d" % randi_range(1, 3), -5.0)
