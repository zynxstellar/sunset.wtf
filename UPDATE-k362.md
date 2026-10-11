# Rift k362

Added the supplied client for Arsenal and Rivals as arsenal-rivals.lua. The main loader routes those games to this imported client and retains the current BedWars, Cold War and Project Delta clients. Arsenal displays its own name. Added a startup game restriction, updated the imported build identifier and gave its local source/reinjection files separate names. Other supplied gameplay/UI code retained.

Validation: both supplied wrapper and embedded source compile; loader tests cover Arsenal, Rivals places/universe, wrong source rejection and retained dedicated routes. Live Roblox runtime and imported feature behavior unverified.
