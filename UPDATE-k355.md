# Rift k355

Car Kill All flies toward each target using the existing Car Fly velocity control and Ram Speed setting. Removed all direct car position writes and teleport timing state from the module. Flight heading follows the approach direction. Ten-second target switching and vehicle exclusion remain.

Local regression suite checks reject any car position/CFrame writes during initial approach and target switching. Compilation passed; live gameplay unverified.
