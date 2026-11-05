extends CanvasLayer

@onready var stats: Label = $Stats

func update_stats(health: int, ammo: int, eliminations: int) -> void:
    stats.text = "موح الفاشل   |   الصحة: %d   |   الذخيرة: %d   |   إقصاءات: %d" % [health, ammo, eliminations]
