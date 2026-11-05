extends CanvasLayer

var stats: Label
var player: Node
var controls: Control
var fire_button: Button

func _ready() -> void:
    add_to_group("hud")
    _build_ui()
    player = get_tree().get_first_node_in_group("player")

func _build_ui() -> void:
    controls = Control.new()
    controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    controls.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(controls)

    var top := Panel.new()
    top.position = Vector2(16, 14)
    top.size = Vector2(360, 74)
    top.modulate = Color(0.05, 0.08, 0.12, 0.82)
    controls.add_child(top)
    stats = Label.new()
    stats.position = Vector2(12, 8)
    stats.size = Vector2(340, 58)
    stats.add_theme_font_size_override("font_size", 19)
    stats.add_theme_color_override("font_color", Color(0.92, 0.97, 1))
    top.add_child(stats)

    var title := Label.new()
    title.text = "MOH AL-FASHIL  /  ساحة التدريب"
    title.position = Vector2(18, 96)
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
    controls.add_child(title)

    _make_button("▲", Vector2(110, -166), Vector2(66, 58), "move_forward")
    _make_button("▼", Vector2(110, -42), Vector2(66, 58), "move_back")
    _make_button("◀", Vector2(42, -104), Vector2(62, 58), "move_left")
    _make_button("▶", Vector2(182, -104), Vector2(62, 58), "move_right")
    _make_action_button("قفز", Vector2(-188, -194), Vector2(92, 62), Callable(self, "_jump"))
    _make_action_button("إعادة", Vector2(-188, -120), Vector2(92, 54), Callable(self, "_reload"))
    fire_button = _make_action_button("إطلاق", Vector2(-200, -80), Vector2(110, 76), Callable())
    fire_button.button_down.connect(_fire_start)
    fire_button.button_up.connect(_fire_stop)
    _make_action_button("علاج", Vector2(-188, -14), Vector2(92, 52), Callable(self, "_heal"))

    var help := Label.new()
    help.text = "حرّك الكاميرا بالسحب في يمين الشاشة"
    help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    help.position = Vector2(0, -30)
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
    controls.add_child(help)

func _make_button(caption: String, offset: Vector2, size: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = caption
    b.size = size
    b.position = Vector2(24, get_viewport().get_visible_rect().size.y - 220) + offset
    b.modulate = Color(0.72, 0.88, 1.0, 0.8)
    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    controls.add_child(b)

func _make_action_button(caption: String, offset: Vector2, size: Vector2, callback: Callable) -> Button:
    var b := Button.new()
    b.text = caption
    b.size = size
    b.position = Vector2(get_viewport().get_visible_rect().size.x - 20, get_viewport().get_visible_rect().size.y - 20) + offset
    b.add_theme_font_size_override("font_size", 20)
    b.modulate = Color(1.0, 0.82, 0.68, 0.9)
    b.pressed.connect(callback)
    controls.add_child(b)
    return b

func _jump() -> void:
    if is_instance_valid(player):
        player.jump()

func _reload() -> void:
    if is_instance_valid(player):
        player.reload_weapon()

func _fire_start() -> void:
    if is_instance_valid(player):
        player.set_firing(true)

func _fire_stop() -> void:
    if is_instance_valid(player):
        player.set_firing(false)

func _heal() -> void:
    if is_instance_valid(player) and player.health < 100:
        player.health = mini(100, player.health + 25)
        player.update_hud()

func update_stats(health: int, ammo: int, reserve: int, eliminations: int, reloading: bool) -> void:
    if is_instance_valid(stats):
        var reload_text := "  |  جارٍ التلقيم..." if reloading else ""
        stats.text = "الصحة %d   |   الذخيرة %d/%d   |   الإقصاءات %d%s" % [health, ammo, reserve, eliminations, reload_text]
