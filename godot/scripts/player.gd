extends CharacterBody3D

@export var move_speed: float = 7.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0025
@export var fire_rate: float = 0.18
@export var weapon_damage: int = 34

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var ammo := 24
var health := 100
var eliminations := 0
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-55), deg_to_rad(35))
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        if event.button_index == MOUSE_BUTTON_LEFT:
            shoot()

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (global_transform.basis.x * input_dir.x - global_transform.basis.z * input_dir.y).normalized()
    if direction.length() > 0.01:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
    move_and_slide()

func shoot() -> void:
    if fire_cooldown > 0.0 or ammo <= 0:
        return
    fire_cooldown = fire_rate
    ammo -= 1
    var from := camera.global_position
    var to := from + -camera.global_transform.basis.z * 120.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target = hit.get("collider")
        if target and target.is_in_group("bots"):
            target.take_damage(weapon_damage)
    update_hud()

func update_hud() -> void:
    var hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.update_stats(health, ammo, eliminations)

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    update_hud()
    if health == 0:
        get_tree().call_deferred("reload_current_scene")

func add_elimination() -> void:
    eliminations += 1
    update_hud()
