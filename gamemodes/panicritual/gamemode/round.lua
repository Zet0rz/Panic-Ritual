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
	local total_circle_charge = 3 -- Runners need to bring the doll past 3 circles - last always itself
	local required_circles = 2 -- Complete 2 circles to unlock weapons
	local postroundtime = 5

	local function PickWeightedRandomPlayers(players, num)
		local total = 0
		for k,v in pairs(players) do
			if not v.DemonChance then v.DemonChance = 1 end
			total = total + v.DemonChance
		end

		local picked = {}
		for i = 1, (num or 1) do
			local ran = math.random(total)
			local cur = 0
			for k,v in pairs(players) do
				if not picked[v] then
					cur = cur + v.DemonChance
					if cur >= ran then
						picked[v] = true
						total = total - v.DemonChance
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
				v:SetDemon()
				v:Spawn()
				v:SetNoCollidePlayers(true)
				v:DrawShadow(false)
				v.DemonChance = 1
			else
				v:SetHuman()
				v:Spawn()
				v:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				v:SetNoCollidePlayers(false)
				v:DrawShadow(true)
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
			local wep = v:GetActiveWeapon()
			if IsValid(wep) and wep.Fade then wep:Fade(2) end
			v:DrawShadow(true)
		end

		for k,v in pairs(circles) do
			v:Reset()
		end

		GAMEMODE:SetRoundState(ROUND_ONGOING)
	end

	local mins = Vector(-20,-20,1)
	local maxs = Vector(20,20,1)
	local closestdist = 500
	local function SpaceForCicle(pos, ang)
		-- Some logic to check if there's space for the circle, and if so, where to place it
		for k,v in pairs(ents.FindByClass("ritual_circle")) do
			local d = v:GetPos():Distance(pos)
			if d < closestdist then return end -- No can do if a circle is closer than this
		end

		local tr = util.TraceHull({
			start = pos + Vector(0,0,64),
			endpos = pos,
			maxs = maxs,
			mins = mins,
			--filter = ent,
			mask = MASK_NPCWORLDSTATIC,
		})
		if tr.Hit then return end

		local reqcharge = total_circle_charge <= 0 and total_circles + total_circle_charge or total_circle_charge
		local a = Angle(0, 360/reqcharge, 0)
		for i = 0, reqcharge - 1 do
			local p = a:Forward()*100
			p:Rotate(a*i)
			
			tr = util.TraceHull({
				start = p + pos + Vector(0,0,64),
				endpos = p + pos,
				maxs = maxs,
				mins = mins,
				--filter = ent,
				mask = MASK_NPCWORLDSTATIC,
			})
			if tr.Hit then return end
		end

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
		if GAMEMODE.RoundState == ROUND_POST then return end

		local humans,demons = true,true
		for k,v in pairs(team.GetPlayers(TEAM_HUMANS)) do
			if v:Alive() or v.RespawnTime then humans = false break end
		end
		for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
			if v:Alive() or v.RespawnTime then demons = false break end
		end

		if humans and demons then -- Both under 1
			GAMEMODE:RoundWin() -- No winners :(
		elseif demons then -- Not both under, but demons under
			GAMEMODE:RoundWin(TEAM_HUMANS)
		elseif humans then -- Not both under, but humans under
			GAMEMODE:RoundWin(TEAM_DEMONS)
		end
	end
	

	hook.Add("Ritual_TeamWin", "Ritual_TempWinIndicator", function(t)
		PrintMessage(HUD_PRINTTALK, t > 0 and team.GetName(t) .. " wins!" or "Everyone's dead!")
	end)

	function GM:Ritual_CanPickUpDoll(doll, wep, caller)
		print("This is run", doll.RitualCircle.Completed, doll:GetCharged())
		return not doll.RitualCircle:GetCompleted() or doll:GetCharged()
	end
	--[[function GM:Ritual_DollPickedUp(doll, wep, caller)
		wep:SetCharged(doll.RitualCircle.Completed)
	end]]

	function GM:Ritual_CanChargeDoll(doll, wep, caller)
		return doll.RitualCircle:GetCompleted() and completedcircles >= required_circles
	end

	-- Spectating system
	--[[function GM:PlayerDeath(ply)
		
	end]]
	local respawntime = 3
	function GM:PostPlayerDeath(ply)
		if GAMEMODE.RoundState == ROUND_PREPARE then
			ply.RespawnTime = CurTime() + respawntime
		else
			timer.Simple(1, function() ply:Spectate(OBS_MODE_ROAMING) end) -- Timer fixes ragdolls spawning in default pose
		end
		CheckTeams()
	end
	hook.Add("PlayerSpawn", "Ritual_StopSpectate", function(ply) ply:UnSpectate() end)

	-- Also handle for disconnecting players
	hook.Add("EntityRemoved", "Ritual_PlayerDisconnect", function(ply)
		if ply:IsPlayer() then CheckTeams() end
	end)

	local function CanSpectate(ply, target)
		return target:Alive() and (target:IsDemon() or target:IsHuman())
	end

	function GM:PlayerDeathThink(ply)
		if ply.RespawnTime then
			if CurTime() >= ply.RespawnTime then
				ply.RespawnTime = nil
				ply:Spawn()
				return true
			end
			return
		end

		-- No respawn on buttons >:(
		local mode = ply:GetObserverMode() == OBS_MODE_ROAMING
		if not ply.SpectateTarget then
			ply.SpectateTarget = team.GetPlayers(TEAM_DEMONS)[1] or team.GetPlayers(TEAM_HUMANS)[1] or ply
			ply:SpectateEntity(ply.SpectateTarget)
		end
		if ply:KeyPressed(IN_JUMP) then
			ply:SetObserverMode(mode and OBS_MODE_IN_EYE or OBS_MODE_ROAMING)
		end

		if ply:KeyPressed(IN_ATTACK) or ply:KeyPressed(IN_ATTACK2) then
			local plys = player.GetAll()
			local newtarget
			if ply:KeyPressed(IN_ATTACK) then
				local foundcur = false
				for k,v in pairs(plys) do
					if v == ply.SpectateTarget then
						foundcur = true
					elseif CanSpectate(ply, v) then
						if not newtarget then newtarget = v end -- The first one (if the loop reaches the end)
						if foundcur then newtarget = v break end -- The one found after finding current one
					end
				end
			else
				for k,v in pairs(plys) do
					if v == ply.SpectateTarget then
						if newtarget then break end -- If we found a valid before this, stop here and return that
						-- If we didn't, continue until end and used last one found						
					elseif CanSpectate(ply, v) then
						newtarget = v
					end
				end
			end

			ply.SpectateTarget = newtarget -- Always set this (just in case it can't spectate one, it can still jump past)
			if IsValid(newtarget) then ply:SpectateEntity(newtarget) end
		end
	end

	function GM:EntityTakeDamage(target, dmg)
		if target:IsPlayer() then
			if target:IsDemon() then
				if dmg:GetInflictor():GetClass() == "ritual_human" then return false end -- Take that damage
				if not dmg:IsDamageType(DMG_CRUSH) then return true end -- Otherwise only take crush damage (for safety reasons)
			end
			if not dmg:IsDamageType(DMG_PARALYZE) then
				if dmg:GetDamage() > target:Health() then
					target:DeathScream()
				else
					if not target.NextHurtSound or CurTime() >= target.NextHurtSound then
						target:HurtScream()
						target.NextHurtSound = CurTime() + 5
					end
				end
			end
		end
	end

	function GM:GetFallDamage(ply, speed)
		if ply:IsDemon() then return 0 end
		return speed/10
	end

	util.AddNetworkString("Ritual_DollReset")
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

	-- Doll reset effects
	net.Receive("Ritual_DollReset", function()
		local ent = net.ReadEntity()
		if IsValid(ent) then
			local e = EffectData()
			e:SetEntity(ent)
			e:SetAttachment(ent:LookupAttachment("doll_body")) -- Body
			if ent:IsWeapon() and ent:IsCarriedByLocalPlayer() then
				e:SetStart(Vector(0,-4,-3))
				e:SetOrigin(Vector(0,-3,5))
				e:SetScale(1)
				e:SetRadius(15)
				e:SetFlags(1)
				timer.Simple(0.3, function() if IsValid(ent) then util.Effect("ritual_dollreset", e, true, true) end end)
			else
				e:SetStart(Vector(0,0,-5))
				e:SetOrigin(Vector(0,0,10))
				e:SetScale(2)
				e:SetRadius(20)
				util.Effect("ritual_dollreset", e, true, true)
			end
		end
	end)

	function GM:CreateClientsideRagdoll(ent, rag)
		if ent == LocalPlayer() then
			local phys = rag:GetPhysicsObject()
			if IsValid(phys) then
				-- Stop that pesky localplayer ragdoll flinging
				for i = 0, rag:GetPhysicsObjectCount() - 1 do
					rag:GetPhysicsObjectNum(i):SetVelocityInstantaneous(Vector(0,0,0))
				end
			end
		end
	end
end