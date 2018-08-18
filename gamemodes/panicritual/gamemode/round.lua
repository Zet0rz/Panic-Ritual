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

GM.RoundState = GM.RoundState or ROUND_INIT

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

		if not ply:IsDemon() then ply:SetHuman() end
		if GAMEMODE.RoundState == ROUND_PREPARE or GAMEMODE.RoundState == ROUND_INIT then
			ply:Spawn()
			player_manager.RunClass(ply, "Init")
		else
			GAMEMODE:PlayerSpawnAsSpectator(ply)
			timer.Simple(0, function()
				ply:KillSilent()
				ply:SetHuman()
				ply:Spectate(OBS_MODE_ROAMING)
			end)
		end
	end)

	local numcircles = 0
	local completedcircles = 0
	local circles = {}

	function GM:RestartRound()
		hook.Remove("Think", "Ritual_PostRound") -- Just in case of manual restart
		game.CleanUpMap()
		self:SetRoundState(ROUND_INIT)

		local players = player.GetAll()
		local demons = PickWeightedRandomPlayers(players, GetConVar("ritual_demon_count"):GetInt() or 1) -- Pick 1 weighted random demon

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

				player_manager.RunClass(v, "Init")
			end
		end

		self:SendHint("human_spawn", team.GetPlayers(TEAM_HUMANS))
		self:SendHint("demon_spawn", team.GetPlayers(TEAM_DEMONS))

		numcircles = 0
		completedcircles = 0
		circles = {}
		self:SetRoundState(ROUND_PREPARE)
	end

	local function StartMainPhase()
		local e = EffectData()
		e:SetRadius(60)
		
		for k,v in pairs(player.GetAll()) do
			if v:IsDemon() then
				v:CollideWhenPossible()
				v:DrawShadow(true)

				e:SetOrigin(v:GetPos() + Vector(0,0,40))
				util.Effect("ritual_fadeout", e, true, true)

				v:StaminaLock(5)
			end
			v:SetHealth(100)
		end

		for k,v in pairs(circles) do
			v:Reset()
		end

		GAMEMODE:SetRoundState(ROUND_ONGOING)
		
		GAMEMODE:SendHint("human_roundstart", team.GetPlayers(TEAM_HUMANS))
		GAMEMODE:SendHint("demon_roundstart", team.GetPlayers(TEAM_DEMONS))
	end

	local mins = Vector(-10,-10,1)
	local maxs = Vector(10,10,1)
	local closestdist = 500
	local function SpaceForCicle(pos, ang, ply)
		-- Some logic to check if there's space for the circle, and if so, where to place it
		for k,v in pairs(ents.FindByClass("ritual_circle")) do
			local p1, p2 = v:GetPos(), Vector(pos)
			p1.z = p1.z*4 -- Count vertical distance 4 times larger
			p2.z = p2.z*4
			local d = p1:Distance(p2)
			if d < closestdist then
				if IsValid(ply) then ply:SendHint("demon_circle_tooclose") end
			return end -- No can do if a circle is closer than this
		end

		local tr = util.TraceHull({
			start = pos + Vector(0,0,64),
			endpos = pos,
			maxs = maxs,
			mins = mins,
			--filter = ent,
			mask = MASK_NPCWORLDSTATIC,
		})
		if tr.Hit then
			if IsValid(ply) then ply:SendHint("demon_circle_nospace") end
		return end

		-- Enable this to enable candle space check
		--[[local reqcharge = total_circle_charge <= 0 and total_circles + total_circle_charge or total_circle_charge
		local a = Angle(0, 360/reqcharge, 0)
		for i = 0, reqcharge - 1 do
			local p = a:Forward()*100
			p:Rotate(a*i)
			
			tr = util.TraceHull({
				start = p + pos + Vector(0,0,30),
				endpos = p + pos,
				maxs = maxs,
				mins = mins,
				--filter = ent,
				mask = MASK_NPCWORLDSTATIC,
			})
			if tr.Hit then
				if IsValid(ply) then ply:SendHint("demon_circle_nospace") end
			return end
		end]]

		return pos,ang
	end

	function GM:PlaceRitualCircle(pos, ang, ply)
		local p,a = SpaceForCicle(pos,ang, ply)
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
		if completedcircles >= required_circles then
			for k,v in pairs(circles) do
				if v:GetCompleted() then v:SetChargeable(true) end
			end
		end
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
		if t == TEAM_DEMONS then
			GAMEMODE:BroadcastHint("demon_win")
		elseif t == TEAM_HUMANS then
			GAMEMODE:BroadcastHint("human_win")
		else
			GAMEMODE:BroadcastHint("noone_win")
		end
	end)

	function GM:Ritual_CanPickUpDoll(doll, wep, caller)
		--print("This is run", doll.RitualCircle.Completed, doll:GetCharged())
		return (IsValid(doll.RitualCircle) and not doll.RitualCircle:GetCompleted()) or doll:GetCharged()
	end
	--[[function GM:Ritual_DollPickedUp(doll, wep, caller)
		wep:SetCharged(doll.RitualCircle.Completed)
	end]]

	function GM:Ritual_CanChargeDoll(doll, wep, caller)
		return (IsValid(doll.RitualCircle) and doll.RitualCircle:GetCompleted()) and doll.RitualCircle:GetChargeable()
	end

	function GM:Ritual_AllowChargeable(circle)
		return circle:GetCompleted() and completedcircles >= required_circles
	end

	-- Spectating system
	--[[function GM:PlayerDeath(ply)
		
	end]]
	local respawntime = 5
	function GM:PostPlayerDeath(ply)
		if GAMEMODE.RoundState == ROUND_PREPARE then
			ply.RespawnTime = CurTime() + respawntime
		else
			if ply:GetObserverMode() ~= OBS_MODE_NONE then return end -- Already spectating
			timer.Simple(respawntime, function() -- Timer fixes ragdolls spawning in default pose
				if IsValid(ply) and not ply:Alive() then
					ply:Spectate(OBS_MODE_ROAMING)
					if ply:IsHuman() then ply:SendHint("human_spectator_hint") end
				end
			end)
		end
		CheckTeams()
	end
	hook.Add("PlayerSpawn", "Ritual_StopSpectate", function(ply)
		--if ply.RespawnTime or GAMEMODE.RoundState == ROUND_PREPARE or GAMEMODE.RoundState == ROUND_INIT then
			ply:UnSpectate()
		--end
	end)

	-- Also handle for disconnecting players
	hook.Add("EntityRemoved", "Ritual_PlayerDisconnect", function(ply)
		if ply:IsPlayer() then CheckTeams() end
	end)

	hook.Add("DoPlayerDeath", "Ritual_PlayerDropDoll", function(ply)
		if ply:IsHuman() then
			local wep = ply:GetWeapon("ritual_human")
			if IsValid(wep) and wep:GetHasDoll() then
				wep:Drop()
			end
		end
	end)

	local function CanSpectate(ply, target)
		return target:Alive() and (target:IsDemon() or target:IsHuman())
	end

	function GM:PlayerDeathThink(ply)
		if ply.RespawnTime then
			if CurTime() >= ply.RespawnTime then
				ply:Spawn()
				ply.RespawnTime = nil
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
				-- Only take damage by "ritual_human" or crush damage (for safety with map traps, avoid getting stuck)
				local wep = dmg:GetInflictor()
				if wep:GetClass() == "ritual_human" then
					if wep.LaserDamage then dmg:SetDamage(wep.LaserDamage) end
				elseif not dmg:IsDamageType(DMG_CRUSH) then return true end
			end
			if not dmg:IsDamageType(DMG_PARALYZE) then
				if dmg:GetDamage() >= target:Health() then
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
		return speed/15
	end

	function GM:GetRitualCircles()
		return circles
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
				e:SetFlags(2)
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