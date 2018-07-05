include("shared.lua" )
include("cl_jumpscares.lua")
include("player_meta.lua")
include("round.lua")
include("animations.lua")
include("antistuck.lua")

--include("demonmaul.lua")
--include("demonsoulsiphon.lua")
--include("demonpossess.lua")

include("horroraspects.lua")
include("spectating.lua")
include("screamandshout.lua")

-- Sound effects used by the gamemode
util.PrecacheSound("sound/ambient/fire/mtov_flame2.wav") -- Reset doll burn
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing1.wav") -- Doll whisper
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing2.wav") -- Doll whisper 2 (shorter)