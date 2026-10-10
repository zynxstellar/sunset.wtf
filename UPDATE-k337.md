# RIFT UPDATE — k337

**Atmosphere customization, slider improvements & Cold War cosmetics**

## Shared UI improvements
- Enlarged slider number fields for easier editing.
- Enlarged the + and - buttons for easier clicking.
- Slider callbacks now apply values directly instead of starting a new task for each value change.
- Sliders use the final pointer position when you release the mouse or touch.
- Only one slider owns the drag at a time.
- Slider cleanup restores scrolling when the UI unloads.
- Existing typed values, step increments, saved values and touch dragging remain supported.
- Regenerated the isolated menu test with the updated slider controls.

## Atmosphere
- Added Original, Blue, Purple, Rose and Amber sky options.
- Colored sky moods use the built-in sky textures, atmosphere colors and a subtle screen tint.
- Added a Custom Ambient toggle.
- Added an Ambient Color picker.
- Added an Outdoor Ambient picker.
- Added a Screen Tint toggle for coloring the overall scene.
- Added a Tint Color picker.
- Added a Tint Strength slider from 0% to 100%.
- Removed Custom Time and the Time of Day slider.
- Selecting Original restores the previous sky settings.
- Disabling Atmosphere restores the lighting and sky settings captured when it was enabled.
- Rift-created sky and color correction objects are removed during cleanup.

## Cold War
- Added Local Shooting Effects under Visuals.
- The effect produces cosmetic particle bursts around your character while enabled; it does not fire your weapon.
- Added an Effect Color picker.
- Added a Burst Particles slider.
- Effects are local: only you see them.
- The new effect sends no remote requests and does not add weapon hooks.
- Particle bursts have a fixed cadence and reuse one emitter.
- Effects clean up on death, game switching, disabling and unload.
- Added a separate Auto Shoot Max Distance slider: 25–5,000 studs.
- Auto Shoot target selection uses the lower of its distance limit and Silent Aim's distance limit.
- The firing check rejects targets beyond Auto Shoot's range, including validated wallbang targets.
- Changing Auto Shoot distance releases the currently owned trigger before the next target check.

## BedWars, Rivals & Project Delta
- These games receive the shared slider improvements.
- This release does not add new combat mechanics to these games.
- Existing dedicated game support is retained; no universal fallback was added.

## Removals retained
- Underground remains removed.
- Hit Sounds remains removed.
- Shoot While Seated remains removed.
- Bullet Speed remains removed.

## Validation
- Luau compilation and the existing regression suite passed.
- Added checks for sky restoration, ambient colors, screen tint and atmosphere cleanup.
- Added checks for bounded local effects and death/game-switch/unload cleanup.
- Added checks for slider release handling and scrolling cleanup.
- Added a check that out-of-range wallbang targets do not trigger Auto Shoot.

**Testing note:** These checks use local mocks. Live visuals, executor compatibility, crash-free operation and server damage registration are not verified by this release's tests.
