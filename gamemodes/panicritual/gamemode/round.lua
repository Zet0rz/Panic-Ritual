ROUND_INIT = 0
ROUND_PREPARE = 1
ROUND_ONGOING = 2
ROUND_POST = 3
local hooks = {
	[ROUND_INIT] = "Ritual_RoundInit",
	[ROUND_PREPARE] = "Ritual_RoundPrepare",
	[ROUND_ONGOING] = "Ritual_RoundBegin",
	[ROUND_POST] = "Ritual_RoundPost",
}

if SERVER then
	-- CONFIG VARIABLES
	local total_circles = 3 -- Demons place 3 circles
	local total_circle_charge = 2 -- Runners need to bring the doll past 2 other circles
	local required_circles = 2 -- Complete 2 circles to unlock weapons
	local postroundtime = 5

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

	GM.RoundState = ROUND_INIT

	util.AddNetworkString("Ritual_RoundState")
	function GM:SetRoundState(state)
		self.RoundState = state
		net.Start("Ritual_RoundState")
			net.WriteUInt(state, 2)
		net.Broadcast()
		hook.Run(hooks[state])
	end

	-- Sync to players joining mid-game
	hook.Add("PlayerInitialSpawn", "Ritual_RoundSync", function(ply)
		net.Start("Ritual_RoundState")
			net.WriteUInt(GAMEMODE.RoundState, 2)
		net.Send(ply)
	end)

	local numcircles = 0
	local completedcircles = 0
	local circles = {}

	function GM:RestartRound()
		hook.Remove("Think", "Ritual_PostRound") -- Just in case of manual restart
		self:SetRoundState(ROUND_INIT)

		game.CleanUpMap()

		local players = player.GetAll()
		local demons = PickWeightedRandomPlayers(players, 1) -- Pick 1 weighted random demon

		local maindemon
		for k,v in pairs(players) do
			v:StripWeapons()
			if demons[v] then
				v:Spawn()
				v:SetDemon()
				v.DemonChance = 1
			else
				v:Spawn()
				v:SetHuman()
				v.DemonChance = v.DemonChance and v.DemonChance + 1 or 1
			end
		end

		numcircles = 0
		completedcircles = 0
		circles = {}
		self:SetRoundState(ROUND_PREPARE)
	end

	local function StartMainPhase()
		for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
			v:StripWeapon("ritual_demon_circles")
			v:Give("ritual_demon")
		end

		for k,v in pairs(circles) do
			v:Reset()
		end

		GAMEMODE:SetRoundState(ROUND_ONGOING)
	end

	local function SpaceForCicle(pos, ang)
		-- Some logic to check if there's space for the circle, and if so, where to place it
		return pos,ang
	end

	function GM:PlaceRitualCircle(pos, ang)
		local p,a = SpaceForCicle(pos,ang)
		if not p then return end

		local circle = ents.Create("ritual_circle")
		circle:SetProgressRequirement(total_circle_charge <= 0 and total_circles + total_circle_charge or total_circle_charge)
		circle:SetPos(p)
		circle:SetAngles(a)
		circle:Spawn()

		local e = EffectData()
		e:SetOrigin(p)
		e:SetAngles(a)
		e:SetRadius(100) -- Size of bottom circulation
		e:SetScale(100) -- Height of pillar
		e:SetMagnitude(10) -- "thickness" of particles (amount/scale)
		e:SetFlags(TEAM_DEMONS) -- Only show for demons
		util.Effect("ritual_circlesummon", e, true, true)

		numcircles = numcircles + 1
		circles[numcircles] = circle
		if numcircles >= total_circles then
			StartMainPhase()
		end

		return true -- It was placed correctly
	end

	function GM:PostRound()
		self:SetRoundState(ROUND_POST)
		local time = CurTime() + postroundtime
		hook.Add("Think", "Ritual_PostRound", function()
			if CurTime() > time then
				self:RestartRound()
				hook.Remove("Think", "Ritual_PostRound")
			end
		end)
	end

	util.AddNetworkString("Ritual_TeamWin")
	function GM:RoundWin(t)
		net.Start("Ritual_TeamWin")
			net.WriteUInt(t or 0, 2)
		net.Broadcast()

		hook.Run("Ritual_TeamWin", t or 0)

		self:PostRound()
	end

	function GM:Ritual_CircleCompleted(circle, ply)
		completedcircles = completedcircles + 1
	end
	function GM:GetCompletedCircles() return completedcircles end

	local function CheckTeams()
		local humans = team.NumPlayers(TEAM_HUMANS) < 1
		local demons = team.NumPlayers(TEAM_DEMONS) < 1

		if humans and demons then -- Both under 1
			GAMEMODE:RoundWin() -- No winners :(
		elseif demons then -- Not both under, but demons under
			GAMEMODE:RoundWin(TEAM_HUMANS)
		elseif humans then -- Not both under, but humans under
			GAMEMODE:RoundWin(TEAM_DEMONS)
		end
	end
	hook.Add("PostPlayerDeath", "Ritual_RoundDeath", function(ply) CheckTeams() end)
	hook.Add("EntityRemoved", "Ritual_PlayerDisconnect", function(ply)
		if ply:IsPlayer() then CheckTeams() end
	end)

	hook.Add("Ritual_TeamWin", "Ritual_TempWinIndicator", function(t)
		PrintMessage(HUD_PRINTTALK, t > 0 and team.GetName(t) .. " wins!" or "Everyone's dead!")
	end)

	hook.Add("PlayerDeath", "Ritual_PlayerToSpectate", function(ply)
		ply:SetTeam(TEAM_SPECTATORS)
	end)

	function GM:Ritual_CanPickUpDoll(doll, wep, caller)
		print("This is run", doll.RitualCircle.Completed, doll:GetCharged())
		return not doll.RitualCircle.Completed or doll:GetCharged()
	end
	--[[function GM:Ritual_DollPickedUp(doll, wep, caller)
		wep:SetCharged(doll.RitualCircle.Completed)
	end]]

	function GM:Ritual_CanChargeDoll(doll, wep, caller)
		return doll.RitualCircle.Completed and completedcircles >= required_circles
	end
end

if CLIENT then
	net.Receive("Ritual_RoundState", function()
		GAMEMODE.RoundState = net.ReadUInt(2)
		hook.Run(hooks[GAMEMODE.RoundState])
	end)

	net.Receive("Ritual_TeamWin", function()
		local t = net.ReadUInt(2)
		hook.Run("Ritual_TeamWin", t)
	end)
end