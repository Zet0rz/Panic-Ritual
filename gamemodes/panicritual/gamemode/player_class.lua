DEFINE_BASECLASS( "player_default" )

local PLAYER = {}
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

function PLAYER:SetupDataTables()

end

function PLAYER:Loadout()

end

player_manager.RegisterClass( "player_ritual_base", PLAYER, "player_default" )

--DEFINE_BASECLASS( "player_ritual_base" )

------------------------- Humans
local HUMANS = {}

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
function HUMANS:Spawn()
	self.Player:SetModel(humans[math.random(#humans)])
end
player_manager.RegisterClass( "player_ritual_human", HUMANS, "player_ritual_base" )

-------------------------- Demons
local DEMONS = {}

local demon = "models/player/group01/male_09.mdl" -- Replace this
function DEMONS:Spawn()
	self.Player:SetModel(demon)
end

player_manager.RegisterClass( "player_ritual_demon", DEMONS, "player_ritual_base" )