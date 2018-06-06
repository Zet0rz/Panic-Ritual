AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("player_class.lua")

include("shared.lua")
include("player_class.lua")
include("sv_player.lua")
include("sv_round.lua")

function GM:PlayerInitialSpawn(ply)
	self:RestartRound()
end