local PLAYER = FindMetaTable("Player")

function PLAYER:GetSiphoning()
	return self:GetNW2Entity("Ritual_SiphonTarget")
end

function PLAYER:GetSiphoned()
	return self:GetNW2Entity("Ritual_SiphonInflictor")
end

function PLAYER:GetFading()
	return self:GetNW2Bool("Ritual_Fading")
end

function PLAYER:SetFading(b)
	return self:SetNW2Bool("Ritual_Fading", b)
end

local siphondist = 5
if SERVER then
	function PLAYER:SiphonGrab(target)


		self:SetNW2Entity("Ritual_SiphonTarget", target)
		target:SetNW2Entity("Ritual_SiphonInflictor", self)

		timer.Simple(3, function() self:SiphonRelease() end)
	end

	function PLAYER:SiphonRelease()
		--print("Releasing")

		local target = self:GetSiphoning()
		self:SetNW2Entity("Ritual_SiphonTarget", nil)
		if IsValid(target) and target:GetSiphoned() == self then
			target:SetNW2Entity("Ritual_SiphonInflictor", nil)
		end
		self:CollideWhenPossible()
	end
end

local siphonedseq = "zombie_cidle_02"
local siphonseq = "idle_all_01"
hook.Add("CalcMainActivity", "Ritual_DemonMaul", function(ply, vel)
	--[[if IsValid(ply:GetSiphoned()) then
		return ACT_HL2MP_IDLE_CROUCH_ZOMBIE_02
	elseif IsValid(ply:GetSiphoning()) then
		return ACT_HL2MP_IDLE_CAMERA
	end]]
end)

hook.Add("UpdateAnimation", "Ritual_SiphonAnim", function(ply, vel, groundspeed)
	if not ply:GetFading() then
		local p = ply:GetSiphoned()
		local iv = IsValid(p) and not p:GetFading()

		if ply.SiphonAnimation ~= iv then
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence(siphonedseq), ply.SiphonAnimation and 1 or 0, ply.SiphonAnimation)
			ply.SiphonAnimation = iv

			if iv then
				local e1 = p:GetAttachment(p:LookupAttachment("eyes"))
				local e2 = ply:GetAttachment(ply:LookupAttachment("eyes"))

				local ang = (e1.Pos - e2.Pos):Angle()
				ang.pitch = 10
				ply:SetEyeAngles(ang)
			end

			if CLIENT then
				ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_Head1"), Angle(0,iv and 50 or 0,0))
			end
		elseif not iv then
			p = ply:GetSiphoning()
			iv = IsValid(p)

			if ply.SiphonArms ~= iv then
				ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence(siphonseq), ply.SiphonArms and 1 or 0, ply.SiphonArms)
				ply.SiphonArms = iv

				if iv then
					local ang = (p:GetPos() - ply:GetPos()):Angle()
					ang.pitch = 10
					ply:SetEyeAngles(ang)
				end

				if CLIENT then
					--print("Updating arms for", ply)
					ply.SiphonArmFade = CurTime()
					if iv then ply.SiphonArmDistance = p:GetPos():Distance(ply:GetPos()) - 30 end
				end
			end
		end
	elseif ply:GetCycle() > 0.5 then
		ply:SetCycle(0.5)
	end

	--[[if iv and CLIENT then
		
		local ang = Angle(0,50,0)
		ply:ManipulateBoneAngles(ply:LookupBone("ValveBiped.Bip01_Head1"), ang)
	end]]
end)

if CLIENT then
	local angmanip = {
		["ValveBiped.Bip01_Spine1"] = Angle(0,10,0),
		["ValveBiped.Bip01_Spine2"] = Angle(0,10,0),
		["ValveBiped.Bip01_L_Clavicle"] = Angle(0,20,-10),
		["ValveBiped.Bip01_L_UpperArm"] = Angle(-40,-75,0),
		["ValveBiped.Bip01_L_Forearm"] = Angle(10,-20,-20),
		["ValveBiped.Bip01_R_Clavicle"] = Angle(10,20,-10),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(50,-70,0),
		["ValveBiped.Bip01_R_Forearm"] = Angle(0,-20,30),
	}
	local animtime = 0.2

	hook.Add("PrePlayerDraw", "Ritual_SiphonRagdoll", function(ply)
		if ply.SiphonArmFade then
			local diff = (CurTime() - ply.SiphonArmFade)/animtime
			if diff > 1 then diff = 1 end

			for k,v in pairs(angmanip) do
				local from = ply.SiphonArms and Angle(0,0,0) or v
				local target = ply.SiphonArms and v or Angle(0,0,0)
				ply:ManipulateBoneAngles(ply:LookupBone(k), LerpAngle(diff, from, target))
			end
			local from = Vector(ply.SiphonArms and 0 or ply.SiphonArmDistance, 0,0)
			local target = Vector(ply.SiphonArms and ply.SiphonArmDistance or 0, 0,0)
			ply:ManipulateBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis"), LerpVector(diff, from, target))

			ply:InvalidateBoneCache()
			if diff >= 1 then
				ply.SiphonArmFade = nil
				if not ply.SiphonArms then
					-- Just a full reset
					for k,v in pairs(angmanip) do
						ply:ManipulateBoneAngles(ply:LookupBone(k), Angle(0,0,0))
					end
					ply:ManipulateBonePosition(ply:LookupBone("ValveBiped.Bip01_Pelvis"), Vector(0,0,0))
				end
			end
		end
	end)

	hook.Add("CalcView", "Ritual_SiphonCam", function(ply, pos, angles, fov)
		local p = ply:GetSiphoned()
		if IsValid(p) then
			-- Getting siphoned
			local view = {}
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
			view.origin = eyes.Pos + eyes.Ang:Right()*2
			view.angles = eyes.Ang

			view.fov = fov
			view.drawviewer = true

			return view
		else
			p = ply:GetSiphoning()
			if IsValid(p) then
				-- Siphoning another player
				local view = {}
				local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
				view.origin = eyes.Pos --+ eyes.Ang:Right()*2
				view.angles = Angle(eyes.Ang[1], angles[2], angles[3])

				view.fov = fov
				view.drawviewer = true

				return view
			end
		end
	end)
end


--[[-------------------------------------------------------------------------
 Anti-stuck: Collide when possible
 ---------------------------------------------------------------------------]]

if SERVER then

	local checkfreq = 0.2
	-- Checks if a player is inside a player, if so, nocollides the player until free
	function PLAYER:CollideWhenPossible()
		if IsValid(self) then
			local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
			if IsValid(tr.Entity) then -- We're inside another entity
				self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				local nextcheck = 0
				local id = self:EntIndex()
				hook.Add("Think", "Ritual_CollideWhenPossible_"..id, function()
					if nextcheck < CurTime() then
						if IsValid(self) then
							local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
							if IsValid(tr.Entity) then
								nextcheck = CurTime() + checkfreq
								return
							end
							self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
						end
						hook.Remove("Think", "Ritual_CollideWhenPossible_"..id)
					end
				end)
			end
		end
	end

end
