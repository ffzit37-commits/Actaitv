extends CharacterBody3D

@export var move_speed := 6.5
@export var jump_velocity := 5.2
@export var mouse_sensitivity := 0.0022
@export var fire_rate := 0.14
@export var weapon_damage := 34

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var ammo := 30
var reserve_ammo := 120
var health := 100
var eliminations := 0
var firing := false
var reloading := false
var reload_timer := 0.0
var look_touch := -1
var last_touch := Vector2.ZERO
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
    add_to_group("player")
    _build_hero()
    update_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _look(event.relative)
    elif event is InputEventScreenTouch:
        if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.38:
            look_touch = event.index
            last_touch = event.position
        elif not event.pressed and event.index == look_touch:
            look_touch = -1
    elif event is InputEventScreenDrag and event.index == look_touch:
        _look(event.position - last_touch)
        last_touch = event.position
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            shoot()
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _look(delta: Vector2) -> void:
    rotate_y(-delta.x * mouse_sensitivity)
    camera_pivot.rotate_x(-delta.y * mouse_sensitivity)
    camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-48), deg_to_rad(32))

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    if reloading:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var needed := 30 - ammo
            var loaded: int = mini(needed, reserve_ammo)
            ammo += loaded
            reserve_ammo -= loaded
            reloading = false
            update_hud()
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        jump()
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (global_transform.basis.x * input_dir.x - global_transform.basis.z * input_dir.y).normalized()
    if direction.length() > 0.01:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)
    move_and_slide()
    if firing:
        shoot()

func _build_hero() -> void:
    var suit := _mat(Color(0.07, 0.20, 0.28))
    var accent := _mat(Color(0.95, 0.35, 0.12))
    var skin := _mat(Color(0.72, 0.52, 0.37))
    _add_capsule($Body, 0.39, 0.92, suit)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.22
    sphere.height = 0.44
    head.mesh = sphere
    head.position = Vector3(0, 1.55, 0)
    head.material_override = skin
    add_child(head)
    _add_box(Vector3(0, 1.02, -0.38), Vector3(0.16, 0.14, 0.78), accent)
    _add_box(Vector3(-0.22, 0.35, 0), Vector3(0.2, 0.65, 0.24), suit)
    _add_box(Vector3(0.22, 0.35, 0), Vector3(0.2, 0.65, 0.24), suit)
    _add_box(Vector3(0, 1.18, 0.18), Vector3(0.54, 0.34, 0.24), accent)

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.78
    return m

func _add_capsule(node: MeshInstance3D, radius: float, height: float, material: Material) -> void:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    node.mesh = mesh
    node.material_override = material

func _add_box(pos: Vector3, size: Vector3, material: Material) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    add_child(node)

func shoot() -> void:
    if reloading or fire_cooldown > 0.0:
        return
    if ammo <= 0:
        reload_weapon()
        return
    fire_cooldown = fire_rate
    ammo -= 1
    var from := camera.global_position
    var to := from + -camera.global_transform.basis.z * 160.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target = hit.get("collider")
        if target and target.is_in_group("bots"):
            target.take_damage(weapon_damage)
    update_hud()

func reload_weapon() -> void:
    if reloading or ammo >= 30 or reserve_ammo <= 0:
        return
    reloading = true
    reload_timer = 1.35
    update_hud()

func jump() -> void:
    if is_on_floor():
        velocity.y = jump_velocity

func set_firing(value: bool) -> void:
    firing = value

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    update_hud()
    if health == 0:
        get_tree().call_deferred("reload_current_scene")

func add_elimination() -> void:
    eliminations += 1
    update_hud()

func update_hud() -> void:
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.update_stats(health, ammo, reserve_ammo, eliminations, reloading)
