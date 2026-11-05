extends Node3D

const BOT_SCENE := preload("res://scenes/bot.tscn")
const HUD_SCRIPT := preload("res://scripts/hud.gd")
const BOT_COUNT := 10

func _ready() -> void:
    randomize()
    _build_environment()
    _build_arena()
    _spawn_bots()
    _create_hud()

func _material(color: Color, roughness := 0.85) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _build_environment() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.48, 0.57, 0.68)
    e.ambient_light_energy = 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _build_arena() -> void:
    _add_box(Vector3(0, -0.6, 0), Vector3(100, 1, 100), Color(0.20, 0.27, 0.23), true)
    var road := _material(Color(0.12, 0.15, 0.17))
    _add_box(Vector3(0, -0.04, 0), Vector3(13, 0.08, 100), Color(0.12, 0.15, 0.17), false)
    for z in range(-45, 50, 10):
        _add_box(Vector3(0, 0.012, z), Vector3(0.22, 0.025, 4), Color(0.88, 0.76, 0.43), false)
    for i in range(18):
        var x := randf_range(-42, 42)
        var z := randf_range(-42, 42)
        if absf(x) < 10.0:
            x += 15.0 if x >= 0.0 else -15.0
        var w := randf_range(5.0, 10.0)
        var d := randf_range(5.0, 10.0)
        var h := randf_range(3.0, 10.0)
        _building(Vector3(x, 0, z), Vector3(w, h, d), i)
    for i in range(28):
        var x := randf_range(-42, 42)
        var z := randf_range(-42, 42)
        if Vector2(x, z).length() < 10.0:
            x += 14.0
        _add_box(Vector3(x, 0.65, z), Vector3(randf_range(1.8, 4.0), 1.3, randf_range(1.8, 4.0)), Color(0.30, 0.36, 0.39), true)
    _add_box(Vector3(0, 0.7, -2), Vector3(5.5, 1.4, 2.5), Color(0.82, 0.28, 0.10), true)

func _building(pos: Vector3, size: Vector3, index: int) -> void:
    var colors := [Color(0.29, 0.34, 0.39), Color(0.37, 0.31, 0.26), Color(0.22, 0.32, 0.35)]
    _add_box(pos + Vector3(0, size.y * 0.5, 0), size, colors[index % colors.size()], true)
    var stripe := Color(0.95, 0.38, 0.12) if index % 3 == 0 else Color(0.12, 0.65, 0.72)
    _add_box(pos + Vector3(0, size.y * 0.72, -size.z * 0.505), Vector3(size.x * 0.72, 0.16, 0.08), stripe, false)

func _add_box(pos: Vector3, size: Vector3, color: Color, solid: bool) -> void:
    var body: Node3D
    if solid:
        body = StaticBody3D.new()
    else:
        body = Node3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    box.material = _material(color)
    mesh.mesh = box
    body.add_child(mesh)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    add_child(body)

func _spawn_bots() -> void:
    for i in range(BOT_COUNT):
        var bot = BOT_SCENE.instantiate()
        var angle := TAU * float(i) / float(BOT_COUNT)
        bot.position = Vector3(cos(angle) * randf_range(17, 33), 0, sin(angle) * randf_range(17, 33))
        add_child(bot)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.set_script(HUD_SCRIPT)
    add_child(layer)
