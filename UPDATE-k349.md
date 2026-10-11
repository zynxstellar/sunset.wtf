# RIFT UPDATE — k349

- Every category column can be dragged independently in all four supported games.
- The menu title/background can still move the group; buttons, text fields and scrollbars keep their own input.
- Category positions are saved with HUD positions; drag ownership prevents simultaneous movement of the category and menu.
- Replaced Cold War Car Fling spin with a non-spinning ram boost.
- Added Ram Speed and Contact Range controls; removed Spin Speed and angular constraints.
- Car Noclip stays enabled: original car collisions return near other vehicles while moving, and noclip resumes outside contact range.
- Contact temporarily also allows scenery collisions. Only the local driven car is modified; launching another player's car is not verified and depends on game physics/network ownership.
- Local regression checks passed for category drag ownership, close/unload cleanup, contact boost, no spin, noclip coexistence and collision restoration.
