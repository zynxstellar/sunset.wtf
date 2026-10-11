# Rift k360

Car Kill All excludes CharacterValues.Unconscious targets, including targets knocked during pursuit. Targets farther than 500 studs receive one approach hop to 100 studs away, below target height, then flight resumes. Underground cruise is capped at 300 km/h while at least six studs below the target; descent, rise and ram remain capped at 100 km/h. Noclip disables local CanTouch as well as collisions on car and driver, restoring originals on cleanup. Car Lift support collisions turn off while auto ram runs to avoid sweeping a solid platform through other players.

Local tests cover knocked filtering, hop distance, single-hop behavior, speed bounds and touch restoration. Terrain depth remains estimated; live server behavior and prevention of server-created attachments are unverified.

Nearest eligible target is rescanned every quarter-second from the local character position, with car position fallback. A timed-out target is excluded for three seconds rather than indefinitely.

Targets below detected terrain/natural ground surfaces are excluded using a cached downward surface check. Indoor roofs are not classified as ground solely for being overhead. This is a surface heuristic with a 48-stud probe range, so custom maps can require additional ground recognition.
