
-- CONFIG VARIABLES
local total_circles = 3 -- Demons place 3 circles
local total_circle_charge = 2 -- Runners need to bring the doll past 2 other circles

local function PickWeightedRandomPlayers(players, num)
	local total = 0
	for k,v in pairs(players) do
		total = total + (v.DemonChance or 1)
	end

	local picked = {}
	for i = 1, num do
		local ran = math.random(total - 1)
		local cur = 0
		for k,v in pairs(players) do
			if not picked[v] then
				local chance = (v.DemonChance or 1)
				cur = cur + chance
				if cur >= ran then
					picked[v] = true
					total = total - chance
					break
				end
			end
		end
	end

	return picked
end

ROUND_INIT = 0
ROUND_PREPARE = 1
ROUND_ONGOING = 2
ROUND_POST = 3

GM.RoundState = ROUND_INIT

local numcircles = 0
local circles = {}

function GM:RestartRound()
	self.RoundState = ROUND_INIT

	game.CleanUpMap()

	local players = player.GetAll()
	local demons = PickWeightedRandomPlayers(players, 1) -- Pick 1 weighted random demon

	local maindemon
	for k,v in pairs(players) do
		v:StripWeapons()
		if demons[v] then
			v:SetDemon()
			v:Spawn()
			v:Give("ritual_demon_circles")
			v.DemonChance = 1
		else
			v:SetHuman()
			v:Spawn()
			v:Give("ritual_human")
			v.DemonChance = v.DemonChance and v.DemonChance + 1 or 1
		end
	end

	numcircles = 0
	circles = {}
	self.RoundState = ROUND_PREPARE
end

local function StartMainPhase()
	for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
		v:StripWeapon("ritual_demon_circles")
		v:Give("ritual_demon")
	end

	for k,v in pairs(circles) do
		v:Reset()
	end
end

function GM:PlaceRitualCircle(pos, ang)
	local circle = ents.Create("ritual_circle")
	circle:SetProgressRequirement(total_circle_charge <= 0 and total_circles + total_circle_charge or total_circle_charge)
	circle:SetPos(pos)
	circle:SetAngles(ang)
	circle:Spawn()

	numcircles = numcircles + 1
	circles[numcircles] = circle
	if numcircles >= total_circles then
		StartMainPhase()
	end
end