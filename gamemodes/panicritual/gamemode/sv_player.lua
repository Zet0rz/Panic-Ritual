local PLAYER = FindMetaTable("Player")

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

function PLAYER:SetHuman()
	self:SetTeam(TEAM_HUMANS)

	self:Give("ritual_human")
	self:SetModel(humans[math.random(#humans)])
end

local demon = "models/player/group01/male_09.mdl" -- Replace this
function PLAYER:SetDemon()
	self:SetTeam(TEAM_DEMONS)
	self:SetModel(demon)
end

function PLAYER:IsHuman() return self:Team() == TEAM_HUMANS end
function PLAYER:IsDemon() return self:Team() == TEAM_DEMONS end