local PLAYER = FindMetaTable("Player")

function PLAYER:GetMauling()
	return self:GetNW2Entity("Ritual_MaulTarget")
end

function PLAYER:GetMauled()
	return self:GetNW2Entity("Ritual_MaulInflictor")
end

if SERVER then
	local damage = 10
	local interval = 0.2

	function PLAYER:DemonicMaul(target)
		if IsValid(self:GetMauled()) then print("Getting mauled") return end -- Can't maul when getting mauled
		if IsValid(target:GetMauled()) then print("Target getting mauled") target:GetMauled():StopMaul() end -- Take over the maul
		if IsValid(self:GetMauling()) then print("Self already mauling") self:StopMaul() end
		if IsValid(target:GetMauling()) then print("Target mauling") target:StopMaul() end

		self:SetNW2Entity("Ritual_MaulTarget", target)
		target:SetNW2Entity("Ritual_MaulInflictor", self)

		--self:SetPos(target:GetPos())
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		--target:SetEyeAngles(self:GetAngles() + Angle(0,180,0))
	end

	function PLAYER:StopMaul()
		local target = self:GetMauling()
		self:SetNW2Entity("Ritual_MaulTarget", nil)
		if IsValid(target) and target:GetMauled() == self then
			target:SetNW2Entity("Ritual_MaulInflictor", nil)
		end
		self:CollideWhenPossible()
	end
end

hook.Add("CalcMainActivity", "Ritual_DemonMaul", function(ply, vel)
	if IsValid(ply:GetMauled()) then
		return ACT_IDLE, ply:LookupSequence("ragdoll")
	elseif IsValid(ply:GetMauling()) then
		return ACT_HL2MP_RUN_ZOMBIE_FAST, ply:LookupSequence("zombie_run_fast")
	end
end)

hook.Add("UpdateAnimation", "Ritual_DemonMaul", function(ply, vel, groundspeed)
	if ply:IsHuman() then
		local iv = IsValid(ply:GetMauled())
		if ply.MaulAnimation ~= iv then
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("zombie_attack_frenzy"), ply.MaulAnimation and 1 or 0, ply.MaulAnimation)
			ply.MaulAnimation = iv
		end
		ply:SetPoseParameter("move_x", 0)
		ply:SetPoseParameter("move_y", 0)
	elseif ply:IsDemon() and IsValid(ply:GetMauling()) then
		--ply:SetSequence(ply:LookupSequence("zombie_run_upperbody_layer"))
		--ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_FLINCH, ply:LookupSequence("zombie_run_upperbody_layer"), 0, false )
		ply:SetPoseParameter("move_x", 1)
	end
end)

if CLIENT then
	local up = Vector(0,0,10)
	hook.Add("PrePlayerDraw", "Ritual_DemonMaul", function(ply, vel, groundspeed)
		local d = ply:GetMauled()
		if IsValid(d) then
			local ang = Angle(-90,d:GetAngles()[2] - 180, 0)
			ply:SetRenderAngles(ang)
			--ply:SetNetworkOrigin(d:GetPos() + up + ang:Up()*-20)
			ply:InvalidateBoneCache()
		end
	end)

	hook.Add("CalcView", "Ritual_MaulCam", function(ply, pos, angles, fov)
		if IsValid(ply:GetMauling()) then
			local view = {}

			view.origin = ply:GetAttachment(ply:LookupAttachment("eyes")).Pos
			view.angles = ply:GetAttachment(ply:LookupAttachment("eyes")).Ang
			view.fov = fov
			view.drawviewer = true

			--return view
		elseif IsValid(ply:GetMauled()) then
			local view = {}

			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
			view.origin = eyes.Pos
			--view.origin = pos
			view.angles = angles + Angle(-60,0,0)
			view.fov = fov
			view.drawviewer = true

			return view
		end
	end)
end

hook.Add("Move", "Ritual_MaulMove", function(ply, mv)
	if IsValid(ply:GetMauling()) then
		--mv:SetForwardSpeed(0)
		--mv:SetSideSpeed(0)
		--mv:SetUpSpeed(0)
	else
		local m = ply:GetMauled()
		if IsValid(m) then
			mv:SetOrigin(m:GetPos() +m:GetVelocity())
			return true
		end
	end
end)

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
