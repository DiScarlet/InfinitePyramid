extends Node
## Autoload singleton (see project.godot -> [autoload]).
##
## Sets up the input actions in code instead of hand-editing project.godot's
## input map, so you can just change the keycodes below and re-run.
##
## Your button box has one physical switch per side, wired into a keyboard
## encoder. Whatever key each switch is programmed to send, put that key here.
## By default this assumes the switches send "1", "2", "3", "4".

const PLAYER_KEYS := {
	1: KEY_1,
	2: KEY_2,
	3: KEY_3,
	4: KEY_4,
}

# Used only on the pre-game setup screen to choose player count / mode.
# These can be the same physical box, or your regular keyboard - your call.
const EXTRA_ACTIONS := {
	"cycle_players": KEY_P,
	"cycle_mode": KEY_M,
}

func _ready() -> void:
	for player_num in PLAYER_KEYS.keys():
		var action_name := "p%d_stop" % player_num
		_ensure_action(action_name, PLAYER_KEYS[player_num])
	for action_name in EXTRA_ACTIONS.keys():
		_ensure_action(action_name, EXTRA_ACTIONS[action_name])

func _ensure_action(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var already_has := false
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and ev.physical_keycode == keycode:
			already_has = true
			break

	if not already_has:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
