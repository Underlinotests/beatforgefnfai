extends RefCounted
class_name FNFHealthSystem

const MAX_HEALTH: float = 2.0
const INITIAL_HEALTH: float = 1.0
const HIT_GAIN: float = 0.035
const MISS_PENALTY: float = 0.17
const HOLD_BREAK_PENALTY: float = 0.17

var health: float = INITIAL_HEALTH

func reset() -> void:
    health = INITIAL_HEALTH

func on_hit() -> void:
    health = clampf(health + HIT_GAIN, 0.0, MAX_HEALTH)

func on_miss() -> void:
    health = clampf(health - MISS_PENALTY, 0.0, MAX_HEALTH)

func on_hold_break() -> void:
    health = clampf(health - HOLD_BREAK_PENALTY, 0.0, MAX_HEALTH)

func depleted() -> bool:
    return health <= 0.00001
