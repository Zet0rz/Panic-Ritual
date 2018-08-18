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

function GM:PlayerCanHearPlayersVoice(listener, talker)
	local alltalk = GetConVar("sv_alltalk"):GetInt()
	if alltalk > 0 then return true, alltalk == 2 end -- Alltalk is on, anyone can hear anyone
	-- Alltalk is 2 and it will be 3D

	local lteam = listener:Team()
	local tteam = talker:Team()
	-- Living Demons can only be heard by other demons, no 3D
	if tteam == TEAM_DEMONS and talker:Alive() then return lteam == TEAM_DEMONS, false end
	
	-- Dead people can be heard by other dead players, no 3D
	if not talker:Alive() then return not listener:Alive(), false end
	
	-- Everyone else can be heard by anyone, but in 3D
	if lteam == TEAM_DEMONS then return talker:VisibleTo(listener), true end
	return true, true
end

-- These shouldn't really be changed, but they are fun to play with
if not ConVarExists("ritual_demon_count") then CreateConVar("ritual_demon_count", 1, {FCVAR_SERVER_CAN_EXECUTE}, "Sets the number of Demons. It is recommended to only be 1.") end