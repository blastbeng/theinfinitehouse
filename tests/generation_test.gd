extends SceneTree
## Headless multi-seed generation test.
## Run: godot --headless -s res://tests/generation_test.gd [seed_count]
## Validates spawn, key and exit placement plus BFS reachability for every seed.

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")

var _failures := 0


func _initialize() -> void:
	var count := 300
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and int(args[0]) > 0:
		count = int(args[0])
	for i in count:
		var seed := 1000 + i * 97
		var layout := HouseGenerator.generate_layout(seed)
		var problems := _validate(layout)
		if not problems.is_empty():
			_failures += 1
			print("FAIL seed %d: %s" % [seed, ", ".join(problems)])
	if _failures == 0:
		print("OK: %d seeds validated" % count)
	else:
		print("FAILED: %d/%d seeds invalid" % [_failures, count])
	quit(1 if _failures > 0 else 0)


func _validate(layout: Dictionary) -> Array:
	var problems: Array = []
	if layout.is_empty():
		return ["empty layout"]
	var grid: Array = layout["grid"]
	var gw: int = layout["grid_w"]
	var gh: int = layout["grid_h"]

	var sc := _cell_of(layout["spawn"])
	if not _in_bounds(sc, gw, gh) or grid[sc.y][sc.x] != HouseGenerator.FLOOR:
		problems.append("spawn not on floor")
	var kc: Vector2i = layout["key_cell"]
	if not _in_bounds(kc, gw, gh) or grid[kc.y][kc.x] != HouseGenerator.FLOOR:
		problems.append("key not on floor")
	var ec: Vector2i = layout["exit_cell"]
	if not _in_bounds(ec, gw, gh) or grid[ec.y][ec.x] != HouseGenerator.DOOR:
		problems.append("exit not a door")

	# BFS from spawn over FLOOR | DOOR.
	var seen := {}
	var queue: Array = [sc]
	seen[sc] = true
	while queue.size() > 0:
		var c: Vector2i = queue.pop_front()
		for n in _neighbors(c):
			if not _in_bounds(n, gw, gh) or seen.has(n):
				continue
			var v: int = grid[n.y][n.x]
			if v == HouseGenerator.FLOOR or v == HouseGenerator.DOOR:
				seen[n] = true
				queue.append(n)
	if not seen.has(kc):
		problems.append("key unreachable")
	if not seen.has(ec):
		problems.append("exit unreachable")
	for r in layout["rooms"]:
		var rc: Vector2i = r["center"]
		if not seen.has(rc):
			problems.append("room %d center unreachable" % r["id"])
	return problems


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / HouseGenerator.TILE), int(p.y / HouseGenerator.TILE))


func _in_bounds(c: Vector2i, gw: int, gh: int) -> bool:
	return c.x >= 0 and c.x < gw and c.y >= 0 and c.y < gh


func _neighbors(c: Vector2i) -> Array:
	return [Vector2i(c.x + 1, c.y), Vector2i(c.x - 1, c.y), Vector2i(c.x, c.y + 1), Vector2i(c.x, c.y - 1)]
