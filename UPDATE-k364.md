RIFT k364 — Shared blue UI and Arsenal cleanup

- Arsenal and Rivals now use the shared flat blue category menu and search.
- Full-width setting names, wrapped module names, and top-center watermark across supported games.
- Removed Player Outlines, Third Person, and Zoom Unlocker from all supported menus and saved-control activation.
- Removed Arsenal Kill Chat, duplicate Enhanced ESP, Instant Hit, Hide Visuals, Named Presets, Preset Profiles, and developer sections.
- Fly and Noclip are independent. During respawn, combined Fly/Noclip retains character collision until hover constraints are ready.
- Auto Shoot is its own module with distance, firing mode, and rate controls. Aimbot alone never generates fire input.
- Legit is now an Aimbot mode.
- Arsenal Wallbang has head hitbox size and surface penetration distance controls; disable/unload restores modified parts.
- One ESP Boxes module with full boxes, names, health bars, distance, and colors; no limb information.
- Simpler Lighting, Visibility (No Fog/Full Bright), and Sky preset settings; sky selection preserves time.
- Shared Music Bridge overlay selected by default, with Game Audio available as an optional source.
- Removed explanatory settings paragraphs and hover descriptions.
- Old imported menu positions migrate to the new layout instead of placing the menu off-screen.

Validation: Luau compilation, existing suite, and production-code tests for imported menu creation/search/settings, independent aiming/firing, spawn collision gating, penetration budget rejection, and hitbox restoration. Live Roblox visuals and server acceptance of local shot/hitbox changes remain unverified.

Infinite Ammo still needs Arsenal's PlayerGui/GUI/Client shooting and reload code. Current adapter only changes Variables/ammocount and ammocount2 locally.
