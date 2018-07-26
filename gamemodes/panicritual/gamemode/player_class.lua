DEFINE_BASECLASS( "player_default" )

local PLAYER = {}
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

function PLAYER:SetupDataTables()
	
end

function PLAYER:Loadout()

end

function PLAYER:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

--[[function PLAYER:CalcView(view)
	local ply = self.Player
	if IsValid(ply:GetMauling()) then
		print("Mauling someone")
	elseif IsValid(ply:GetMauled()) then
		
	end
end]]

player_manager.RegisterClass( "player_ritual_base", PLAYER, "player_default" )

local HUMANS = {}
function HUMANS:SetupDataTables()
	
end

function HUMANS:Loadout()
	self.Player:Give("ritual_human")
end

local humans = { -- the models
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/male_08.mdl",
	"models/player/group01/male_09.mdl"
}
function HUMANS:Init()
	self.Player:SetModel(humans[math.random(#humans)])
end

function HUMANS:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

player_manager.RegisterClass( "player_ritual_human", HUMANS, "player_ritual_base" )

local DEMONS = {}
DEMONS.WalkSpeed 			= 200
DEMONS.RunSpeed				= 400

function DEMONS:SetupDataTables()
	
end

function DEMONS:Loadout()
	self.Player:Give("ritual_demon_possess")
end

local demonmodel = "models/player/keeper_red_hooded.mdl"
player_manager.AddValidModel("keeper_red_hooded", "models/player/keeper_red_hooded.mdl")
player_manager.AddValidHands("keeper_red_hooded", "models/player/c_arms_keeper_red_hooded.mdl", 0, "00000000")

local afktime = 60 -- seconds of not pressing any buttons to AFK
local afkwarn = 30
function DEMONS:Init()
	self.Player:SetModel(demonmodel)
end

function DEMONS:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

if not ConVarExists("ritual_afktime") then CreateConVar("ritual_afktime", 60, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "The amount of time with Demons no moving to slay them. Set to 0 to disable.") end
local time = GetConVar("ritual_afktime")

function DEMONS:StartMove(mv, cmd)
	if SERVER and self.Player:Alive() then
		local ct = CurTime()
		local t = time:GetInt()
		if t > 0 then
			if not self.AFKTime then self.AFKTime = CurTime() + t end
			if not self.AFKWarn then self.AFKWarn = CurTime() + t*0.5 end

			if cmd:GetButtons() > 0 then self.AFKTime = ct + t self.AFKWarn = ct + t*0.5 end
			if ct > self.AFKTime then
				self.AFKTime = nil
				self.Player:SetTeam(TEAM_SPECTATORS)
				self.Player:Kill()
				PrintMessage(HUD_PRINTTALK, self.Player:Nick() .. " was slain for being AFK!")
			end
			if self.AFKWarn and ct > self.AFKWarn then
				self.Player:SendHint("afk")
				self.AFKWarn = nil
			end
		end
	end
end

player_manager.RegisterClass( "player_ritual_demon", DEMONS, "player_ritual_base" )