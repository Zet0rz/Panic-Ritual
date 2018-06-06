
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
				cur = cur + (v.DemonChance or 1)
				if cur > ran then
					picked[v] = true
					total = total - (v.DemonChance or 1)
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

function GM:RestartRound()
	self.RoundState = ROUND_INIT

	game.CleanUpMap()

	local players = player.GetAll()
	local demons = PickWeightedRandomPlayers(players, 1) -- Pick 1 weighted random demon

	local maindemon
	for k,v in pairs(players) do
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

	self.RoundState = ROUND_PREPARE
end