extends Node3D

const BOT_SCENE := preload("res://scenes/bot.tscn")
const BOT_POSITIONS := [
    Vector3(-12, 0, -10), Vector3(10, 0, -14), Vector3(17, 0, 7),
    Vector3(-18, 0, 12), Vector3(3, 0, -23), Vector3(-5, 0, 20)
]

func _ready() -> void:
    _build_cover()
    _spawn_bots()
    _create_hud()

func _build_cover() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.31, 0.36, 0.39)
    for i in range(12):
        var block := StaticBody3D.new()
        block.name = "Cover_%02d" % i
        var mesh := MeshInstance3D.new()
        var shape := CollisionShape3D.new()
        var box := BoxMesh.new()
        var collision := BoxShape3D.new()
        var size := Vector3(randf_range(2.0, 4.0), randf_range(1.5, 3.0), randf_range(2.0, 4.0))
        box.size = size
        box.material = material
        collision.size = size
        mesh.mesh = box
        mesh.position.y = size.y * 0.5
        shape.shape = collision
        shape.position.y = size.y * 0.5
        block.position = Vector3(randf_range(-27, 27), 0, randf_range(-27, 27))
        block.add_child(mesh)
        block.add_child(shape)
        add_child(block)

func _spawn_bots() -> void:
    for point in BOT_POSITIONS:
        var bot = BOT_SCENE.instantiate()
        bot.position = point
        add_child(bot)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.add_to_group("hud")
    var label := Label.new()
    label.name = "Stats"
    label.position = Vector2(22, 18)
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(label)
    var hint := Label.new()
    hint.text = "WASD: حركة  |  Space: قفز  |  زر الفأرة الأيسر: إطلاق"
    hint.position = Vector2(22, 52)
    hint.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(hint)
    add_child(layer)
    layer.set_script(HUDScript)
    layer.update_stats(100, 24, 0)

const HUDScript = preload("res://scripts/hud.gd")
