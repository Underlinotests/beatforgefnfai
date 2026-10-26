extends RefCounted
class_name ScoreSystem

var score := 0
var hits := 0
var misses := 0
var combo := 0
var rating := "READY"

func hit(error_seconds: float) -> void:
    var error_ms := absf(error_seconds) * 1000.0
    if error_ms <= 45.0:
        rating = "SICK!"
        score += 350
    elif error_ms <= 90.0:
        rating = "GOOD"
        score += 200
    elif error_ms <= 135.0:
        rating = "BAD"
        score += 100
    else:
        rating = "SHIT"
        score += 50
    hits += 1
    combo += 1

func miss() -> void:
    rating = "MISS"
    misses += 1
    combo = 0

func accuracy() -> float:
    var count := hits + misses
    return 100.0 if count == 0 else float(hits) / float(count) * 100.0
