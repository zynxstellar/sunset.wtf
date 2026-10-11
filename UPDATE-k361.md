# Rift k361

Includes k360 pursuit changes. Corrected underground route depth to use target height instead of subtracting more depth from an already-low car. Travel height stays at least 64 studs above workspace FallenPartsDestroyHeight. Car Fly requests upward movement when a live driven car is below that margin.

Local tests cover recovery direction and destruction-height velocity guard. Cannot recover a vehicle already destroyed or override server removal, kicks or bans.
