extends SceneTree
## Headless anomaly system test.
## Run: godot --headless -s res://tests/anomaly_test.gd [seed_count]
## For each seed: builds the house, drives the anomaly system with synthetic
## deltas (no player), and validates invariants afterwards. Also checks that
## the anomaly schedule is deterministic for a given seed.

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")
const AnomalySystem := preload("res://scripts/gameplay/anomaly_system.gd")

const SIM_SECONDS := 150.0
const STEP := 0.1

var _failures := 0


func _initialize() -> void:
	var count := 20
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and int(args[0]) > 0:
		count = int(args[0])
	for i in count:
		var seed := 5000 + i * 131
		var problems := _test_seed(seed)
		if not problems.is_empty():
			_failures += 1
			print("FAIL seed %d: %s" % [seed, ", ".join(problems)])
	var det := _test_determinism(777)
	if not det.is_empty():
		_failures += 1
		print("FAIL determinism: %s" % ", ".join(det))
	if _failures == 0:
		print("OK: %d seeds + determinism validated" % count)
	else:
		print("FAILED: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_seed(seed: int) -> Array:
	var problems: Array = []
	var run := _make_run(seed)
	if not _run_ok(run):
		_teardown(run)
		return ["run setup failed"]
	if (run["layout"] as Dictionary).is_empty():
		_teardown(run)
		return ["empty layout"]
	for i in int(SIM_SECONDS / STEP):
		run["anomaly"]._process(STEP)
	# Snap any in-flight transition to its end state before validating.
	run["anomaly"].stop_run()
	problems.append_array(run["anomaly"].validate())
	var fired: Array = run["fired"]
	if fired.size() < 3:
		problems.append("too few anomalies fired in %ds (%d)" % [int(SIM_SECONDS), fired.size()])
	_teardown(run)
	return problems


func _test_determinism(seed: int) -> Array:
	var a := _make_run(seed)
	if not _run_ok(a):
		_teardown(a)
		return ["run setup failed"]
	for i in int(SIM_SECONDS / STEP):
		a["anomaly"]._process(STEP)
	var b := _make_run(seed)
	if not _run_ok(b):
		_teardown(a)
		_teardown(b)
		return ["run setup failed (second run)"]
	for i in int(SIM_SECONDS / STEP):
		b["anomaly"]._process(STEP)
	var fa: Array = a["fired"]
	var fb: Array = b["fired"]
	_teardown(a)
	_teardown(b)
	if fa.is_empty():
		return ["no anomalies fired"]
	if fa != fb:
		return ["schedule differs: %s vs %s" % [str(fa), str(fb)]]
	return []


func _make_run(seed: int) -> Dictionary:
	var layout := HouseGenerator.generate_layout(seed)
	var house := Node2D.new()
	house.name = "House"
	if not layout.is_empty():
		house = HouseGenerator.build_house(layout)
	root.add_child(house)
	var anomaly := AnomalySystem.new()
	root.add_child(anomaly)
	var fired: Array = []
	anomaly.anomaly_started.connect(func(id: String) -> void:
		fired.append(id))
	if not layout.is_empty():
		# Open one door so door_slam has a candidate.
		for d in get_nodes_in_group("interactables"):
			if d.has_method("toggle") and not d.is_exit:
				d.toggle()
				break
		anomaly.start_run(seed, layout, house, null)
	return {"layout": layout, "house": house, "anomaly": anomaly, "fired": fired}


func _run_ok(run) -> bool:
	if not (run is Dictionary):
		return false
	var a = run.get("anomaly")
	return a != null and a.has_method("validate")


func _teardown(run) -> void:
	if not (run is Dictionary):
		return
	var anomaly = run.get("anomaly")
	var house = run.get("house")
	if anomaly != null and anomaly.get_parent() == root:
		root.remove_child(anomaly)
		anomaly.free()
	if house != null and house.get_parent() == root:
		root.remove_child(house)
		house.free()
