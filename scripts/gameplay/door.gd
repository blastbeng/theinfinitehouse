extends Node2D
## A one-cell doorway. Normal doors toggle open/closed; the exit door stays
## locked until the run's objective is completed.

signal state_changed(door)
signal escape_requested(door)

const TILE := 32

var is_exit := false
var locked := false
var is_open := false

var _body: StaticBody2D
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("interactables")
	if is_exit:
		add_to_group("exit_door")
	_body = StaticBody2D.new()
	_shape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(TILE, TILE)
	_shape.shape = rect_shape
	_body.add_child(_shape)
	add_child(_body)
	_apply_state()


func _apply_state() -> void:
	_shape.disabled = is_open


func toggle() -> void:
	if locked:
		return
	is_open = not is_open
	_apply_state()
	queue_redraw()
	state_changed.emit(self)


# --- interactable interface -------------------------------------------------

func can_interact() -> bool:
	return true


func get_prompt() -> String:
	if is_exit:
		return "Locked" if locked else "Leave the house"
	return "Close the door" if is_open else "Open the door"


func interact(_player) -> void:
	if is_exit:
		if locked:
			return
		is_open = true
		_apply_state()
		queue_redraw()
		state_changed.emit(self)
		escape_requested.emit(self)
		return
	toggle()


func _draw() -> void:
	var r := Rect2(-Vector2(TILE, TILE) / 2.0, Vector2(TILE, TILE))
	if is_exit:
		draw_rect(r, Color(0.16, 0.11, 0.07))
		draw_rect(Rect2(4, -TILE / 2.0 + 4, 5, TILE - 8), Color(0.38, 0.32, 0.22))
		if locked:
			draw_rect(r.grow(-6), Color(0.05, 0.04, 0.03, 0.55))
	elif is_open:
		draw_rect(Rect2(-TILE / 2.0, -TILE / 2.0, TILE, 5), Color(0.20, 0.15, 0.10))
	else:
		draw_rect(r, Color(0.24, 0.17, 0.11))
		draw_rect(Rect2(-TILE / 2.0 + 3, -TILE / 2.0 + 3, TILE - 6, TILE - 6), Color(0.18, 0.13, 0.08))
