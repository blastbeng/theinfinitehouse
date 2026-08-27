extends SceneTree
## Headless entity system test.
## Run: godot --headless -s res://tests/entity_test.gd [seed_count]
## For each seed: builds the house, drives the entity with synthetic deltas and
## a static player at the spawn point, validates invariants afterwards. Also
## checks the fallback layout (small-house relaxation) and that the entity
## schedule is deterministic for a given seed.

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")
const Entity := preload("res://scripts/gameplay/entity.gd")

const SIM_SECONDS := 240.0
const STEP := 0.1

var _failures := 0


func _initialize() -> void:
	var count := 20
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and int(args[0]) > 0:
		count = int(args[0])
	for i in count:
		var seed := 9000 + i * 173
		var problems := _test_seed(seed)
		if not problems.is_empty():
			_failures += 1
			print("FAIL seed %d: %s" % [seed, ", ".join(problems)])
	var fb := _test_fallback()
	if not fb.is_empty():
		_failures += 1
		print("FAIL fallback layout: %s" % ", ".join(fb))
	var det := _test_determinism(777)
	if not det.is_empty():
		_failures += 1
		print("FAIL determinism: %s" % ", ".join(det))
	if _failures == 0:
		print("OK: %d seeds + fallback + determinism validated" % count)
	else:
		print("FAILED: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_seed(seed: int) -> Array:
	var problems: Array = []
	var run := _make_run(seed, HouseGenerator.generate_layout(seed))
	if not _run_ok(run):
		_teardown(run)
		return ["run setup failed"]
	for i in int(SIM_SECONDS / STEP):
		run["entity"]._process(STEP)
	run["entity"].stop_run()
	var ent = run["entity"]
	if ent.appearances < 2:
		problems.append("entity appeared only %d time(s) in %ds" % [ent.appearances, int(SIM_SECONDS)])
	for ev in run["events"]:
		var pos := Vector2(ev[1], ev[2])
		if not _is_floor(run["layout"], pos):
			problems.append("entity visible at non-floor position %s" % str(pos))
			break
	_teardown(run)
	return problems


func _test_fallback() -> Array:
	var problems: Array = []
	var layout := HouseGenerator._fallback_layout(12345)
	var run := _make_run(12345, layout)
	if not _run_ok(run):
		_teardown(run)
		return ["run setup failed"]
	for i in int(SIM_SECONDS / STEP):
		run["entity"]._process(STEP)
	run["entity"].stop_run()
	var ent = run["entity"]
	if ent.appearances < 1:
		problems.append("entity never appeared in the fallback house")
	for ev in run["events"]:
		var pos := Vector2(ev[1], ev[2])
		if not _is_floor(layout, pos):
			problems.append("entity visible at non-floor position %s" % str(pos))
			break
	_teardown(run)
	return problems


func _test_determinism(seed: int) -> Array:
	var a := _make_run(seed, HouseGenerator.generate_layout(seed))
	if not _run_ok(a):
		_teardown(a)
		return ["run setup failed"]
	for i in int(SIM_SECONDS / STEP):
		a["entity"]._process(STEP)
	var b := _make_run(seed, HouseGenerator.generate_layout(seed))
	if not _run_ok(b):
		_teardown(a)
		_teardown(b)
		return ["run setup failed (second run)"]
	for i in int(SIM_SECONDS / STEP):
		b["entity"]._process(STEP)
	var ea: Array = a["events"]
	var eb: Array = b["events"]
	_teardown(a)
	_teardown(b)
	if ea.is_empty():
		return ["no state transitions recorded"]
	if ea != eb:
		return ["schedule differs: %s vs %s" % [str(ea), str(eb)]]
	return []


func _make_run(seed: int, layout: Dictionary) -> Dictionary:
	var house := Node2D.new()
	house.name = "House"
	if not layout.is_empty():
		house = HouseGenerator.build_house(layout)
	root.add_child(house)
	var player := Node2D.new()
	player.name = "Player"
	if not layout.is_empty():
		player.position = layout["spawn"]
	root.add_child(player)
	var entity := Entity.new()
	root.add_child(entity)
	var events: Array = []
	entity.entity_state_changed.connect(func(s: int) -> void:
		events.append([s, roundf(entity.position.x * 10.0) / 10.0, roundf(entity.position.y * 10.0) / 10.0]))
	if not layout.is_empty():
		entity.start_run(seed, layout, house, player)
	return {"layout": layout, "house": house, "player": player, "entity": entity, "events": events}


func _run_ok(run) -> bool:
	if not (run is Dictionary):
		return false
	var e = run.get("entity")
	return e != null and e.has_method("stop_run")


func _is_floor(layout: Dictionary, pos: Vector2) -> bool:
	var grid: Array = layout["grid"]
	var cx := int(pos.x / Entity.TILE)
	var cy := int(pos.y / Entity.TILE)
	if cx < 0 or cy < 0 or cx >= layout["grid_w"] or cy >= layout["grid_h"]:
		return false
	return grid[cy][cx] == HouseGenerator.FLOOR


func _teardown(run) -> void:
	if not (run is Dictionary):
		return
	for key in ["entity", "player", "house"]:
		var n = run.get(key)
		if n != null and n.get_parent() == root:
			root.remove_child(n)
			n.free()
