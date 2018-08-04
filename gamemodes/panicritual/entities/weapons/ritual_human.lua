if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false
end

if CLIENT then
	SWEP.PrintName     	    = "Human Hands"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true
end

SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Cleanse Ritual Doll"
SWEP.Instructions	= "Bring the doll to the other ritual circles!"

SWEP.HoldType = "normal"

SWEP.ViewModel	= "models/weapons/c_ritual_human.mdl" --"models/weapons/c_ritual_human.mdl"
SWEP.WorldModel	= "models/weapons/w_ritual_human.mdl"
SWEP.UseHands = true

local cleansetime = 4
local chargetime = 10
local ammo_type = "GaussEnergy"
local chargeammo = 100

-- Related to evil scale
local emindist = 300 -- Distance at which scale is 1
local emaxdist = 1000 -- How far away from mindist scale reaches 0
local eupdatedelay = 2 -- How often to run the distance check
local eapproach = 0.5 -- How much the client interpolates last known to recently updated per second (smoothens)

-- Related to whisper scale
local wmindist = 300 -- Distance at which scale is 1
local wmaxdist = 1000 -- How far away from mindist scale reaches 0
local wupdatedelay = 1 -- How often to run the distance check

local dollcleansesound = Sound("panicritual/doll_cleanse.wav")
local dollchargesound = Sound("panicritual/doll_charged.wav")

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= ammo_type

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "HasDoll")
	self:NetworkVar("Bool", 1, "Charged")
	self:NetworkVar("Bool", 2, "Shooting")
	self:NetworkVar("Float", 0, "EvilScale")
	self:NetworkVar("Float", 1, "WhisperScale")

	if SERVER then
		--self:NetworkVarNotify("HasDoll", self.DollPickupAnimation)
	end
end

function SWEP:Initialize()
	if SERVER then
		self:SetHasDoll(false)
		self:SetCharged(false)
		self:SetShooting(false)
		self:SetEvilScale(0)
	else
		self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), Angle(0,0,0))
	end
	self:SetHoldType(self.HoldType)
end

local function UpdateAnimations(self)
	if self.Sprinting then
		self.NextIdleAct = self:GetHasDoll() and ACT_VM_SPRINT_IDLE or ACT_VM_IDLE -- replace with non-doll sprint act later
	--elseif self.Owner:KeyDown(IN_WALK) then
		--self.NextIdleAct = self:GetHasDoll() and ACT_VM_IDLE_DEPLOYED_1 or ACT_VM_IDLE
	else
		self.NextIdleAct = self:GetHasDoll() and ACT_VM_IDLE_DEPLOYED or ACT_VM_IDLE
	end
	if not self.NextIdleTime then self:SendWeaponAnim(self.NextIdleAct) end
end

if SERVER then
	util.AddNetworkString("ritual_doll_cleanse")

	function SWEP:PlayActAndWait(act, cycle)
		local vm = self.Owner:GetViewModel()
		local seq = vm:SelectWeightedSequence(act)
		local len = vm:SequenceDuration(seq)

		vm:SetSequence(seq)
		if cycle then
			vm:SetCycle(cycle)
			len = len * (1 - cycle)
		end
		self.NextIdleTime = CurTime() + len

		return len
	end

	function SWEP:PlaySequenceAndWait(seq, cycle)
		local vm = self.Owner:GetViewModel()
		local id, dur = vm:LookupSequence(seq)

		vm:SetSequence(id)
		if cycle then
			vm:SetCycle(cycle)
			len = len * (1 - cycle)
		end
		self.NextIdleTime = CurTime() + dur

		return dur
	end

	function SWEP:SetRitualCircle(circle)
		self.RitualCircle = circle
	end

	function SWEP:PickupDoll(doll)
		self:SetRitualCircle(doll.RitualCircle)
		self:SetHasDoll(true)
		local dc = doll:GetCharged()
		self:SetCharged(dc)
		local cc = dc and doll.AmmoCharge or 0
		self.Owner:SetAmmo(cc, ammo_type)
		self.AmmoCharge = cc
		self:PlayActAndWait(ACT_VM_DEPLOY)
		UpdateAnimations(self)
	end

	local function losedoll(self)
		self:SetHasDoll(false)
		self:SetCharged(false)
		self:SetShooting(false)
		self:SetEvilScale(0)

		self:SetHoldType(self.HoldType)

		self.Owner:SetAmmo(0, ammo_type)
		self.Charging = nil
		if self.Cleansing then self:StopDollCleanse(self.Cleansing) end

		UpdateAnimations(self)
	end

	function SWEP:Reset(fromcircle) -- Called from the ritual circle. Burn up and reset!
		if IsValid(self.RitualCircle) then
			if not fromcircle then
				self.RitualCircle:Reset()
				return
			end

			local doll = ents.Create("ritual_doll")
			doll:SetRitualCircle(self.RitualCircle)
			self.RitualCircle:SetDoll(doll)
			doll:Spawn()
			doll:Reset(fromcircle)
		end

		losedoll(self)

		self:PlayActAndWait(ACT_VM_UNDEPLOY, 0.2)

		net.Start("Ritual_DollReset")
			net.WriteEntity(self)
		net.Broadcast()
	end

	function SWEP:Drop() -- Drop this as a doll entity!
		local doll = ents.Create("ritual_doll")
		doll:TransferDollData(self)
		self.RitualCircle:SetDoll(doll)
		doll:SetPos(self.Owner:GetShootPos())
		doll:SetAngles(self.Owner:GetAngles())
		--doll:SetMoveType(MOVETYPE_VPHYSICS)
		doll.Dropped = true
		doll:Spawn()
		doll:Activate()

		doll.AmmoCharge = self.Owner:GetAmmoCount(ammo_type)

		losedoll(self)

		return doll
	end

	function SWEP:StartDollCleanse(circle)
		if not circle:AllowCleanse(self) then return end

		self.Cleansing = circle
		self.InCleanseLoop = false

		local ct = CurTime()

		local time = self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_IN)
		self.CleanseLoop = ct + time

		self.CleanseFinish = ct + cleansetime

		--[[net.Start("ritual_doll_cleanse")
			net.WriteBool(true)
		net.Send(self.Owner)]]
	end

	--[[function SWEP:StartAnimLoop(anim, delay, duration, callback)
		if self.AnimLoopCallback then self:AnimLoopCallback(false) end

		self.InAnimLoop = false

		local ct = CurTime()
		self.AnimLoopStart = ct + delay
		self.AnimLoopFinish = ct + duration
		self.AnimLoopCallback = callback
		self.AnimLoopAnim = anim
	end]]
	function SWEP:StartDollCharge(doll)
		if not doll:AllowCharge(self) then return end
		
		local ct = CurTime()
		self.InCleanseLoop = false
		self.CleanseLoop = ct
		self.CleanseFinish = ct + cleansetime
		self.Charging = doll

		--[[local e = EffectData()
		e:SetEntity(self)
		e:SetOrigin(doll:GetPos())
		e:SetStart(doll.RitualCircle:GetPos())
		e:SetScale(5)
		e:SetMagnitude(1)
		e:SetRadius(100)
		e:SetFlags(0)
		util.Effect("ritual_dollcharge",e,true,true)]]
	end

	function SWEP:StopDollCharge(doll)
		if not self.Charging then return end
		-- Kill the effect
		--[[local e = EffectData()
		e:SetEntity(self)
		e:SetFlags(1) -- Kills the effect
		util.Effect("ritual_dollcharge",e,true,true)]]

		self.Charging = nil
		--self.NextIdleTime = nil
		UpdateAnimations(self)
	end

	function SWEP:CompleteDollCharge(doll)
		if IsValid(doll.RitualCircle) then
			local e = EffectData()
			e:SetOrigin(doll.RitualCircle:GetPos())
			e:SetMagnitude(200)
			e:SetRadius(100)
			e:SetScale(1)
			util.Effect("ritual_dollchargebeam",e,true,true)
		end

		self.Charging = nil
		doll:Pickup(self.Owner)
		self:Charge()
		self:PlayActAndWait(ACT_VM_PICKUP) -- Replace with charge anim
		self.Owner:EmitSound(dollchargesound)
	end

	function SWEP:StopDollCleanse(circle)
		if self.Cleansing == nil or not circle:AllowCleanse(self) then return end

		self.Cleansing = nil
		if self:GetHasDoll() then self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT) end
	end

	function SWEP:CompleteCircle(circle)
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT)
		self.Cleansing = nil

		if self:GetCharged() and self.RitualCircle:GetCompleted() then
			self:Charge() -- Re-cleanse = reload ammo/charge
		else
			self.RitualCircle:Progress(circle, self.Owner)
		end

		self.Owner:EmitSound(dollcleansesound)
		net.Start("ritual_doll_cleanse")
			net.WriteEntity(self)
		net.Broadcast()
	end

	function SWEP:Charge()
		if not self:GetHasDoll() then return end

		self:SetCharged(true)
		self.ChargeAmmo = chargeammo
		self.Owner:SetAmmo(self.ChargeAmmo, ammo_type)
	end

	function SWEP:UpdateEvilScale()
		local bestdist = math.huge
		for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
			-- Even though there should only ever be 1, support more
			if v:Alive() then
				local dist = self:GetPos():Distance(v:GetPos())
				if dist < bestdist then bestdist = dist end
			end
		end
		local scale = math.Clamp(1 - (bestdist - emindist)/emaxdist, 0, 1)
		self:SetEvilScale(scale)
	end

	function SWEP:UpdateWhisperScale()
		if not IsValid(self.RitualCircle) then self:SetWhisperScale(0) return end

		local bestdist = math.huge
		for k,v in pairs(GAMEMODE.GetRitualCircles()) do
			if v:AllowCleanse(self) then
				local dist = self:GetPos():Distance(v:GetPos())
				if dist < bestdist then bestdist = dist end
			end
		end
		local scale = math.Clamp(1 - (bestdist - wmindist)/wmaxdist, 0, 1)
		self:SetWhisperScale(scale)
	end

	function SWEP:Think()
		local ct = CurTime()

		if self.NextIdleTime and not self.Cleansing and ct > self.NextIdleTime then
			self:SendWeaponAnim(self.NextIdleAct or ACT_VM_IDLE)
			self.NextIdleTime = nil
		end

		if self.Owner:KeyDown(IN_FORWARD) then
			if self.Owner:IsSprinting() and self.Owner:GetVelocity():Length2D() > 100 then
				if not self.Sprinting then
					self.Sprinting = true
					UpdateAnimations(self)
				end
			elseif self.Sprinting then
				self.Sprinting = false
				UpdateAnimations(self)
			end
		elseif self.Sprinting then
			self.Sprinting = false
			UpdateAnimations(self)
		end

		if self.Cleansing then
			if not self.InCleanseLoop then
				if ct > self.CleanseLoop then
					self:SendWeaponAnim(ACT_VM_DEPLOYED_LIFTED_IDLE)
					self.InCleanseLoop = true
				end
			else
				local pct = (ct - self.CleanseLoop)/cleansetime
				local vm = self.Owner:GetViewModel()
				vm:SetPoseParameter("doll_cleanse", pct)
				if ct > self.CleanseFinish then
					self:CompleteCircle(self.Cleansing)
				end
			end
		elseif self.Charging then
			if not self.InCleanseLoop then
				if ct > self.CleanseLoop then
					self:SendWeaponAnim(ACT_VM_READY) -- Replace with charge anim
					self.InCleanseLoop = true
				end
			else
				if self.Owner:GetEyeTrace().Entity ~= self.Charging then
					self:StopDollCharge()
				else
					local pct = (ct - self.CleanseLoop)/chargetime
					local vm = self.Owner:GetViewModel()
					vm:SetPoseParameter("doll_cleanse", pct)
					if ct > self.CleanseFinish then
						self:CompleteDollCharge(self.Charging)
					end
				end
			end
		elseif self:GetShooting() and self.Owner:KeyReleased(IN_ATTACK) then
			self:PlayActAndWait(ACT_VM_DEPLOYED_OUT)
			self:SetShooting(false)
			self:SetHoldType(self.HoldType)
		end

		if not self.NextEvilUpdate or ct > self.NextEvilUpdate then
			self:UpdateEvilScale()
			self.NextEvilUpdate = ct + eupdatedelay
		end

		if not self.NextWhisperUpdate or ct > self.NextWhisperUpdate then
			self:UpdateWhisperScale()
			self.NextWhisperUpdate = ct + wupdatedelay
		end
	end
end

if CLIENT then
	local cleanseloop
	local cleansepcf = "ritual_doll_cleanse"
	net.Receive("ritual_doll_cleanse", function()
		local doll = net.ReadEntity()
		local viewmodel
		if doll:IsWeapon() and doll:IsCarriedByLocalPlayer() then
			viewmodel = LocalPlayer():GetViewModel()
		end
		doll.DollCleansedEffect = CreateParticleSystem(viewmodel or doll, cleansepcf, PATTACH_POINT, (viewmodel or doll):LookupAttachment("doll_body"), Vector(0,0,0))
		doll.DollCleansedEffect:SetControlPoint(0, (viewmodel or doll):GetBonePosition((viewmodel or doll):LookupBone("Doll")))
		doll.DollCleansedEffect:SetControlPoint(1, Vector(0.7,1,1))
		doll.DollCleansedEffect:SetShouldDraw(not viewmodel)
		doll.DollCleansedEffect:SetIsViewModelEffect(not not viewmodel)
	end)

	-- Function run to draw the red eyes depending on distance to demon(s)
	-- Runs both on world model and viewmodel
	--[[local particledelay = 0.05
	local gravity = Vector(0,0,100)
	local particles = {
		"panicritual/particles/fire/ritual_fire_cloud1",
		"panicritual/particles/fire/ritual_fire_cloud2",
	}]]
	local pcf = "ritual_doll_burn_eyes"
	local function drawdolleffects(self, viewmodel)
		-- Create and remove burning eye effects
		if not self.LEyeEffect == self:GetHasDoll() then
			if self.LEyeEffect then
				self.LEyeEffect:StopEmission(false,true)
				self.REyeEffect:StopEmission(false,true)

				self.LEyeEffect = nil
				self.REyeEffect = nil
			else
				if viewmodel then
					self.LEyeEffect = CreateParticleSystem(viewmodel, pcf, PATTACH_POINT_FOLLOW, viewmodel:LookupAttachment("doll_l_eye_vm"), Vector(0,0,0))
					self.LEyeEffect:SetControlPoint(1, Vector(1,0.5,1))
					self.LEyeEffect:SetShouldDraw(false)

					self.REyeEffect = CreateParticleSystem(viewmodel, pcf, PATTACH_POINT_FOLLOW, viewmodel:LookupAttachment("doll_r_eye_vm"), Vector(0,0,0))
					self.REyeEffect:SetControlPoint(1, Vector(1,0.5,1))
					self.REyeEffect:SetShouldDraw(false)
				else
					self.LEyeEffect = CreateParticleSystem(self, pcf, PATTACH_POINT_FOLLOW, self:LookupAttachment("doll_l_eye"), Vector(0,0,0))
					self.LEyeEffect:SetControlPoint(1, Vector(1,0.5,1))
					self.LEyeEffect:SetShouldDraw(true)

					self.REyeEffect = CreateParticleSystem(self, pcf, PATTACH_POINT_FOLLOW, self:LookupAttachment("doll_r_eye"), Vector(0,0,0))
					self.REyeEffect:SetControlPoint(1, Vector(1,0.5,1))
					self.REyeEffect:SetShouldDraw(true)
				end
				
			end
		end

		-- Render burning eye effects
		if self.LEyeEffect then
			local targetpower = self:GetEvilScale()
			if not self.EvilScale then self.EvilScale = 0 end
			self.EvilScale = math.Approach(self.EvilScale, targetpower, FrameTime()*eapproach)
			self.LEyeEffect:SetControlPoint(2, Vector(self.EvilScale,0,0)) -- Scale
			self.REyeEffect:SetControlPoint(2, Vector(self.EvilScale,0,0))

			if viewmodel then
				-- This code makes it more accurate; but it falls behind on lower-end systems
				-- Enabling this code requires setting PATTACH_POINT (no FOLLOW) on the effects on viewmodel
				
				--[[local pos,ang = viewmodel:GetBonePosition(viewmodel:LookupBone("Doll"))
				local wpos,wang = LocalToWorld(Vector(-1.2,4,-3), Angle(130,0,-80), pos, ang)
				local f,r,u = wang:Forward(),wang:Right(),wang:Up()

				local repos = wpos + r*0.4
				local lepos = wpos + r*-1.1

				self.LEyeEffect:SetControlPoint(0, lepos)
				self.LEyeEffect:SetControlPointOrientation(0,f,r,u)
				self.REyeEffect:SetControlPoint(0, repos)
				self.REyeEffect:SetControlPointOrientation(0,f,r,u)]]
				self.LEyeEffect:Render()
				self.REyeEffect:Render()

				--[[[render.SetColorMaterial()
				render.DrawBeam(pos,pos + wang:Forward()*10,1,0,1,Color(255,0,0))
				render.DrawBeam(pos,pos + wang:Right()*10,1,0,1,Color(0,255,0))
				render.DrawBeam(pos,pos + wang:Up()*10,1,0,1,Color(0,0,255))

				--render.DrawBeam(pos,repos,1,0,1,Color(0,255,255))
				render.DrawBeam(pos,wpos,1,0,1,Color(255,0,255))]]
			end
		end

		-- Render doll cleanse effects
		if self.DollCleansedEffect then
			self.DollCleansedEffect:Render()
			--if self.DollCleansedEffect:IsFinished() then print("done") end
		end
		--[[if viewmodel then
			--PrintTable(viewmodel:GetAttachments())
			render.SetColorMaterial()
			local ep1 = viewmodel:GetAttachment(viewmodel:LookupAttachment("doll_l_eye_vm")).Pos
			local ep2 = viewmodel:GetAttachment(viewmodel:LookupAttachment("doll_r_eye_vm")).Pos
			--render.DrawSphere(ep1, 1, 10, 10, Color(255,255,255))
			--render.DrawSphere(ep2, 1, 10, 10, Color(255,255,255))
			local pos,ang = viewmodel:GetBonePosition(viewmodel:LookupBone("Doll"))
			render.SetColorMaterialIgnoreZ()
			render.DrawSphere(pos, 1, 10, 10, Color(255,255,255))
			render.DrawBeam(pos, ep1, 1, 0,0, Color(pos:Distance(ep1)*10,0,0))

			--render.SetMaterial()
		end]]

		if not self.ChargedEffect == self:GetCharged() then
			if self.ChargedEffect then
				self.ChargedEffect:StopEmission(false, true)
				self.ChargedEffect = nil
			else
				local att = (viewmodel or self):LookupAttachment("doll_body")
				self.ChargedEffect = CreateParticleSystem(viewmodel or self, "ritual_doll_charged", PATTACH_POINT_FOLLOW, att)
				self.ChargedEffect:SetIsViewModelEffect(not not viewmodel)
				self.ChargedEffect:SetShouldDraw(not viewmodel)
				self.ChargedEffect:SetControlPoint(1, Vector(0.7,1,1))
				self.ChargedEffect:SetControlPoint(2, Vector(1,0,0))
			end
		end

		if self.ChargedEffect then
			local pct = self.Owner:GetAmmoCount(ammo_type)/chargeammo
			self.ChargedEffect:SetControlPoint(2, Vector(pct,0,0))
			if viewmodel then
				self.ChargedEffect:Render()
			end
		end
	end

	function SWEP:GetViewModelPosition(pos,ang)
		--return pos + ang:Forward()*70, ang + Angle(0,CurTime()%360*30,0)
		--return pos + ang:Right()*10 + ang:Forward()*30, ang + Angle(0,90,0)
	end

	function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
		--return pos, ang
	end
	
	local lastwhisper = 0
	function SWEP:PostDrawViewModel(vm, wep, ply)
		drawdolleffects(self, vm)
		if not self.WhisperSound then self.WhisperSound = CreateSound(self, "panicritual/doll_whisper.wav") end
		if not self:GetHasDoll() and self.WhisperSound:IsPlaying() then
			self.WhisperSound:Stop()
		else
			local scale = self:GetWhisperScale()
			if scale ~= lastwhisper then
				if not self.WhisperSound:IsPlaying() then self.WhisperSound:Play() end
				self.WhisperSound:ChangeVolume(scale, wupdatedelay)
				lastwhisper = scale
			end
		end
	end

	function SWEP:DrawWorldModel()
		if self:GetHasDoll() then
			if self:GetShooting() ~= self.ShootHands then
				self.ShootHands = self:GetShooting()
				self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), self.ShootHands and Angle(0,70,0) or Angle(0,0,0))
			end

			self:DrawModel()

			drawdolleffects(self)

			-- Draw the red eyes
			--[[local power = self:GetEvilScale()
			if not self.Emitter then
				self.Emitter = ParticleEmitter(self:GetPos())
				self.NextParticle = 0
			end
			local ct = CurTime()
			if ct > self.NextParticle then
				local vel = power*10 -- The power it flies forwards

				for i = 2,3 do
					local att = self:GetAttachment(i)
					local p = self.Emitter:Add(particles[math.random(#particles)], att.Pos)
					p:SetVelocity(att.Ang:Forward()*vel)
					--p:SetColor(255,255,255)
					p:SetLifeTime(0)
					p:SetDieTime(0.25)
					p:SetStartAlpha(255)
					p:SetEndAlpha(0)
					p:SetStartSize(1)
					p:SetEndSize(0.75)
					--p:SetRoll(math.random(360))
					--p:SetRollDelta(math.Rand(5,10))
					p:SetAirResistance(100)
					p:SetGravity(gravity)
				end

				self.NextParticle = ct + particledelay
			end]]
		else
			if self.LEyeEffect then
				drawdolleffects(self) -- This removes the effect
			end
			if self.ShootHands then
				self.ShootHands = false
				self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), Angle(0,0,0))
			end
		end
	end

	function SWEP:OnRemove()
		if self.ShootHands then -- Restore here
			self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), Angle(0,0,0))
		end
		if self.Emitter then self.Emitter:Finish() end
		if self.WhisperSound and self.WhisperSound:IsPlaying() then self.WhisperSound:Stop() end
	end

	local nodoll = Material("panicritual/hud/human_nodoll.png", "noclamp")
	local doll = Material("panicritual/hud/human_doll.png", "noclamp")
	local chargedoll = Material("panicritual/hud/human_dollcharge.png", "noclamp")

	local staminabar = Material("panicritual/hud/glyph_bar.png", "noclamp")
	local backdrop = Material("panicritual/hud/ability_backdrop_square.png", "noclamp")

	local throw = Material("panicritual/hud/human_throw.png", "noclamp")
	local peek = Material("panicritual/hud/human_peek.png", "noclamp")

	local pad = 50
	local space = 15
	local size1 = 150
	local size2 = 75
	local barsize = 600
	local barheight = 80
	local barlower = 75

	local col_disabled = Color(100,100,100)
	function SWEP:DrawHUD()
		local w,h = ScrW(),ScrH()

		-- Stamina
		surface.SetDrawColor(0,0,0,250)
		surface.SetMaterial(staminabar)
		surface.DrawTexturedRect(w - pad - 130 - barsize, h - pad - barlower, barsize, barheight)

		local pct = self.Owner:GetStamina()/100
		surface.SetDrawColor(0,150,255)
		surface.DrawTexturedRectUV(w - pad - 130 - barsize*pct, h - pad - barlower, barsize*pct, barheight, 1-pct, 0, 1, 1)

		if self.Owner.Ritual_StaminaLock then
			local pct2 = (self.Owner.Ritual_StaminaLock - CurTime())/self.Owner.Ritual_StaminaLockTime
			local pct3 = 1 - pct2
			surface.SetDrawColor(0,150*pct3,255*pct3,pct2*255)
			surface.DrawTexturedRectUV(w - pad - 130 - barsize*pct3 - 5, h - pad - barlower - 5, barsize*pct3 + 10, barheight + 10, pct2, 0, 1, 1)
			if pct3 >= 1 then
				self.Owner.Ritual_StaminaLock = nil
			end
		end

		-- Main doll icon
		surface.SetDrawColor(0,150,255)
		surface.SetMaterial(backdrop)
		local posx1 = w - pad - size1
		local posy1 = h - pad - size1
		surface.DrawTexturedRect(posx1, posy1, size1, size1)

		-- Throw
		local hasdoll = self:GetHasDoll()
		if hasdoll then
			surface.SetDrawColor(0,150,255)
			surface.DrawTexturedRect(posx1 - space - size2, posy1 + 10, size2, size2)
			draw.SimpleTextOutlined("RMB", "Ritual_HUDFont_Small", posx1 - space - 10, posy1 + size2 + 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)
		else
			surface.SetDrawColor(0,75,150)
			surface.DrawTexturedRect(posx1 - space - size2, posy1 + 10, size2, size2)
			draw.SimpleTextOutlined("RMB", "Ritual_HUDFont_Small", posx1 - space - 10, posy1 + size2 + 10, col_disabled, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)
		end
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(throw)
		surface.DrawTexturedRect(posx1 - space - size2, posy1 + 10, size2, size2)

		-- Peek
		if self.Peeking then
			surface.SetDrawColor(0,150,255)
		else
			surface.SetDrawColor(0,75,150)
		end
		surface.SetMaterial(backdrop)
		surface.DrawTexturedRect(posx1 - space*2 - size2*2, posy1 + 10, size2, size2)
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(peek)
		surface.DrawTexturedRect(posx1 - space*2 - size2*2, posy1 + 10, size2, size2)
		draw.SimpleTextOutlined("Alt", "Ritual_HUDFont_Small", posx1 - space*2 - size2 - 10, posy1 + size2 + 10, self.CanPeek and color_white or col_disabled, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)

		if hasdoll then
			if self.Owner:GetAmmoCount(ammo_type) > 0 then
				surface.SetMaterial(chargedoll)
				surface.DrawTexturedRect(posx1, posy1, size1, size1)
				draw.SimpleTextOutlined("LMB", "Ritual_HUDFont_Large", posx1 + size1 - 15, posy1 + size1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 3, color_black)
			else
				surface.SetMaterial(doll)
				surface.DrawTexturedRect(posx1, posy1, size1, size1)
			end
		else
			surface.SetMaterial(nodoll)
			surface.DrawTexturedRect(posx1, posy1, size1, size1)
		end
	end

	local peekmaxdist = 100
	local peeksidedist = 20
	local peekdist = 0.2 -- +20% extra (based on peekmaxdist)
	local peeklerpspeed = 3
	local peekang = 70
	local peekroll = 20	
	function SWEP:CalcView(ply, pos, ang, fov)
		local dir = ang:Forward()*peekmaxdist
		local side = ang:Right()*peeksidedist
		--[[local trc = util.TraceLine({
			start = pos,
			endpos = pos + dir,
			filter = ply
		})

		if not trc.Hit then
			local side = ang:Right()*-peeksidedist
			local trl = util.TraceLine({
				start = pos + side,
				endpos = pos + dir + side,
				filter = ply
			})
			
			if trl.Hit then
				self.PeekTargetPos = pos + dir*(trl.Fraction + peekdist)
				self.PeekTargetAngle = ang + Angle(0,peekang,peekroll)
				self.CanPeek = true
			else
				side = ang:Right()*peeksidedist
				local trr = util.TraceLine({
					start = pos + side,
					endpos = pos + dir + side,
					filter = ply
				})

				if trr.Hit then
					self.PeekTargetPos = pos + dir*(trr.Fraction + peekdist)
					self.PeekTargetAngle = ang + Angle(0,-peekang,-peekroll)
					self.CanPeek = true
				elseif self.CanPeek then
					self.CanPeek = false
				end
			end
		end]]

		local trside,trpos
		local trl = util.TraceLine({
			start = pos,
			endpos = pos + dir - side,
			filter = ply 
		})
		if trl.Hit then
			trside = -1
			trpos = pos + dir*(trl.Fraction + peekdist)
		else
			local trr = util.TraceLine({
				start = pos,
				endpos = pos + dir + side,
				filter = ply 
			})
			if trr.Hit then
				trside = 1
				trpos = pos + dir*(trr.Fraction + peekdist)
			end
		end

		if trside then
			local trc = util.TraceLine({
				start = pos,
				endpos = trpos,
				filter = ply
			})
			if not trc.Hit then
				local trs = util.TraceLine({
					start = trpos,
					endpos = trpos + trside*side,
					filter = ply
				})
				if not trs.Hit then
					self.CanPeek = true
					self.PeekTargetPos = trpos + trside*side*0.35
					self.PeekTargetAngle = ang - Angle(0,trside*peekang, trside*peekroll)
				else
					self.CanPeek = false
				end
			else
				self.CanPeek = false
			end
		else
			self.CanPeek = false
		end

		local topeek = self.CanPeek and ply:KeyDown(IN_WALK)
		if topeek ~= self.Peeking then
			self.Peeking = topeek
			self.PeekAngle = self.PeekTargetAngle
		end
		if not self.PeekLerp then self.PeekLerp = 0 end
		if self.Peeking and self.PeekLerp < 1 then
			self.PeekLerp = math.Approach(self.PeekLerp, 1, FrameTime()*peeklerpspeed)
		elseif not self.Peeking and self.PeekLerp > 0 then
			self.PeekLerp = math.Approach(self.PeekLerp, 0, -FrameTime()*peeklerpspeed)
		end

		return LerpVector(self.PeekLerp, pos, self.PeekTargetPos or pos), LerpAngle(self.PeekLerp, ang, self.PeekAngle or ang)
	end
	
	-- Lets you look around while peeking
	hook.Add("InputMouseApply", "Ritual_PeekLook", function(cmd,x,y,ang)
		local wep = LocalPlayer():GetWeapon("ritual_human")
		if IsValid(wep) and wep.Peeking and wep.PeekAngle then			
			wep.PeekAngle = wep.PeekAngle + Angle(y/120,-x/60,0)
			return true
		end
	end)
	
	-- Stop drawing the viewmodel while peeking (so you don't see dislocated arms)
	function SWEP:PreDrawViewModel()
		if self.Peeking then return true end
	end
end

local firerate = 0.05
local breakables = {
	["func_breakable"] = true,
	["func_breakable_surf"] = true,
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
}
function SWEP:PrimaryAttack()
	if self.Owner:KeyPressed(IN_ATTACK) then
		local tr = util.TraceLine({
			start = self.Owner:EyePos(),
			endpos = self.Owner:EyePos() + self.Owner:GetAimVector()*100,
			filter = self.Owner
		})
		if tr.Hit and IsValid(tr.Entity) and breakables[tr.Entity:GetClass()] then
			if SERVER then
				tr.Entity:TakeDamage(20, self.Owner, self)
				tr.Entity:Fire("Break")
				self:PlayActAndWait(ACT_VM_THROW)
			end
			self.Owner:ViewPunch(Angle(-3, 0, 0))
			return 
		end
	end

	if self:GetCharged() and (not self.NextShot or self.NextShot <= CurTime()) then
		self:FireBullets({
			Attacker = self.Owner,
			Damage = 4,
			TracerName = "ritual_dolllaser",
			Dir = self.Owner:GetAimVector(),
			Src = self.Owner:GetShootPos(),
			IgnoreEntity = self.Owner
		})
		self.NextShot = CurTime() + firerate
		self.Owner:RemoveAmmo(1, ammo_type)
		self:SendWeaponAnim(ACT_VM_DEPLOYED_FIRE)
		if not self:GetShooting() then
			self:SetShooting(true)
			self:SetHoldType("pistol")
		end
		if SERVER and self.Owner:GetAmmoCount(ammo_type) <= 0 then self:Reset() end
	end
end

-- Throw your doll!
local throwpower = 1000
function SWEP:SecondaryAttack()
	if SERVER and self:GetHasDoll() then
		local doll = self:Drop()
		local phys = doll:GetPhysicsObject()
		if IsValid(phys) then
			phys:ApplyForceCenter(self.Owner:GetAimVector()*throwpower)
		end
		self:PlayActAndWait(ACT_VM_THROW)
	end
end