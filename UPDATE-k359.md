# Rift k359

Added Cold War Movement > Car Anti Aim. Driver-only angular constraint tumbles the car around three axes with a 1-12 rad/s speed control. Works without Car Fly; when both are enabled, Car Fly releases its upright orientation constraint. Cleanup on disable, seat loss, vehicle change, death, wrong game, errors and unload.

Local tests cover constraint reuse, direction changes, speed bounds and cleanup. Live replication and hit avoidance unverified; no guarantee of avoiding hits.
