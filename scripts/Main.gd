extends Node2D
## Button Stacker - core game loop.
##
## Mechanic: a block slides left/right above the tower. Pressing a player's
## button stops it in place and drops it onto the stack. Whatever part of it
## doesn't overlap the block below gets trimmed off. If nothing overlaps,
## it's game over.
##
## Two multiplayer modes:
##  - TURN_BASED:   players take turns; only the active player's button works.
##  - ALL_TOGETHER: every active player must press their button before the
##                   block stops (good for a "everyone commits together" feel).

const VIEW_WIDTH := 720.0
const VIEW_HEIGHT := 1280.0
const BLOCK_HEIGHT := 44.0
const START_WIDTH := 260.0
const DROP_GAP := 260.0        # vertical gap between the falling block and current tower top
const MARGIN := 40.0           # side margin the block slides within
const BASE_SPEED := 240.0      # px/sec
const SPEED_STEP := 6.0        # speed increase applied after each successful placement
const CAMERA_OFFSET := 420.0   # how far below the tower top the camera centers itself
const SNAP_TOLERANCE := 6.0    # px of misalignment still counted as a "perfect" placement

enum Mode { TURN_BASED, ALL_TOGETHER }

@export var num_players: int = 1
@export var mode: Mode = Mode.TURN_BASED

var min_x: float
var max_x: float

var blocks_container: Node2D
var camera: Camera2D
var bg: ColorRect

var falling: Block = null
var falling_dir: int = 1
var falling_speed: float = BASE_SPEED
var falling_active: bool = false

var top_x_min: float
var top_x_max: float
var top_y: float

var score: int = 0
var game_over: bool = false
var game_started: bool = false

var player_order: Array = []
var current_player_i: int = 0
var pressed_this_round: Dictionary = {}

# UI
var ui: CanvasLayer
var score_label: Label
var turn_label: Label
var message_label: Label
var setup_label: Label
var game_over_panel: ColorRect
var final_score_label: Label

func _ready() -> void:
	min_x = MARGIN
	max_x = VIEW_WIDTH - MARGIN
	_build_scene()
	_show_setup_screen()

func _build_scene() -> void:
	bg = ColorRect.new()
	bg.color = Color(0.09, 0.10, 0.14)
	bg.size = Vector2(VIEW_WIDTH * 3, VIEW_HEIGHT * 8)
	bg.position = Vector2(-VIEW_WIDTH, -VIEW_HEIGHT * 7)
	add_child(bg)

	blocks_container = Node2D.new()
	add_child(blocks_container)

	camera = Camera2D.new()
	camera.position = Vector2(VIEW_WIDTH / 2.0, 0)
	camera.enabled = true
	add_child(camera)

	ui = CanvasLayer.new()
	add_child(ui)

	score_label = Label.new()
	score_label.position = Vector2(24, 24)
	score_label.add_theme_font_size_override("font_size", 40)
	ui.add_child(score_label)

	turn_label = Label.new()
	turn_label.position = Vector2(24, 76)
	turn_label.add_theme_font_size_override("font_size", 24)
	ui.add_child(turn_label)

	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.position = Vector2(24, VIEW_HEIGHT - 120)
	message_label.size = Vector2(VIEW_WIDTH - 48, 100)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.add_child(message_label)

	setup_label = Label.new()
	setup_label.add_theme_font_size_override("font_size", 28)
	setup_label.position = Vector2(40, VIEW_HEIGHT / 2.0 - 200)
	setup_label.size = Vector2(VIEW_WIDTH - 80, 440)
	setup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.add_child(setup_label)

	game_over_panel = ColorRect.new()
	game_over_panel.color = Color(0, 0, 0, 0.75)
	game_over_panel.size = Vector2(VIEW_WIDTH, VIEW_HEIGHT)
	game_over_panel.visible = false
	ui.add_child(game_over_panel)

	final_score_label = Label.new()
	final_score_label.add_theme_font_size_override("font_size", 34)
	final_score_label.position = Vector2(40, VIEW_HEIGHT / 2.0 - 100)
	final_score_label.size = Vector2(VIEW_WIDTH - 80, 240)
	final_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_panel.add_child(final_score_label)

func _show_setup_screen() -> void:
	game_started = false
	_update_setup_text()

func _update_setup_text() -> void:
	var mode_name := "Turn-Based (players alternate)" if mode == Mode.TURN_BASED else "All-Together (all sides press at once)"
	setup_label.text = "BUTTON STACKER\n\nPlayers: %d\nMode: %s\n\nPress P to change player count (1-4)\nPress M to change mode\nPress button 1 to start" % [num_players, mode_name]

func _process(delta: float) -> void:
	if not game_started:
		if Input.is_action_just_pressed("cycle_players"):
			num_players = num_players % 4 + 1
			_update_setup_text()
		if Input.is_action_just_pressed("cycle_mode"):
			mode = Mode.ALL_TOGETHER if mode == Mode.TURN_BASED else Mode.TURN_BASED
			_update_setup_text()
		if Input.is_action_just_pressed("p1_stop"):
			_start_game()
		return

	if game_over:
		if Input.is_action_just_pressed("p1_stop"):
			_restart()
		return

	if falling_active and falling:
		_move_falling(delta)
		_check_stop_input()

	var target_y: float = top_y - CAMERA_OFFSET
	camera.position.y = lerp(camera.position.y, target_y, clamp(delta * 6.0, 0.0, 1.0))

func _start_game() -> void:
	game_started = true
	game_over = false
	score = 0
	falling_speed = BASE_SPEED

	for c in blocks_container.get_children():
		c.queue_free()

	player_order.clear()
	for i in range(num_players):
		player_order.append(i + 1)
	current_player_i = 0

	var base := Block.new()
	base.color = Color(0.85, 0.85, 0.9)
	base.set_width(START_WIDTH)
	base.position = Vector2(VIEW_WIDTH / 2.0, 0)
	blocks_container.add_child(base)

	top_x_min = VIEW_WIDTH / 2.0 - START_WIDTH / 2.0
	top_x_max = VIEW_WIDTH / 2.0 + START_WIDTH / 2.0
	top_y = 0.0

	camera.position = Vector2(VIEW_WIDTH / 2.0, top_y - CAMERA_OFFSET)

	message_label.text = ""
	setup_label.text = ""
	game_over_panel.visible = false
	_update_turn_label()
	_spawn_falling()

func _restart() -> void:
	_start_game()

func _update_turn_label() -> void:
	score_label.text = "Score: %d" % score
	if mode == Mode.TURN_BASED and num_players > 1:
		turn_label.text = "Player %d's turn - press your button!" % player_order[current_player_i]
	elif mode == Mode.ALL_TOGETHER and num_players > 1:
		turn_label.text = "All %d players press together!" % num_players
	else:
		turn_label.text = "Press your button to stop the block!"

func _spawn_falling() -> void:
	var w: float = top_x_max - top_x_min
	falling = Block.new()
	falling.color = Color.from_hsv(fmod(score * 0.06, 1.0), 0.55, 0.95)
	falling.set_width(w)
	falling.position = Vector2(top_x_min + w / 2.0, top_y - DROP_GAP)
	add_child(falling)

	falling_dir = 1 if randi() % 2 == 0 else -1
	falling_active = true
	pressed_this_round.clear()

func _move_falling(delta: float) -> void:
	var half: float = falling.width / 2.0
	falling.position.x += falling_speed * falling_dir * delta
	if falling.position.x - half < min_x:
		falling.position.x = min_x + half
		falling_dir = 1
	elif falling.position.x + half > max_x:
		falling.position.x = max_x - half
		falling_dir = -1

func _check_stop_input() -> void:
	if mode == Mode.TURN_BASED or num_players <= 1:
		var active_player: int = player_order[current_player_i] if num_players > 1 else 1
		var action := "p%d_stop" % active_player
		if Input.is_action_just_pressed(action):
			_lock_falling()
	else:
		for p in player_order:
			var action := "p%d_stop" % p
			if Input.is_action_just_pressed(action):
				pressed_this_round[p] = true
		if pressed_this_round.size() >= player_order.size():
			_lock_falling()

func _lock_falling() -> void:
	falling_active = false
	var half: float = falling.width / 2.0
	var new_min: float = falling.position.x - half
	var new_max: float = falling.position.x + half

	var overlap_min: float = max(new_min, top_x_min)
	var overlap_max: float = min(new_max, top_x_max)
	var overlap: float = overlap_max - overlap_min

	if overlap <= 0.0:
		_end_game()
		return

	var full_width: float = new_max - new_min
	if overlap >= full_width - SNAP_TOLERANCE and abs(new_min - top_x_min) < SNAP_TOLERANCE and abs(new_max - top_x_max) < SNAP_TOLERANCE:
		overlap_min = top_x_min
		overlap_max = top_x_max
		overlap = overlap_max - overlap_min
		score += 2
		message_label.text = "Perfect!"
	else:
		score += 1
		message_label.text = ""

	falling.set_width(overlap)
	falling.position.x = (overlap_min + overlap_max) / 2.0
	falling.position.y = top_y - BLOCK_HEIGHT
	falling.reparent(blocks_container)

	top_x_min = overlap_min
	top_x_max = overlap_max
	top_y -= BLOCK_HEIGHT

	falling_speed += SPEED_STEP
	falling = null

	if mode == Mode.TURN_BASED and num_players > 1:
		current_player_i = (current_player_i + 1) % player_order.size()

	_update_turn_label()
	_spawn_falling()

func _end_game() -> void:
	game_over = true
	falling_active = false
	message_label.text = ""
	var who := ""
	if num_players > 1 and mode == Mode.TURN_BASED:
		who = " (Player %d missed)" % player_order[current_player_i]
	final_score_label.text = "Game Over!%s\nFinal Score: %d\n\nPress button 1 to play again" % [who, score]
	game_over_panel.visible = true
