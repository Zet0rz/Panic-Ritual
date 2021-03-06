include("shared.lua" )
include("hints.lua")
include("cl_jumpscares.lua")
include("player_meta.lua")
include("player_class.lua")
include("round.lua")
include("antistuck.lua")
include("cl_hud.lua")

include("horroraspects.lua")
include("screamandshout.lua")

-- Sound effects used by the gamemode
util.PrecacheSound("sound/ambient/fire/mtov_flame2.wav") -- Reset doll burn
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing1.wav") -- Doll whisper
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing2.wav") -- Doll whisper 2 (shorter)