extends Node2D
## A small glowing key hidden somewhere in the house. Interact to pick it up.

signal picked_up(key)

const LightUtils := preload("res://scripts/core/light_utils.gd")

var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("key_item")
	_base_y = position.y
	var light := PointLight2D.new()
	light.texture = LightUtils.make_radial_texture(64, 1.4)
	light.texture_scale = 1.6
	light.energy = 0.9
	light.color = Color(1.0, 0.85, 0.45)
	add_child(light)


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 2.5
	queue_redraw()


# --- interactable interface -------------------------------------------------

func can_interact() -> bool:
	return true


func get_prompt() -> String:
	return "Take the key"


func interact(_player) -> void:
	picked_up.emit(self)
	queue_free()


func _draw() -> void:
	var pulse := 0.75 + 0.25 * sin(_t * 4.0)
	draw_rect(Rect2(-3, -8, 6, 16), Color(0.9, 0.75, 0.35, pulse))
	draw_rect(Rect2(-6, -8, 12, 4), Color(0.9, 0.75, 0.35, pulse))
