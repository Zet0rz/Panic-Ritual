local PLAYER = FindMetaTable("Player")

local malesoundpack = {
	RoundBeginTalk = {
		"vo/npc/male01/question02.wav",
		"vo/npc/male01/question04.wav",
		"vo/npc/male01/question05.wav",
		"vo/npc/male01/question11.wav",
		"vo/npc/male01/question12.wav",
		"vo/npc/male01/question16.wav",
		"vo/npc/male01/question20.wav",
		"vo/npc/male01/question21.wav",
		"vo/npc/male01/question25.wav",
		"vo/npc/male01/gordead_ques06.wav",
		"vo/npc/male01/gordead_ques10.wav",
		"vo/npc/male01/gordead_ques13.wav",
		"vo/npc/male01/gordead_ques14.wav",
		"vo/npc/male01/gordead_ques16.wav",
		"vo/npc/male01/doingsomething.wav",
		"vo/npc/male01/waitingsomebody.wav",
		"vo/npc/male01/gordead_ans01.wav",
		"vo/npc/male01/gordead_ans02.wav",
		"vo/npc/male01/gordead_ans06.wav",
		"vo/npc/male01/gordead_ans14.wav",
		"vo/npc/male01/gordead_ans15.wav",
	},
	RoundBeginResponse = {
		"vo/npc/male01/answer18.wav",
		"vo/npc/male01/answer29.wav",
		"vo/npc/male01/answer36.wav",
		"vo/npc/male01/gordead_ans03.wav",
		"vo/npc/male01/gordead_ans04.wav",
		"vo/npc/male01/gordead_ans05.wav",
		"vo/npc/male01/gordead_ans09.wav",
		"vo/npc/male01/gordead_ans10.wav",
		"vo/npc/male01/gordead_ans11.wav",
		"vo/npc/male01/gordead_ans12.wav",
		"vo/npc/male01/gordead_ans13.wav",
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
	RoundBeginTalk = {
		"vo/npc/female01/question02.wav",
		"vo/npc/female01/question04.wav",
		"vo/npc/female01/question05.wav",
		"vo/npc/female01/question11.wav",
		"vo/npc/female01/question12.wav",
		"vo/npc/female01/question16.wav",
		"vo/npc/female01/question20.wav",
		"vo/npc/female01/question21.wav",
		"vo/npc/female01/question25.wav",
		"vo/npc/female01/gordead_ques06.wav",
		"vo/npc/female01/gordead_ques10.wav",
		"vo/npc/female01/gordead_ques13.wav",
		"vo/npc/female01/gordead_ques14.wav",
		"vo/npc/female01/gordead_ques16.wav",
		"vo/npc/female01/doingsomething.wav",
		"vo/npc/female01/waitingsomebody.wav",
		"vo/npc/female01/gordead_ans01.wav",
		"vo/npc/female01/gordead_ans02.wav",
		"vo/npc/female01/gordead_ans06.wav",
		"vo/npc/female01/gordead_ans14.wav",
		"vo/npc/female01/gordead_ans15.wav",
	},
	RoundBeginResponse = {
		"vo/npc/female01/answer18.wav",
		"vo/npc/female01/answer29.wav",
		"vo/npc/female01/answer36.wav",
		"vo/npc/female01/gordead_ans03.wav",
		"vo/npc/female01/gordead_ans04.wav",
		"vo/npc/female01/gordead_ans05.wav",
		"vo/npc/female01/gordead_ans09.wav",
		"vo/npc/female01/gordead_ans10.wav",
		"vo/npc/female01/gordead_ans11.wav",
		"vo/npc/female01/gordead_ans12.wav",
		"vo/npc/female01/gordead_ans13.wav",
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
	HurtPitch = {75,150},
	Death = {
		"panicritual/demon_death.wav",
	},
	DeathPitch = {75,125},
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
		self:EmitSound(s, 75, sounds.DeathPitch and math.random(unpack(sounds.DeathPitch)) or 100)
		return SoundDuration(s), s
	end
end

function PLAYER:HurtScream()
	local sounds = models[self:GetModel()]
	if sounds and sounds.Hurt then
		local s = sounds.Hurt[math.random(#sounds.Hurt)]
		self:EmitSound(s, 75, sounds.HurtPitch and math.random(unpack(sounds.HurtPitch)) or 100)
		return SoundDuration(s), s
	end
end

function PLAYER:Talk()
	local sounds = models[self:GetModel()]
	if sounds and sounds.RoundBeginTalk then
		local s = sounds.RoundBeginTalk[math.random(#sounds.RoundBeginTalk)]
		self:EmitSound(s, 75, 100)
		return SoundDuration(s), s
	end
end

function PLAYER:Respond()
	local sounds = models[self:GetModel()]
	if sounds and sounds.RoundBeginResponse then
		local s = sounds.RoundBeginResponse[math.random(#sounds.RoundBeginResponse)]
		self:EmitSound(s, 75, 100)
		return SoundDuration(s), s
	end
end

if SERVER then
	-- Enabling with round
	if not ConVarExists("ritual_roundtalk") then CreateConVar("ritual_roundtalk", 1, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Enables Humans talking at the start of the round.") end

	local delay1 = 3
	local delay2 = 0.5 -- after first finishes talking
	local maxdistance = 500 -- Distance to initial player for responding player
	hook.Add("Ritual_RoundPrepare", "Ritual_RoundBeginTalk", function()
		if GetConVar("ritual_roundtalk"):GetBool() then
			timer.Simple(delay1, function()
				local humans = team.GetPlayers(TEAM_HUMANS)
				if #humans > 0 then
					local ply = humans[math.random(#humans)]
					if ply:Alive() then
						local d = ply:Talk()
						if d then
							timer.Simple(d + delay2, function()
								local possible = {}
								local pos = ply:GetPos()
								for k,v in pairs(humans) do
									if v:Alive() and v ~= ply then
										local dist = v:GetPos():Distance(pos)
										if dist <= maxdistance then
											table.insert(possible, v)
										end
									end
								end
								
								if #possible > 0 then
									local ply2 = possible[math.random(#possible)]
									ply2:Respond()
								end
							end)
						end
					end
				end
			end)
		end
	end)
end