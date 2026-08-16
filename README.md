# Button Stacker

A Stack-style game for Godot 4.4: a block slides left/right above the tower,
and pressing your button stops it — try to land it perfectly on the block
below. Whatever doesn't overlap gets trimmed off. Miss completely and it's
game over.

## Running it

1. Open Godot 4.4, choose "Import", and select the `project.godot` file in
   this folder.
2. Press Play (F5). It runs at 720x1280 (portrait) by default.

## Controls

- **Player buttons**: by default, keys `1`, `2`, `3`, `4` on a keyboard stop
  the block for players 1–4. This is meant to be driven by your physical
  button box wired as a keyboard encoder — whatever keys your switches send,
  just match them up (see "Remapping buttons" below).
- On the start screen:
  - **P** cycles the number of active players (1–4)
  - **M** toggles between Turn-Based and All-Together mode
  - **Button 1** (key `1`) starts the game, and restarts it after Game Over

## Game modes

- **Turn-Based** (default): players take turns. Only the current player's
  button does anything; after a successful placement, the turn passes to the
  next player.
- **All-Together**: everyone's button is live on every block, but the block
  only stops once *all* active players have pressed theirs. Good for a
  "commit as a team" feel if you want all 4 sides engaged on every piece.

## Remapping buttons

If your physical switches send different keys than 1/2/3/4, open
`scripts/InputSetup.gd` and edit the `PLAYER_KEYS` dictionary at the top:

```gdscript
const PLAYER_KEYS := {
    1: KEY_1,
    2: KEY_2,
    3: KEY_3,
    4: KEY_4,
}
```

Replace `KEY_1` etc. with whatever `KEY_*` constant matches your switch's
key (full list in Godot's docs under `@GlobalScope > Key`). No need to touch
the Input Map UI — this script sets it up automatically every time the game
starts.

## Tuning the feel

Most of the gameplay constants live at the top of `scripts/Main.gd`:

- `BASE_SPEED` / `SPEED_STEP` — how fast the block slides, and how much
  faster it gets after each placement
- `BLOCK_HEIGHT` — how tall each layer is
- `SNAP_TOLERANCE` — how many pixels off you can be and still get a "Perfect"
  (full-width, no trim) placement
- `DROP_GAP` — vertical gap between the falling block and the current tower
  top

## Project structure

```
project.godot          # engine + autoload + window config
scripts/InputSetup.gd  # autoload: sets up keyboard->player button mapping
scripts/Block.gd       # the falling/stacked block itself (draws + resizes)
scripts/Main.gd        # game loop: movement, input, scoring, stacking, UI
scenes/Main.tscn       # minimal scene, everything else built in code
```

Camera, background, tower container, and all UI are built in code inside
`Main.gd`'s `_build_scene()` rather than laid out in the scene file — makes
it easy to tweak positions/sizes by just editing numbers in one place.
