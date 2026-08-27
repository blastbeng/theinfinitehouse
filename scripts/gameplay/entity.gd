extends Node2D
## Procedural supernatural entity: a shadow that watches from dark corners and
## drifts closer when the player is not near. It never attacks in v1 — its job
## is to make the house feel inhabited and untrustworthy ("it was just there").
##
## States:
##   DORMANT     invisible; waiting for the next appearance window
##   RELOCATING  fading out at one spot / fading in at another (closer) spot
##   OBSERVING   visible, stationary, watching the player
##   ESCAPING    the player got too close; quick fade + longer cooldown
##
## Escalation: every LEVEL_STEP seconds of run time raises `level` (max 3):
## longer observations, closer relocations, shorter cooldowns.
## All transitions are interpolated in _process (no tweens) so the whole thing
## advances with synthetic deltas and stays testable headless.

signal entity_state_changed(state: int)
signal entity_departed(pos: Vector2)

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")
const TILE := HouseGenerator.TILE

enum State { DORMANT, RELOCATING, OBSERVING, ESCAPING }

const FIRST_APPEAR_MIN := 45.0
const FIRST_APPEAR_MAX := 75.0
const SPAWN_MIN_DIST := 320.0   # first appearance: at least this far from the player
const FADE_IN := 0.6
const FADE_OUT := 0.5
const ESCAPE_FADE := 0.4
const VANISH_DIST := 110.0      # player closer than this -> ESCAPING
const COOLDOWN_MIN := 20.0
const COOLDOWN_MAX := 35.0
const COOLDOWN_FLOOR := 8.0
const RETRY_AFTER_FAIL := 3.0
const LEVEL_STEP := 60.0
const MAX_LEVEL := 3

var active := false
var elapsed := 0.0
var current_seed := 0
var state: int = State.DORMANT
var level := 0
var appearances := 0            # completed fade-ins (test/debug counter)

var _rng := RandomNumberGenerator.new()
var _layout: Dictionary = {}
var _house: Node2D
var _player: Node2D
var _fade := 0.0                # current visibility 0..1
var _phase := ""               # "in" | "out" (RELOCATING only)
var _t := 0.0
var _dur := 0.0
var _from_pos := Vector2.ZERO
var _to_pos := Vector2.ZERO
var _breath := 0.0


func start_run(seed: int, layout: Dictionary, house: Node2D, player: Node2D) -> void:
	active = true
	current_seed = seed
	elapsed = 0.0
	level = 0
	appearances = 0
	_rng.seed = seed * 17 + 3
	_layout = layout
	_house = house
	_player = player
	_fade = 0.0
	_t = 0.0
	_dur = _rng.randf_range(FIRST_APPEAR_MIN, FIRST_APPEAR_MAX)
	state = State.DORMANT
	position = Vector2.ZERO
	queue_redraw()


## Stops the entity and hides it so nothing lingers behind the end overlay.
func stop_run() -> void:
	active = false
	_fade = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	level = mini(int(elapsed / LEVEL_STEP), MAX_LEVEL)
	_breath += delta
	match state:
		State.DORMANT:
			_t += delta
			if _t >= _dur:
				_begin_appearance()
		State.RELOCATING:
			_t += delta
			var k := minf(_t / _dur, 1.0)
			if _phase == "out":
				_fade = 1.0 - k
				position = _from_pos
				if k >= 1.0:
					_phase = "in"
					_t = 0.0
					_dur = FADE_IN
					position = _to_pos
			else:
				_fade = k
				position = _to_pos
				if k >= 1.0:
					_enter_observing()
		State.OBSERVING:
			_t += delta
			if _player_too_close():
				_begin_escape()
			elif _t >= _dur:
				_begin_relocation()
		State.ESCAPING:
			_t += delta
			var k := minf(_t / ESCAPE_FADE, 1.0)
			_fade = 1.0 - k
			if k >= 1.0:
				_enter_dormant(_rng.randf_range(COOLDOWN_MIN, COOLDOWN_MAX) - level * 4.0)
	if _fade > 0.0:
		queue_redraw()


# --- state transitions -------------------------------------------------------

func _begin_appearance() -> void:
	var spot := _pick_spot(SPAWN_MIN_DIST, INF)
	if spot == Vector2.ZERO:
		_dur = RETRY_AFTER_FAIL
		return
	_to_pos = spot
	_phase = "in"
	_t = 0.0
	_dur = FADE_IN
	position = spot
	state = State.RELOCATING
	entity_state_changed.emit(state)


func _enter_observing() -> void:
	appearances += 1
	_fade = 1.0
	_t = 0.0
	# Base 4s, +2s per escalation level, +/- 2s jitter.
	_dur = 4.0 + level * 2.0 + _rng.randf_range(-2.0, 2.0)
	state = State.OBSERVING
	entity_state_changed.emit(state)


func _begin_relocation() -> void:
	var min_d := maxf(120.0, 280.0 - level * 45.0)
	var max_d := maxf(min_d + 60.0, 460.0 - level * 70.0)
	var spot := _pick_spot(min_d, max_d)
	if spot == Vector2.ZERO:
		# No floor cell in the band (small house / player in a corridor):
		# keep watching a bit longer and try again.
		_dur += 5.0
		return
	_from_pos = position
	_to_pos = spot
	_phase = "out"
	_t = 0.0
	_dur = FADE_OUT
	state = State.RELOCATING
	entity_state_changed.emit(state)


func _begin_escape() -> void:
	_t = 0.0
	state = State.ESCAPING
	entity_state_changed.emit(state)


func _enter_dormant(cooldown: float) -> void:
	var pos := position
	_fade = 0.0
	_t = 0.0
	_dur = maxf(COOLDOWN_FLOOR, cooldown)
	state = State.DORMANT
	entity_state_changed.emit(state)
	entity_departed.emit(pos)


# --- helpers ------------------------------------------------------------------

func _player_pos() -> Vector2:
	if _player != null and is_instance_valid(_player):
		return _player.global_position
	return _layout.get("spawn", Vector2.ZERO)


func _player_too_close() -> bool:
	return global_position.distance_to(_player_pos()) < VANISH_DIST


## Picks a random floor cell whose center lies within [min_d, max_d] pixels of
## the player. If no cell qualifies (small house / fallback layout) the lower
## bound is relaxed step by step so a spot can still be found. Returns
## Vector2.ZERO only when even the relaxed band is empty.
func _pick_spot(min_d: float, max_d: float) -> Vector2:
	var ppos := _player_pos()
	var grid: Array = _layout["grid"]
	var lo := min_d
	while true:
		var options: Array = []
		for y in _layout["grid_h"]:
			for x in _layout["grid_w"]:
				if grid[y][x] != HouseGenerator.FLOOR:
					continue
				var c := Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)
				var d := c.distance_to(ppos)
				if d < lo or d > max_d:
					continue
				options.append(c)
		if not options.is_empty():
			return options[_rng.randi_range(0, options.size() - 1)]
		if lo <= 60.0:
			break
		lo = maxf(60.0, lo - 80.0)
	return Vector2.ZERO


func _draw() -> void:
	if _fade <= 0.01:
		return
	var s := 1.0 + 0.05 * sin(_breath * 2.0)
	var body := Color(0.02, 0.02, 0.04, 0.88 * _fade)
	draw_circle(Vector2(0, 4), 11.0 * s, body)
	draw_circle(Vector2(-6, -2), 7.5 * s, body)
	draw_circle(Vector2(6, -2), 7.5 * s, body)
	draw_circle(Vector2(0, -8), 8.5 * s, body)
	var dir := Vector2.ZERO
	if _player != null and is_instance_valid(_player):
		dir = (_player.global_position - global_position).normalized()
	var eye_c := Color(0.75, 0.78, 0.85, 0.9 * _fade)
	draw_circle(Vector2(-3.5, -6) + dir * 1.5, 1.4, eye_c)
	draw_circle(Vector2(3.5, -6) + dir * 1.5, 1.4, eye_c)
