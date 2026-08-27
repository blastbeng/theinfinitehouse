extends CharacterBody2D
## Top-down player: movement, flashlight, proximity interaction.

signal prompt_changed(text: String)

const LightUtils := preload("res://scripts/core/light_utils.gd")

const SPEED := 175.0
const INTERACT_RANGE := 48.0

var _facing := Vector2.DOWN
var _last_prompt := ""
var _interactables: Array = []


func _ready() -> void:
	var light: PointLight2D = get_node("Flashlight")
	light.texture = LightUtils.make_radial_texture(128, 1.5)
	_interactables = get_tree().get_nodes_in_group("interactables")


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		_facing = dir.normalized()
		queue_redraw()
	velocity = dir * SPEED
	move_and_slide()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		var target = _find_interactable()
		if target != null:
			target.interact(self)
	_update_prompt()


func _find_interactable():
	var best = null
	var best_d := INTERACT_RANGE
	for n in _interactables:
		if not is_instance_valid(n):
			continue
		if not n.can_interact():
			continue
		var d := global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _update_prompt() -> void:
	var t := ""
	var target = _find_interactable()
	if target != null:
		t = "[E]  " + target.get_prompt()
	if t != _last_prompt:
		_last_prompt = t
		prompt_changed.emit(t)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.55, 0.52, 0.47))
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, Color(0.18, 0.17, 0.15), 1.5)
	draw_line(_facing * 3.0, _facing * 12.0, Color(0.8, 0.77, 0.68), 2.5)
