# RIFT UPDATE — k345

- Changed Car Lift into a catch platform instead of an automatically rising plate.
- Car Lift and Car Fly can now run together.
- Follow Flight Height keeps the platform below the car during flight.
- Turning Car Fly off leaves the platform at its last height for landing and driving.
- The platform continues following the car horizontally.
- Added Platform Gap and removed Rise Speed.
- Separated flight constraint cleanup from platform cleanup.
- Local tests passed for simultaneous flight/platform, frozen landing height, horizontal following and cleanup.
- No Fall is pending inspection of the game's fall-damage handling; it is not included in this build.
