AddCSLuaFile("shared.lua")
AddCSLuaFile("hints.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("player_class.lua")
AddCSLuaFile("cl_jumpscares.lua")
AddCSLuaFile("player_meta.lua")
AddCSLuaFile("round.lua")
AddCSLuaFile("antistuck.lua")
AddCSLuaFile("screamandshout.lua")
AddCSLuaFile("cl_hud.lua")

include("shared.lua")
include("hints.lua")
include("round.lua")
include("player_class.lua")
include("player_meta.lua")
include("antistuck.lua")
include("screamandshout.lua")

AddCSLuaFile("horroraspects.lua")
include("horroraspects.lua")

--resource.AddWorkshop("1455501072")
resource.AddFile("resource/fonts/octobercrow.ttf")
resource.AddFile("resource/fonts/hauntaoe.ttf")

RunConsoleCommand("sv_skyname", "painted")
hook.Add("InitPostEntity", "Ritual_RemoveSkyPaint", function()
	local sky = ents.FindByClass("env_skypaint")[1]
	if not IsValid(sky) then
		sky = ents.Create("env_skypaint")
		sky:Spawn()
	end
	GAMEMODE.SkyPaint = sky
	GAMEMODE.SkyTopColor = sky:GetTopColor()
	GAMEMODE.SkyBottomColor = sky:GetBottomColor()
	GAMEMODE.SkyDuskColor = sky:GetDuskColor()
	GAMEMODE.SkyDuskIntensity = sky:GetDuskIntensity()
	GAMEMODE.SkyDuskScale = sky:GetDuskScale()
	GAMEMODE.SkySunNormal = sky:GetSunNormal()
	sky:SetDrawStars(false)
end)

function GM:PlayerInitialSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_ritual_base")
	--ply:SetShouldServerRagdoll(true)
	if player.GetCount() == 2 then
		self:RestartRound()
	end
end

function GM:PlayerSpawn(ply)
	--ply:SetupHands()
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