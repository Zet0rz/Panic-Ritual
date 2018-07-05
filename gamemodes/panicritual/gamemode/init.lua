AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("player_class.lua")
AddCSLuaFile("cl_jumpscares.lua")
AddCSLuaFile("player_meta.lua")
AddCSLuaFile("animations.lua")
AddCSLuaFile("antistuck.lua")

include("shared.lua")
include("player_class.lua")
include("player_meta.lua")
include("sv_round.lua")
include("animations.lua")
include("antistuck.lua")

-- Demon maul, pounce attack
--AddCSLuaFile("demonmaul.lua")
--include("demonmaul.lua")

-- Demon soul siphon, walked attack
--AddCSLuaFile("demonsoulsiphon.lua")
--include("demonsoulsiphon.lua")

function GM:PlayerInitialSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_ritual_base")
	self:RestartRound()
end

function GM:PlayerSpawn(ply)
	ply:SetupHands()
	player_manager.RunClass(ply, "Loadout")
	--if ply:IsHuman() then ply:Give("ritual_human") end
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