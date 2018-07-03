DEFINE_BASECLASS( "player_default" )

local PLAYER = {}
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

function PLAYER:SetupDataTables()
	
end

function PLAYER:Loadout()

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
	self.Player:NetworkVar("Entity", 0, "Mauled")
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

player_manager.RegisterClass( "player_ritual_human", HUMANS, "player_ritual_base" )

local DEMONS = {}
function DEMONS:SetupDataTables()
	self.Player:NetworkVar("Entity", 0, "Mauling")
	self.Player:NetworkVar("Bool", 0, "LeapCharging")
end

function DEMONS:Loadout()
	self.Player:Give("ritual_demon")
end

local demonmodel = "models/player/group01/male_09.mdl" -- Replace this
function DEMONS:Init()
	self.Player:SetModel(demonmodel)
end

function DEMONS:Move(mv)
	local ply = self.Player

	--[[if ply:GetLeapCharging() then
		print("Charging")
		local vel = mv:GetVelocity()
		mv:SetVelocity(vel*0.75)
	end]]

	if SERVER and ply:IsOnGround() and not ply.NextLeap then
		ply.NextLeap = CurTime() + 1
	end
end

player_manager.RegisterClass( "player_ritual_demon", DEMONS, "player_ritual_base" )