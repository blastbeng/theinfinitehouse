extends Node
## Procedural anomaly system: small, seeded disturbances that make the house
## feel untrustworthy. Data-driven definitions; the schedule is deterministic
## for a given run seed (target choice also depends on live player position).
##
## v1 anomalies (all environmental/spatial, low severity):
##   light_out        a distant room light dims out, then returns
##   door_slam        a distant open door slams shut
##   furniture_shift  a piece of furniture slides to another spot in its room
##
## Transitions are interpolated in _process (no tweens) so the whole system
## advances with synthetic deltas and stays testable headless.

signal anomaly_started(id: String)
signal anomaly_resolved(id: String)

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")
const TILE := HouseGenerator.TILE

## weight = relative probability, min_time = earliest it may fire (run seconds),
## cooldown = minimum gap between two uses of the same type.
const ANOMALIES: Dictionary = {
	"light_out": {"weight": 3, "min_time": 20.0, "cooldown": 18.0, "severity": 1},
	"door_slam": {"weight": 3, "min_time": 30.0, "cooldown": 15.0, "severity": 1},
	"furniture_shift": {"weight": 2, "min_time": 45.0, "cooldown": 25.0, "severity": 1},
}

const GRACE_MIN := 20.0
const GRACE_MAX := 35.0
const INTERVAL_MIN := 12.0
const INTERVAL_MAX := 25.0
const RETRY_AFTER_FAIL := 3.0
const PLAYER_CLEAR_PX := 80.0
const LIGHT_HOLD_MIN := 6.0
const LIGHT_HOLD_MAX := 14.0
const LIGHT_FADE := 0.7
const LIGHT_OUT_DIM := 0.12
const MOVE_DURATION := 0.5

var active := false
var elapsed := 0.0
var current_seed := 0

var _rng := RandomNumberGenerator.new()
var _layout: Dictionary = {}
var _house: Node2D
var _player: CharacterBody2D
var _reserved: Dictionary = {}
var _last_used: Dictionary = {}
# {light, flicker, base, phase: "dim"|"hold"|"restore", from, to, t, dur}
var _light_job: Dictionary = {}
# [{item, from, to, t, dur}]
var _moves: Array = []
var _next_at := 0.0


func start_run(seed: int, layout: Dictionary, house: Node2D, player: CharacterBody2D) -> void:
	active = true
	current_seed = seed
	elapsed = 0.0
	_rng.seed = seed * 31 + 7
	_layout = layout
	_house = house
	_player = player
	_reserved = _build_reserved(layout)
	_last_used.clear()
	_light_job = {}
	_moves.clear()
	_next_at = _rng.randf_range(GRACE_MIN, GRACE_MAX)


## Stops scheduling and snaps any in-flight transition to its end state so
## nothing freezes half-done behind the end overlay.
func stop_run() -> void:
	active = false
	if not _light_job.is_empty():
		var light = _light_job["light"]
		if is_instance_valid(light):
			light.energy = _light_job["base"]
		var flicker: Node = _light_job["flicker"]
		if flicker and is_instance_valid(flicker):
			flicker.set_process(true)
		_light_job = {}
	for m in _moves:
		if is_instance_valid(m["item"]):
			m["item"].position = m["to"]
	_moves.clear()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	_step_light_job(delta)
	for m in _moves.duplicate():
		m["t"] += delta
		var k := minf(float(m["t"]) / float(m["dur"]), 1.0)
		m["item"].position = m["from"].lerp(m["to"], k)
		if k >= 1.0:
			_moves.erase(m)
	if elapsed >= _next_at and _can_fire():
		var id := _pick_anomaly()
		if id == "":
			_next_at = elapsed + RETRY_AFTER_FAIL
		elif _run(id):
			_last_used[id] = elapsed
			_next_at = elapsed + _rng.randf_range(INTERVAL_MIN, INTERVAL_MAX)
		else:
			_next_at = elapsed + RETRY_AFTER_FAIL


# --- anomaly executors ------------------------------------------------------

## A new anomaly may fire when no light is currently out (dim/hold phases).
func _can_fire() -> bool:
	if _light_job.is_empty():
		return true
	return _light_job["phase"] == "restore"


func _pick_anomaly() -> String:
	var eligible: Array = []
	var total := 0
	for id in ANOMALIES:
		var def: Dictionary = ANOMALIES[id]
		if elapsed < float(def["min_time"]):
			continue
		if _last_used.has(id) and elapsed - float(_last_used[id]) < float(def["cooldown"]):
			continue
		eligible.append(id)
		total += int(def["weight"])
	if eligible.is_empty():
		return ""
	var roll := _rng.randi_range(0, total - 1)
	for id in eligible:
		roll -= int(ANOMALIES[id]["weight"])
		if roll < 0:
			return id
	return eligible[0]


func _run(id: String) -> bool:
	match id:
		"light_out":
			return _run_light_out()
		"door_slam":
			return _run_door_slam()
		"furniture_shift":
			return _run_furniture_shift()
	return false


func _run_light_out() -> bool:
	var candidates: Array = []
	for c in _house.get_children():
		if not (c is PointLight2D):
			continue
		if _player and c.position.distance_to(_player.global_position) < PLAYER_CLEAR_PX * 1.5:
			continue
		candidates.append(c)
	if candidates.is_empty():
		return false
	var light: PointLight2D = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var flicker: Node = null
	for c in light.get_children():
		if c.get_script() != null:
			flicker = c
			break
	if flicker:
		flicker.set_process(false)
	_light_job = {
		"light": light, "flicker": flicker, "base": light.energy,
		"phase": "dim", "from": light.energy, "to": LIGHT_OUT_DIM,
		"t": 0.0, "dur": LIGHT_FADE,
	}
	anomaly_started.emit("light_out")
	return true


func _step_light_job(delta: float) -> void:
	if _light_job.is_empty():
		return
	var light = _light_job["light"]
	if not is_instance_valid(light):
		_light_job = {}
		return
	_light_job["t"] += delta
	var k := minf(float(_light_job["t"]) / float(_light_job["dur"]), 1.0)
	match _light_job["phase"]:
		"dim":
			light.energy = lerpf(float(_light_job["from"]), float(_light_job["to"]), k)
			if k >= 1.0:
				_light_job["phase"] = "hold"
				_light_job["t"] = 0.0
				_light_job["dur"] = _rng.randf_range(LIGHT_HOLD_MIN, LIGHT_HOLD_MAX)
		"hold":
			if float(_light_job["t"]) >= float(_light_job["dur"]):
				_light_job["phase"] = "restore"
				_light_job["from"] = LIGHT_OUT_DIM
				_light_job["to"] = _light_job["base"]
				_light_job["t"] = 0.0
				_light_job["dur"] = LIGHT_FADE
		"restore":
			light.energy = lerpf(float(_light_job["from"]), float(_light_job["to"]), k)
			if k >= 1.0:
				var flicker: Node = _light_job["flicker"]
				if flicker and is_instance_valid(flicker):
					flicker.set_process(true)
				_light_job = {}
				anomaly_resolved.emit("light_out")


func _run_door_slam() -> bool:
	var candidates: Array = []
	for d in _house.get_children():
		if not d.has_method("toggle"):
			continue
		if d.is_exit or not d.is_open:
			continue
		if _player and d.global_position.distance_to(_player.global_position) < PLAYER_CLEAR_PX:
			continue
		candidates.append(d)
	if candidates.is_empty():
		return false
	var door: Node2D = candidates[_rng.randi_range(0, candidates.size() - 1)]
	door.toggle()
	anomaly_started.emit("door_slam")
	return true


func _run_furniture_shift() -> bool:
	var furn := _house.get_node_or_null("Furniture")
	if furn == null or furn.get_children().is_empty():
		return false
	var items: Array = furn.get_children()
	var item = items[_rng.randi_range(0, items.size() - 1)]
	var from_cell := _cell_of(item.position)
	var room := _room_containing(from_cell)
	if room == null:
		return false
	var rrect: Rect2i = room["rect"]
	var w: int = item.size_cells.x
	var h: int = item.size_cells.y

	# Live occupancy of every other item (previous shifts already moved them).
	var occupied := {}
	for o in furn.get_children():
		if o == item:
			continue
		var oc := _cell_of(o.position)
		for cy in o.size_cells.y:
			for cx in o.size_cells.x:
				occupied[Vector2i(oc.x + cx, oc.y + cy)] = true

	var options: Array = []
	for cy in range(rrect.position.y, rrect.end.y - h + 1):
		for cx in range(rrect.position.x, rrect.end.x - w + 1):
			var at := Vector2i(cx, cy)
			if at == from_cell or _manhattan(at, from_cell) < 2:
				continue
			if not _fits_at(at, w, h, occupied):
				continue
			var center := Vector2((cx + w / 2.0) * TILE, (cy + h / 2.0) * TILE)
			if _player and center.distance_to(_player.global_position) < PLAYER_CLEAR_PX:
				continue
			options.append(at)
	if options.is_empty():
		return false
	var to_cell: Vector2i = options[_rng.randi_range(0, options.size() - 1)]
	_moves.append({
		"item": item, "from": item.position,
		"to": Vector2(to_cell.x * TILE, to_cell.y * TILE),
		"t": 0.0, "dur": MOVE_DURATION,
	})
	anomaly_started.emit("furniture_shift")
	return true


# --- validation (used by the headless test) ---------------------------------

## Returns a list of problems with the current live state (empty = healthy).
func validate() -> Array:
	var problems: Array = []
	if _light_job.is_empty():
		for c in _house.get_children():
			if c is PointLight2D and (c as PointLight2D).energy < 0.05:
				problems.append("light stuck off")
	var furn := _house.get_node_or_null("Furniture")
	if furn != null:
		var occupied := {}
		for o in furn.get_children():
			var oc := _cell_of(o.position)
			for cy in o.size_cells.y:
				for cx in o.size_cells.x:
					var k := Vector2i(oc.x + cx, oc.y + cy)
					if occupied.has(k):
						problems.append("furniture overlap at %s" % str(k))
					occupied[k] = true
			var room := _room_containing(oc)
			if room == null:
				problems.append("furniture outside its room: %s" % str(oc))
			elif not (room["rect"] as Rect2i).has_point(Vector2i(oc.x + o.size_cells.x - 1, oc.y + o.size_cells.y - 1)):
				problems.append("furniture escapes room rect: %s" % str(oc))
			if not _fits_at(oc, o.size_cells.x, o.size_cells.y, {}):
				problems.append("furniture on invalid cells: %s" % str(oc))
	return problems


# --- helpers ------------------------------------------------------------------

func _build_reserved(layout: Dictionary) -> Dictionary:
	var reserved := {}
	var grid: Array = layout["grid"]
	var gw: int = layout["grid_w"]
	var gh: int = layout["grid_h"]
	# Corridor cells are floor cells outside every room rect.
	for y in gh:
		for x in gw:
			if grid[y][x] != HouseGenerator.FLOOR:
				continue
			if _room_containing(Vector2i(x, y)) != null:
				continue
			reserved[Vector2i(x, y)] = true
			for n in _neighbors(Vector2i(x, y)):
				reserved[n] = true
	for d in layout["doors"]:
		var dc: Vector2i = d["cell"]
		reserved[dc] = true
		for n in _neighbors(dc):
			reserved[n] = true
	reserved[layout["exit_cell"]] = true
	reserved[layout["key_cell"]] = true
	return reserved


func _fits_at(at: Vector2i, w: int, h: int, occupied: Dictionary) -> bool:
	var grid: Array = _layout["grid"]
	for cy in h:
		for cx in w:
			var c := Vector2i(at.x + cx, at.y + cy)
			if c.x < 0 or c.x >= _layout["grid_w"] or c.y < 0 or c.y >= _layout["grid_h"]:
				return false
			if grid[c.y][c.x] != HouseGenerator.FLOOR:
				return false
			if _reserved.has(c) or occupied.has(c):
				return false
	return true


func _room_containing(cell: Vector2i) -> Variant:
	for r in _layout["rooms"]:
		if (r["rect"] as Rect2i).has_point(cell):
			return r
	return null


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / TILE), int(p.y / TILE))


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _neighbors(c: Vector2i) -> Array:
	return [
		Vector2i(c.x + 1, c.y), Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1), Vector2i(c.x, c.y - 1),
	]
