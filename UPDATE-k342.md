# RIFT UPDATE — k342

- Added Cold War → Movement → Car Noclip.
- Disables collisions on the vehicle currently being driven.
- Records each part's original setting and restores it on disable or seat exit.
- Handles vehicle parts added or removed while enabled.
- Excludes passenger character models from collision changes.
- Restores collisions on death, game switching and unload.
- Reuses native/custom driver-seat detection; no workspace-wide scans.
- Local regression tests passed. Live server replication remains unverified.
