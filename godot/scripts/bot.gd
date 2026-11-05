extends CharacterBody3D

@export var max_health: int = 100
@export var move_speed: float = 2.4
@export var attack_range: float = 13.0
@export var attack_damage: int = 8

var health: int
var attack_timer := 0.0
var player: Node3D

func _ready() -> void:
    health = max_health
    add_to_group("bots")
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    var offset := player.global_position - global_position
    var distance := offset.length()
    if distance > 2.6:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
    if distance <= attack_range and attack_timer <= 0.0:
        attack_timer = 1.2
        if player.has_method("take_damage"):
            player.take_damage(attack_damage)
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        var hero = get_tree().get_first_node_in_group("player")
        if hero:
            hero.add_elimination()
        queue_free()
