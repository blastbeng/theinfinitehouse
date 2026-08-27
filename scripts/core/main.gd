extends Node2D
## Top-level flow: title -> run -> pause / ending. Builds the HUD, overlays and
## the per-run world procedurally; no external assets.

const HouseGenerator := preload("res://scripts/generation/house_generator.gd")
const ObjectiveSystem := preload("res://scripts/gameplay/objective_system.gd")
const AnomalySystem := preload("res://scripts/gameplay/anomaly_system.gd")
const Entity := preload("res://scripts/gameplay/entity.gd")
const PlayerScene: PackedScene = preload("res://scenes/player.tscn")

enum State { TITLE, RUNNING, PAUSED, ENDED }

var state: int = State.TITLE
var current_seed := 0
var run_time := 0.0

var world: Node2D
var player: CharacterBody2D
var objective: RefCounted
var anomaly: Node
var entity: Node

# HUD
var hud_layer: CanvasLayer
var objective_label: Label
var seed_label: Label
var time_label: Label
var prompt_label: Label

# Overlays
var title_layer: CanvasLayer
var howto_label: Label
var pause_layer: CanvasLayer
var end_layer: CanvasLayer
var end_title_label: Label
var end_stats_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	world = Node2D.new()
	world.name = "World"
	# Process normally, freeze while the tree is paused (pause menu).
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	_build_hud()
	_build_title()
	_build_pause()
	_build_end()
	_show_title()


func _process(delta: float) -> void:
	if state == State.RUNNING and not get_tree().paused:
		run_time += delta
		_update_time_label()
	if Input.is_action_just_pressed("pause"):
		if state == State.RUNNING:
			_set_paused(true)
		elif state == State.PAUSED:
			_set_paused(false)


# --- input ------------------------------------------------------------------

func _setup_input() -> void:
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_E, KEY_ENTER])
	_add_action("pause", [KEY_ESCAPE])


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)


# --- run lifecycle ----------------------------------------------------------

func start_run(seed: int) -> void:
	get_tree().paused = false
	current_seed = seed
	run_time = 0.0
	_clear_world()

	var layout := HouseGenerator.generate_layout(seed)
	var house := HouseGenerator.build_house(layout)
	house.name = "House"
	world.add_child(house)

	player = PlayerScene.instantiate()
	player.position = layout["spawn"]
	world.add_child(player)
	var cam := player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = layout["grid_w"] * HouseGenerator.TILE
	cam.limit_bottom = layout["grid_h"] * HouseGenerator.TILE

	objective = ObjectiveSystem.new()
	objective.objective_changed.connect(_on_objective_changed)
	objective.start("find_key")

	var keys := get_tree().get_nodes_in_group("key_item")
	if keys.size() > 0:
		keys[0].picked_up.connect(_on_key_picked_up)
	for d in get_tree().get_nodes_in_group("exit_door"):
		d.escape_requested.connect(_on_escape_requested)
	player.prompt_changed.connect(_on_prompt_changed)

	anomaly = AnomalySystem.new()
	world.add_child(anomaly)
	anomaly.start_run(seed, layout, house, player)

	entity = Entity.new()
	world.add_child(entity)
	entity.start_run(seed, layout, house, player)

	state = State.RUNNING
	title_layer.visible = false
	pause_layer.visible = false
	end_layer.visible = false
	hud_layer.visible = true
	prompt_label.text = ""
	_update_hud_labels()


func _clear_world() -> void:
	for c in world.get_children():
		world.remove_child(c)
		c.free()
	player = null
	objective = null
	anomaly = null
	entity = null


func end_run(result: String) -> void:
	state = State.ENDED
	get_tree().paused = false
	if anomaly:
		anomaly.stop_run()
	if entity:
		entity.stop_run()
	hud_layer.visible = false
	_show_end(result)


func _quit_to_title() -> void:
	get_tree().paused = false
	state = State.TITLE
	hud_layer.visible = false
	_show_title()


func _set_paused(p: bool) -> void:
	if p:
		state = State.PAUSED
		get_tree().paused = true
		pause_layer.visible = true
	else:
		state = State.RUNNING
		get_tree().paused = false
		pause_layer.visible = false


func _random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(1, 999999)


# --- HUD --------------------------------------------------------------------

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 2
	add_child(hud_layer)

	var vignette := ColorRect.new()
	vignette.color = Color.WHITE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = """
shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.3, 0.8, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.6);
}
"""
	vignette.material = mat
	hud_layer.add_child(vignette)

	objective_label = _make_label(18, Color(0.85, 0.82, 0.75))
	objective_label.position = Vector2(16, 14)
	hud_layer.add_child(objective_label)

	seed_label = _make_label(14, Color(0.55, 0.53, 0.5))
	seed_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	seed_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	seed_label.position = Vector2(-160, 14)
	hud_layer.add_child(seed_label)

	time_label = _make_label(14, Color(0.55, 0.53, 0.5))
	time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	time_label.position = Vector2(-160, 34)
	hud_layer.add_child(time_label)

	prompt_label = _make_label(20, Color(0.9, 0.87, 0.7))
	prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_label.position = Vector2(0, -56)
	hud_layer.add_child(prompt_label)


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _update_hud_labels() -> void:
	seed_label.text = "seed %d" % current_seed
	time_label.text = "00:00"


func _update_time_label() -> void:
	var t := int(run_time)
	var s := "%02d:%02d" % [t / 60, t % 60]
	if time_label.text != s:
		time_label.text = s


# --- overlays ---------------------------------------------------------------

func _build_title() -> void:
	title_layer = CanvasLayer.new()
	title_layer.name = "Title"
	title_layer.layer = 10
	title_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_layer)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.035)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(bg)

	var title := _make_label(56, Color(0.82, 0.78, 0.7))
	title.text = "THE INFINITE HOUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(0, 200)
	title_layer.add_child(title)

	var sub := _make_label(18, Color(0.5, 0.48, 0.45))
	sub.text = "A procedural house that becomes impossible to trust."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(0, 280)
	title_layer.add_child(sub)

	var new_game := _make_button("New Game", Vector2(530, 380), Vector2(220, 48))
	new_game.pressed.connect(func(): start_run(_random_seed()))
	title_layer.add_child(new_game)

	howto_label = _make_label(16, Color(0.6, 0.58, 0.52))
	howto_label.text = "WASD / arrows - move\nE - interact\nEsc - pause"
	howto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	howto_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	howto_label.position = Vector2(0, 450)
	howto_label.visible = false
	title_layer.add_child(howto_label)

	var howto := _make_button("How to Play", Vector2(530, 450), Vector2(220, 40))
	howto.pressed.connect(func(): howto_label.visible = not howto_label.visible)
	title_layer.add_child(howto)

	var quit := _make_button("Quit", Vector2(530, 640), Vector2(220, 40))
	quit.pressed.connect(func(): get_tree().quit())
	title_layer.add_child(quit)


func _build_pause() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.name = "Pause"
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.025, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(bg)

	var title := _make_label(40, Color(0.8, 0.77, 0.7))
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(0, 180)
	pause_layer.add_child(title)

	var resume := _make_button("Resume", Vector2(530, 300), Vector2(220, 48))
	resume.pressed.connect(func(): _set_paused(false))
	pause_layer.add_child(resume)

	var restart := _make_button("Restart (same seed)", Vector2(530, 364), Vector2(220, 44))
	restart.pressed.connect(func(): start_run(current_seed))
	pause_layer.add_child(restart)

	var new_run := _make_button("New Run", Vector2(530, 424), Vector2(220, 44))
	new_run.pressed.connect(func(): start_run(_random_seed()))
	pause_layer.add_child(new_run)

	var quit := _make_button("Quit to Title", Vector2(530, 484), Vector2(220, 44))
	quit.pressed.connect(func(): _quit_to_title())
	pause_layer.add_child(quit)


func _build_end() -> void:
	end_layer = CanvasLayer.new()
	end_layer.name = "End"
	end_layer.layer = 10
	end_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(end_layer)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(bg)

	end_title_label = _make_label(48, Color(0.82, 0.78, 0.7))
	end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	end_title_label.position = Vector2(0, 220)
	end_layer.add_child(end_title_label)

	end_stats_label = _make_label(18, Color(0.55, 0.53, 0.5))
	end_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_stats_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	end_stats_label.position = Vector2(0, 300)
	end_layer.add_child(end_stats_label)

	var new_run := _make_button("New Run", Vector2(530, 420), Vector2(220, 48))
	new_run.pressed.connect(func(): start_run(_random_seed()))
	end_layer.add_child(new_run)

	var menu := _make_button("Main Menu", Vector2(530, 484), Vector2(220, 44))
	menu.pressed.connect(func(): _quit_to_title())
	end_layer.add_child(menu)


func _make_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	return b


func _show_title() -> void:
	title_layer.visible = true
	pause_layer.visible = false
	end_layer.visible = false
	hud_layer.visible = false


func _show_end(result: String) -> void:
	var t := int(run_time)
	match result:
		"escape":
			end_title_label.text = "You escaped."
		_:
			end_title_label.text = "The house keeps you."
	end_stats_label.text = "seed %d  ·  %02dm %02ds in the house" % [current_seed, t / 60, t % 60]
	title_layer.visible = false
	pause_layer.visible = false
	end_layer.visible = true


# --- signal handlers --------------------------------------------------------

func _on_objective_changed(text: String) -> void:
	objective_label.text = text


func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text


func _on_key_picked_up(_key) -> void:
	objective.complete("find_key")
	for d in get_tree().get_nodes_in_group("exit_door"):
		d.locked = false
		d.queue_redraw()


func _on_escape_requested(_door) -> void:
	end_run("escape")
