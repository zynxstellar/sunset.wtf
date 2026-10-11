# RIFT UPDATE — k350

- Car Lift now follows directly beneath wheel bottoms during flight, driving and falling.
- Removed frozen-height behavior and the old gap/follow-height controls.
- Handles wheel rotation and suspension movement, including wheels added or removed while active.
- Uses vehicle lower bounds when wheel parts cannot be identified.
- Uses one support platform, with wheel references cached per vehicle and cleaned up on disable, seat exit, death and unload.
- Local regression checks passed. This local platform does not guarantee server grounding or anti-cheat acceptance.
