# Rift k351

Cold War changes:
- Added Hitboxes in Combat. Independently select Head, Torso, Left Arm, Right Arm, Left Leg and Right Leg. Supports multiple selections together, R6/R15 limb names, a 2–50 stud size slider (default 20), and Team Check enabled by default.
- Original sizes, collision, mass and transparency restore on deselection, disable, death, team changes, character replacement, leaving, switching games and unloading. Checks run at most four times per second while active.
- Added Instant Actions in Player. Skips local vehicle entry/exit animations and door waits using the existing native completion paths; server approval remains required. Hooks install only when enabled and restore on disable/unload.
- Added Car Kill All in Combat. Driver-only automatic vehicle approaches underneath a randomly selected living enemy, with team filtering and a speed control. Retains a target until invalid; pauses while typing or using the menu and clears when the vehicle is lost.
- Fixed repeated vehicle exit attempts losing their original animation cache during Instant Actions cleanup.

Validation: full local regression suite and Luau compilation passed. No live Roblox verification. Local hitbox resizing and vehicle ramming do not guarantee server damage or kills. Existing games and controls remain supported.
