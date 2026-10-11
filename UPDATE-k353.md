# Rift k353

Fixed independently dragged categories disappearing at the menu boundary across supported games. Categories now live in a separate unclipped frame, while the horizontal scrollbar moves their positions and preserves individual offsets.

Validation: shared menu regression tests cover unclipped parenting and horizontal scroll synchronization; full local suite and compilation. Live Roblox appearance has not been verified.

Car Kill All now skips seated players and abandons a target after three seconds, choosing a different eligible player. With no alternative it waits. Local regression tests cover both rules.
