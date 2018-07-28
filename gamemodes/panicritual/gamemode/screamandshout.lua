
print("screams")

local PLAYER = FindMetaTable("Player")

local malesoundpack = {
	RoundBegin = {
		"vo/npc/male01/answer18.wav",
		"vo/npc/male01/answer29.wav",
		"vo/npc/male01/answer36.wav",
		"vo/npc/male01/gordead_ans01.wav",
		"vo/npc/male01/gordead_ans02.wav",
		"vo/npc/male01/gordead_ans03.wav",
		"vo/npc/male01/gordead_ans04.wav",
		"vo/npc/male01/gordead_ans05.wav",
		"vo/npc/male01/gordead_ans06.wav",
		"vo/npc/male01/gordead_ans09.wav",
		"vo/npc/male01/gordead_ans10.wav",
		"vo/npc/male01/gordead_ans11.wav",
		"vo/npc/male01/gordead_ans12.wav",
		"vo/npc/male01/gordead_ans13.wav",
		"vo/npc/male01/gordead_ans14.wav",
		"vo/npc/male01/gordead_ans15.wav",
		"vo/npc/male01/question02.wav",
		"vo/npc/male01/question04.wav",
		"vo/npc/male01/question05.wav",
		"vo/npc/male01/question11.wav",
		"vo/npc/male01/question12.wav",
		"vo/npc/male01/question16.wav",
		"vo/npc/male01/question20.wav",
		"vo/npc/male01/question21.wav",
		"vo/npc/male01/question25.wav",
		"vo/npc/male01/gordead_ques13.wav",
		"vo/npc/male01/gordead_ques14.wav",
		"vo/npc/male01/gordead_ques16.wav",
		"vo/npc/male01/doingsomething.wav",
		"vo/npc/male01/waitingsomebody.wav",
	},
	Hurt = {
		"vo/npc/male01/ow01.wav",
		"vo/npc/male01/ow02.wav",
		"vo/npc/male01/pain01.wav",
		"vo/npc/male01/pain02.wav",
		"vo/npc/male01/pain03.wav",
		"vo/npc/male01/pain04.wav",
		"vo/npc/male01/pain05.wav",
	},
	Death = {
		"vo/npc/male01/pain06.wav",
		"vo/npc/male01/pain07.wav",
		"vo/npc/male01/pain09.wav",
		"vo/npc/male01/no02.wav",
	},
}

local femalesoundpack = {
	RoundBegin = {
		"vo/npc/female01/answer18.wav",
		"vo/npc/female01/answer29.wav",
		"vo/npc/female01/answer36.wav",
		"vo/npc/female01/gordead_ans01.wav",
		"vo/npc/female01/gordead_ans02.wav",
		"vo/npc/female01/gordead_ans03.wav",
		"vo/npc/female01/gordead_ans04.wav",
		"vo/npc/female01/gordead_ans05.wav",
		"vo/npc/female01/gordead_ans06.wav",
		"vo/npc/female01/gordead_ans09.wav",
		"vo/npc/female01/gordead_ans10.wav",
		"vo/npc/female01/gordead_ans11.wav",
		"vo/npc/female01/gordead_ans12.wav",
		"vo/npc/female01/gordead_ans13.wav",
		"vo/npc/female01/gordead_ans14.wav",
		"vo/npc/female01/gordead_ans15.wav",
		"vo/npc/female01/question02.wav",
		"vo/npc/female01/question04.wav",
		"vo/npc/female01/question05.wav",
		"vo/npc/female01/question11.wav",
		"vo/npc/female01/question12.wav",
		"vo/npc/female01/question16.wav",
		"vo/npc/female01/question20.wav",
		"vo/npc/female01/question21.wav",
		"vo/npc/female01/question25.wav",
		"vo/npc/female01/gordead_ques13.wav",
		"vo/npc/female01/gordead_ques14.wav",
		"vo/npc/female01/gordead_ques16.wav",
		"vo/npc/female01/doingsomething.wav",
		"vo/npc/female01/waitingsomebody.wav",
	},
	Hurt = {
		"vo/npc/male01/ow01.wav",
		"vo/npc/male01/ow02.wav",
		"vo/npc/female01/pain02.wav",
		"vo/npc/female01/pain03.wav",
	},
	Death = {
		"vo/npc/female01/pain01.wav",
		"vo/npc/female01/pain04.wav",
		"vo/npc/female01/pain05.wav",
		"vo/npc/female01/pain08.wav",
	},
}

local demonsoundpack = {
	Hurt = {
		"panicritual/demon_damage1.wav",
		"panicritual/demon_damage2.wav",
	},
	Death = {
		"panicritual/demon_death.wav",
	},
}

local models = {
	["models/player/group01/female_01.mdl"] = femalesoundpack,
	["models/player/group01/female_02.mdl"] = femalesoundpack,
	["models/player/group01/female_03.mdl"] = femalesoundpack,
	["models/player/group01/female_04.mdl"] = femalesoundpack,
	["models/player/group01/female_05.mdl"] = femalesoundpack,
	["models/player/group01/female_06.mdl"] = femalesoundpack,
	["models/player/group01/male_01.mdl"] = malesoundpack,
	["models/player/group01/male_02.mdl"] = malesoundpack,
	["models/player/group01/male_03.mdl"] = malesoundpack,
	["models/player/group01/male_04.mdl"] = malesoundpack,
	["models/player/group01/male_05.mdl"] = malesoundpack,
	["models/player/group01/male_06.mdl"] = malesoundpack,
	["models/player/group01/male_07.mdl"] = malesoundpack,
	["models/player/group01/male_08.mdl"] = malesoundpack,
	["models/player/group01/male_09.mdl"] = malesoundpack,
	["models/player/panicritual/keeper_hooded_red.mdl"] = demonsoundpack,
	["models/player/panicritual/keeper_hooded_black.mdl"] = demonsoundpack,
}

function PLAYER:DeathScream()
	local sounds = models[self:GetModel()]
	if sounds and sounds.Death then
		local s = sounds.Death[math.random(#sounds.Death)]
		self:EmitSound(s, 75, 100)
	end
end

function PLAYER:HurtScream()
	local sounds = models[self:GetModel()]
	if sounds and sounds.Hurt then
		local s = sounds.Hurt[math.random(#sounds.Hurt)]
		self:EmitSound(s, 75, 100)
	end
end

function PLAYER:Talk()
	local sounds = models[self:GetModel()]
	if sounds and sounds.RoundBegin then
		local s = sounds.RoundBegin[math.random(#sounds.RoundBegin)]
		self:EmitSound(s, 75, 100)
	end
end