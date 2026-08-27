extends RefCounted
## Procedural house generator.
##
## Two stages, both deterministic from a seed:
##   generate_layout(seed) -> Dictionary of pure data (testable headless)
##   build_house(layout)   -> Node2D ready to add to the scene tree
##
## The layout is a grid of cells (WALL / FLOOR / DOOR). Rooms are carved
## rectangles, connected by an L-shaped corridor spanning tree with a door at
## each entry. A BFS validation guarantees the key and the exit are reachable;
## if generation keeps failing, a minimal guaranteed house is produced instead.

const LightUtils := preload("res://scripts/core/light_utils.gd")

const TILE := 32
const GRID_W := 44
const GRID_H := 32

const WALL := 1
const FLOOR := 2
const DOOR := 3

const ENTRANCE_TYPE := "entrance"
const ROOM_TYPES: Array = [
	"living_room", "kitchen", "bedroom", "bathroom",
	"storage", "office", "dining_room", "utility_room",
]

const FURNITURE: Dictionary = {
	"living_room": [["sofa", 3, 1], ["table", 2, 2], ["shelf", 2, 1]],
	"kitchen": [["counter", 3, 1], ["table", 2, 2], ["fridge", 1, 1], ["cabinet", 2, 1]],
	"bedroom": [["bed", 3, 2], ["wardrobe", 2, 1], ["nightstand", 1, 1]],
	"bathroom": [["bathtub", 3, 1], ["sink", 1, 1], ["toilet", 1, 1]],
	"storage": [["shelf", 2, 1], ["crate", 1, 1], ["crate", 1, 1]],
	"office": [["desk", 2, 1], ["chair", 1, 1], ["shelf", 2, 1]],
	"dining_room": [["table", 3, 2], ["cabinet", 2, 1]],
	"utility_room": [["counter", 2, 1], ["crate", 1, 1]],
}

const FURNITURE_COLORS: Dictionary = {
	"sofa": Color(0.30, 0.24, 0.20),
	"table": Color(0.26, 0.21, 0.16),
	"shelf": Color(0.22, 0.18, 0.14),
	"counter": Color(0.24, 0.23, 0.21),
	"fridge": Color(0.30, 0.30, 0.32),
	"cabinet": Color(0.23, 0.19, 0.15),
	"bed": Color(0.28, 0.23, 0.20),
	"wardrobe": Color(0.21, 0.17, 0.13),
	"nightstand": Color(0.24, 0.20, 0.16),
	"bathtub": Color(0.32, 0.32, 0.33),
	"sink": Color(0.30, 0.31, 0.32),
	"toilet": Color(0.30, 0.30, 0.31),
	"crate": Color(0.25, 0.21, 0.15),
	"desk": Color(0.24, 0.19, 0.14),
	"chair": Color(0.22, 0.18, 0.14),
}


static func generate_layout(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for attempt in range(8):
		var layout := _try_generate(rng, seed + attempt * 7919)
		if not layout.is_empty():
			return layout
	push_warning("HouseGenerator: all attempts failed for seed %d, using fallback house" % seed)
	return _fallback_layout(seed)


static func build_house(layout: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = "House"

	var floor_node := _FloorView.new()
	floor_node.layout = layout
	root.add_child(floor_node)

	# Walls: one StaticBody2D per horizontal run of wall cells.
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	var grid: Array = layout["grid"]
	var gw: int = layout["grid_w"]
	var gh: int = layout["grid_h"]
	for y in gh:
		var x := 0
		while x < gw:
			if grid[y][x] == WALL:
				var x2 := x
				while x2 + 1 < gw and grid[y][x2 + 1] == WALL:
					x2 += 1
				var body := StaticBody2D.new()
				var shape := CollisionShape2D.new()
				var rect_shape := RectangleShape2D.new()
				rect_shape.size = Vector2((x2 - x + 1) * TILE, TILE)
				shape.shape = rect_shape
				body.add_child(shape)
				body.position = Vector2((x + (x2 - x + 1) / 2.0) * TILE, (y + 0.5) * TILE)
				walls.add_child(body)
				x = x2 + 1
			else:
				x += 1
	root.add_child(walls)

	# Furniture.
	var furn := Node2D.new()
	furn.name = "Furniture"
	for f in layout["furniture"]:
		var item := _FurnitureItem.new()
		item.item_name = f["name"]
		item.color = FURNITURE_COLORS.get(f["name"], Color(0.25, 0.2, 0.16))
		item.size_cells = Vector2i(f["w"], f["h"])
		item.position = Vector2(f["cell"].x * TILE, f["cell"].y * TILE)
		furn.add_child(item)
	root.add_child(furn)

	# Doors + exit.
	var DoorScript: GDScript = preload("res://scripts/gameplay/door.gd")
	for d in layout["doors"]:
		var door: Node2D = DoorScript.new()
		door.position = Vector2((d["cell"].x + 0.5) * TILE, (d["cell"].y + 0.5) * TILE)
		root.add_child(door)
	var exit_door: Node2D = DoorScript.new()
	exit_door.is_exit = true
	exit_door.locked = true
	exit_door.position = Vector2((layout["exit_cell"].x + 0.5) * TILE, (layout["exit_cell"].y + 0.5) * TILE)
	root.add_child(exit_door)

	# Room lights.
	var LightFlicker: GDScript = preload("res://scripts/generation/light_flicker.gd")
	var light_tex := LightUtils.make_radial_texture()
	for l in layout["lights"]:
		var light := PointLight2D.new()
		light.texture = light_tex
		light.texture_scale = l["scale"]
		light.light_energy = l["energy"]
		light.color = l["color"]
		light.position = l["pos"]
		if l["flicker"]:
			var fl: Node = LightFlicker.new()
			light.add_child(fl)
		root.add_child(light)

	# The key.
	var KeyItemScript: GDScript = preload("res://scripts/gameplay/key_item.gd")
	var key: Node2D = KeyItemScript.new()
	key.position = Vector2((layout["key_cell"].x + 0.5) * TILE, (layout["key_cell"].y + 0.5) * TILE)
	root.add_child(key)

	return root


# ---------------------------------------------------------------------------
# Layout generation
# ---------------------------------------------------------------------------

static func _try_generate(rng: RandomNumberGenerator, eff_seed: int) -> Dictionary:
	var grid := _empty_grid()
	var rooms: Array = []

	# Place non-overlapping room rectangles.
	var target := rng.randi_range(8, 11)
	var attempts := 0
	while rooms.size() < target and attempts < 120:
		attempts += 1
		var w := rng.randi_range(5, 9)
		var h := rng.randi_range(4, 7)
		var x := rng.randi_range(1, GRID_W - w - 2)
		var y := rng.randi_range(1, GRID_H - h - 2)
		var rect := Rect2i(x, y, w, h)
		if _overlaps_any(rect, rooms, 1):
			continue
		for cy in rect.size.y:
			for cx in rect.size.x:
				grid[rect.position.y + cy][rect.position.x + cx] = FLOOR
		rooms.append({
			"id": rooms.size(),
			"type": "",
			"rect": rect,
			"center": Vector2i(rect.position + rect.size / 2),
		})

	if rooms.size() < 6:
		return {}

	# Assign semantic types; the first room is always the entrance.
	rooms[0]["type"] = ENTRANCE_TYPE
	var pool: Array = ROOM_TYPES.duplicate()
	_shuffle(rng, pool)
	for i in range(1, rooms.size()):
		rooms[i]["type"] = pool[(i - 1) % pool.size()]

	# Corridors + doors: Prim-like spanning tree over room centers.
	var corridor_cells: Array[Vector2i] = []
	var door_cells: Array[Vector2i] = []
	var doors: Array = []
	var connected: Array = [rooms[0]]
	while connected.size() < rooms.size():
		var best_score := -1
		var best_pair := {}
		for a in connected:
			for b in rooms:
				if connected.has(b):
					continue
				var d: float = (a["center"] as Vector2i).distance_to(b["center"] as Vector2i)
				if best_score < 0 or d < best_score:
					best_score = d
					best_pair = {"a": a, "b": b}
		var a: Dictionary = best_pair["a"]
		var b: Dictionary = best_pair["b"]

		var path := _corridor_path(rng, a["center"], b["center"])
		for cell in path:
			if grid[cell.y][cell.x] == WALL:
				grid[cell.y][cell.x] = FLOOR
				corridor_cells.append(cell)

		# Door where the corridor meets room b's wall (only if there is a wall).
		var door_cell := _door_at_entry(path, b["rect"])
		if door_cell != Vector2i(-1, -1) and grid[door_cell.y][door_cell.x] == WALL \
				and not door_cells.has(door_cell):
			grid[door_cell.y][door_cell.x] = DOOR
			door_cells.append(door_cell)
			doors.append({"id": doors.size(), "cell": door_cell, "rooms": [a["id"], b["id"]]})
		connected.append(b)

	# Exit: a wall cell on the entrance room's perimeter.
	var er: Rect2i = rooms[0]["rect"]
	var exit_cell := Vector2i(-1, -1)
	var candidates: Array[Vector2i] = []
	for x in range(er.position.x, er.end.x):
		candidates.append(Vector2i(x, er.end.y))
		candidates.append(Vector2i(x, er.position.y - 1))
	for y in range(er.position.y, er.end.y):
		candidates.append(Vector2i(er.end.x, y))
		candidates.append(Vector2i(er.position.x - 1, y))
	for c in candidates:
		if c.x >= 0 and c.x < GRID_W and c.y >= 0 and c.y < GRID_H and grid[c.y][c.x] == WALL:
			exit_cell = c
			break
	if exit_cell == Vector2i(-1, -1):
		return {}
	grid[exit_cell.y][exit_cell.x] = DOOR

	var spawn_cell: Vector2i = rooms[0]["center"]
	var spawn := Vector2((spawn_cell.x + 0.5) * TILE, (spawn_cell.y + 0.5) * TILE)

	# Cells furniture must not touch: corridors, doorways, exit, and their edges.
	var reserved := {}
	for c in corridor_cells:
		reserved[c] = true
		for n in _neighbors(c):
			reserved[n] = true
	for dc in door_cells:
		reserved[dc] = true
		for n in _neighbors(dc):
			reserved[n] = true
	reserved[exit_cell] = true

	# Key: a floor cell in some non-entrance room, away from doorways.
	var key_rooms: Array = []
	for r in rooms:
		if r["id"] != 0:
			key_rooms.append(r)
	var kr: Dictionary = key_rooms[rng.randi_range(0, key_rooms.size() - 1)]
	var krect: Rect2i = kr["rect"]
	var options: Array[Vector2i] = []
	for cy in range(krect.position.y + 1, krect.end.y - 1):
		for cx in range(krect.position.x + 1, krect.end.x - 1):
			if grid[cy][cx] == FLOOR and not reserved.has(Vector2i(cx, cy)):
				options.append(Vector2i(cx, cy))
	if options.is_empty():
		for cy in range(krect.position.y, krect.end.y):
			for cx in range(krect.position.x, krect.end.x):
				if grid[cy][cx] == FLOOR:
					options.append(Vector2i(cx, cy))
	if options.is_empty():
		return {}
	var key_cell: Vector2i = options[rng.randi_range(0, options.size() - 1)]
	reserved[key_cell] = true

	# Furniture.
	var furniture: Array = []
	for room in rooms:
		var rrect: Rect2i = room["rect"]
		var defs: Array = (FURNITURE.get(room["type"], []) as Array).duplicate()
		if defs.is_empty():
			continue
		_shuffle(rng, defs)
		var count := mini(defs.size(), 2 + rng.randi_range(0, 1))
		for i in count:
			var def: Array = defs[i]
			var fw: int = def[1]
			var fh: int = def[2]
			for attempt in 24:
				var fx := rng.randi_range(rrect.position.x, rrect.end.x - fw)
				var fy := rng.randi_range(rrect.position.y, rrect.end.y - fh)
				if _fits(grid, reserved, Vector2i(fx, fy), fw, fh):
					furniture.append({"name": def[0], "cell": Vector2i(fx, fy), "w": fw, "h": fh})
					for cy in fh:
						for cx in fw:
							reserved[Vector2i(fx + cx, fy + cy)] = true
					break

	# Room lights.
	var lights: Array = []
	for room in rooms:
		var c: Vector2i = room["center"]
		lights.append({
			"pos": Vector2((c.x + 0.5) * TILE, (c.y + 0.5) * TILE),
			"energy": 0.75 + rng.randf() * 0.45,
			"scale": 3.2 + rng.randf() * 1.6,
			"flicker": rng.randf() < 0.35,
			"color": Color(1.0, 0.86 - rng.randf() * 0.08, 0.62 - rng.randf() * 0.1),
		})

	# Validation: everything critical must be reachable from the spawn.
	if not _reachable(grid, spawn_cell, key_cell) or not _reachable(grid, spawn_cell, exit_cell):
		return {}
	for room in rooms:
		if not _reachable(grid, spawn_cell, room["center"]):
			return {}

	return {
		"seed": eff_seed,
		"grid_w": GRID_W,
		"grid_h": GRID_H,
		"grid": grid,
		"rooms": rooms,
		"doors": doors,
		"exit_cell": exit_cell,
		"spawn": spawn,
		"key_cell": key_cell,
		"furniture": furniture,
		"lights": lights,
	}


static func _fallback_layout(seed: int) -> Dictionary:
	# Deterministic minimal house: one large room. Guarantees a playable run.
	var grid := _empty_grid()
	var rect := Rect2i(16, 12, 12, 8)
	for cy in rect.size.y:
		for cx in rect.size.x:
			grid[rect.position.y + cy][rect.position.x + cx] = FLOOR
	var exit_cell := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)
	grid[exit_cell.y][exit_cell.x] = DOOR
	var key_cell := Vector2i(rect.position.x + 1, rect.position.y + 1)
	var center := Vector2i(rect.position + rect.size / 2)
	return {
		"seed": seed,
		"grid_w": GRID_W,
		"grid_h": GRID_H,
		"grid": grid,
		"rooms": [{"id": 0, "type": ENTRANCE_TYPE, "rect": rect, "center": center}],
		"doors": [],
		"exit_cell": exit_cell,
		"spawn": Vector2((center.x + 0.5) * TILE, (center.y + 0.5) * TILE),
		"key_cell": key_cell,
		"furniture": [],
		"lights": [{
			"pos": Vector2((center.x + 0.5) * TILE, (center.y + 0.5) * TILE),
			"energy": 1.0, "scale": 4.0, "flicker": false,
			"color": Color(1.0, 0.86, 0.62),
		}],
	}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func _empty_grid() -> Array:
	var grid := []
	for y in GRID_H:
		var row := PackedByteArray()
		row.resize(GRID_W)
		row.fill(WALL)
		grid.append(row)
	return grid


static func _overlaps_any(rect: Rect2i, rooms: Array, margin: int) -> bool:
	for r in rooms:
		if rect.intersects((r["rect"] as Rect2i).grow(margin)):
			return true
	return false


static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _neighbors(c: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(c.x + 1, c.y), Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1), Vector2i(c.x, c.y - 1),
	]


static func _corridor_path(rng: RandomNumberGenerator, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var mid := Vector2i(to.x, from.y) if rng.randf() < 0.5 else Vector2i(from.x, to.y)
	var path := _line(from, mid)
	path.append_array(_line(mid, to))
	return path


static func _line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x := a.x
	var y := a.y
	while true:
		cells.append(Vector2i(x, y))
		if x == b.x and y == b.y:
			break
		if x < b.x:
			x += 1
		elif x > b.x:
			x -= 1
		if y < b.y:
			y += 1
		elif y > b.y:
			y -= 1
	return cells


static func _door_at_entry(path: Array, room_rect: Rect2i) -> Vector2i:
	for i in range(path.size() - 1, -1, -1):
		var c: Vector2i = path[i]
		if not room_rect.has_point(c):
			continue
		if i == 0 or not room_rect.has_point(path[i - 1]):
			return c
	return Vector2i(-1, -1)


static func _fits(grid: Array, reserved: Dictionary, at: Vector2i, w: int, h: int) -> bool:
	for cy in h:
		for cx in w:
			var c := Vector2i(at.x + cx, at.y + cy)
			if c.x < 0 or c.x >= GRID_W or c.y < 0 or c.y >= GRID_H:
				return false
			if grid[c.y][c.x] != FLOOR or reserved.has(c):
				return false
	return true


static func _reachable(grid: Array, from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true
	var seen := {}
	var queue: Array[Vector2i] = [from]
	seen[from] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in _neighbors(c):
			if n.x < 0 or n.x >= GRID_W or n.y < 0 or n.y >= GRID_H:
				continue
			if seen.has(n):
				continue
			var v: int = grid[n.y][n.x]
			if v != FLOOR and v != DOOR:
				continue
			seen[n] = true
			if n == to:
				return true
			queue.append(n)
	return false


# ---------------------------------------------------------------------------
# Scene building helpers
# ---------------------------------------------------------------------------

class _FloorView extends Node2D:
	var layout: Dictionary = {}

	func _draw() -> void:
		var grid: Array = layout["grid"]
		var gw: int = layout["grid_w"]
		var gh: int = layout["grid_h"]
		for y in gh:
			for x in gw:
				var cell := Vector2(x * TILE, y * TILE)
				match grid[y][x]:
					WALL:
						draw_rect(Rect2(cell, Vector2(TILE, TILE)), Color(0.10, 0.095, 0.09))
					FLOOR:
						var shade := 0.14 + ((x * 7 + y * 13) % 5) / 5.0 * 0.03
						draw_rect(Rect2(cell, Vector2(TILE, TILE)), Color(shade, shade * 0.97, shade * 0.92))
					DOOR:
						draw_rect(Rect2(cell, Vector2(TILE, TILE)), Color(0.07, 0.065, 0.06))


class _FurnitureItem extends Node2D:
	var item_name := "crate"
	var color := Color(0.25, 0.2, 0.16)
	var size_cells := Vector2i(1, 1)

	func _ready() -> void:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(size_cells.x * TILE, size_cells.y * TILE)
		shape.shape = rect_shape
		body.add_child(shape)
		add_child(body)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, Vector2(size_cells.x * TILE, size_cells.y * TILE))
		draw_rect(r, color)
		draw_rect(r.grow(-3), Color(0, 0, 0, 0.15))
