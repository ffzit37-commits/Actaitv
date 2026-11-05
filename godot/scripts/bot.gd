extends CharacterBody3D

@export var max_health := 100
@export var move_speed := 2.1
@export var attack_range := 16.0
@export var attack_damage := 7

var health: int
var attack_timer := 0.0
var strafe_timer := 0.0
var strafe_sign := 1.0
var player: Node3D
var health_bar: MeshInstance3D

func _ready() -> void:
    health = max_health
    add_to_group("bots")
    _build_bot()
    player = get_tree().get_first_node_in_group("player")

func _build_bot() -> void:
    var armor := StandardMaterial3D.new()
    armor.albedo_color = Color(0.42, 0.12, 0.10)
    var bright := StandardMaterial3D.new()
    bright.albedo_color = Color(1.0, 0.48, 0.12)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.23
    sphere.height = 0.46
    head.mesh = sphere
    head.position.y = 1.58
    head.material_override = bright
    add_child(head)
    _box(Vector3(0, 0.95, 0), Vector3(0.72, 0.9, 0.42), armor)
    _box(Vector3(-0.2, 0.3, 0), Vector3(0.22, 0.6, 0.25), armor)
    _box(Vector3(0.2, 0.3, 0), Vector3(0.22, 0.6, 0.25), armor)
    var bar_bg := BoxMesh.new()
    bar_bg.size = Vector3(0.9, 0.08, 0.05)
    var bar := MeshInstance3D.new()
    bar.mesh = bar_bg
    bar.position = Vector3(0, 2.05, 0)
    add_child(bar)
    health_bar = MeshInstance3D.new()
    var fill := BoxMesh.new()
    fill.size = Vector3(0.86, 0.055, 0.06)
    health_bar.mesh = fill
    var green := StandardMaterial3D.new()
    green.albedo_color = Color(0.2, 0.95, 0.4)
    health_bar.material_override = green
    health_bar.position = Vector3(0, 2.06, -0.035)
    add_child(health_bar)

func _box(pos: Vector3, size: Vector3, material: Material) -> void:
    var n := MeshInstance3D.new()
    var m := BoxMesh.new()
    m.size = size
    n.mesh = m
    n.position = pos
    n.material_override = material
    add_child(n)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    strafe_timer -= delta
    if strafe_timer <= 0.0:
        strafe_timer = randf_range(1.2, 2.6)
        strafe_sign *= -1.0
    var offset := player.global_position - global_position
    var distance := offset.length()
    var direction := offset.normalized()
    look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
    var move_dir := Vector3.ZERO
    if distance > 8.0:
        move_dir = direction
    elif distance > 4.0:
        move_dir = direction * 0.35 + global_transform.basis.x * strafe_sign * 0.7
    else:
        move_dir = -direction * 0.45 + global_transform.basis.x * strafe_sign
    velocity.x = move_dir.normalized().x * move_speed
    velocity.z = move_dir.normalized().z * move_speed
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    move_and_slide()
    if distance <= attack_range and attack_timer <= 0.0:
        attack_timer = 1.4
        if player.has_method("take_damage"):
            player.take_damage(attack_damage)

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    if is_instance_valid(health_bar):
        health_bar.scale.x = maxf(0.02, float(health) / float(max_health))
    if health <= 0:
        var hero = get_tree().get_first_node_in_group("player")
        if hero:
            hero.add_elimination()
        queue_free()
