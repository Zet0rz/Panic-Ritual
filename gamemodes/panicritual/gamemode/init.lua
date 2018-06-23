AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("player_class.lua")

include("shared.lua")
include("player_class.lua")
include("sv_player.lua")
include("sv_round.lua")

function GM:PlayerInitialSpawn(ply)
	self:RestartRound()
	player_manager.SetPlayerClass(ply, "player_ritual_base")
end

function GM:PlayerSpawn(ply)
	ply:SetupHands()
	if ply:IsHuman() then ply:Give("ritual_human") end
end

function GM:PlayerSetHandsModel( ply, ent )

	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end

end