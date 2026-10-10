# RIFT UPDATE — k341

- Added Cold War → Movement → Car Lift.
- Places one solid blue platform beneath the vehicle and raises it while enabled.
- Added Rise Speed, from 1–12 studs/s.
- Follows the car horizontally and limits overlap if the car stops rising.
- Pauses lift movement while menus or text inputs are active.
- Temporarily takes priority over Car Fly's velocity constraints.
- Removes the platform on disable, seat exit, death, game switch or unload.
- Local tests passed; live collision behavior and server replication remain unverified.
