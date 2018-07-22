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

local cleansetime = 3
local chargetime = 5
local ammo_type = "GaussEnergy"
local chargeammo = 100

-- Related to evil scale
local mindist = 300 -- Distance at which scale is 1
local maxdist = 1000 -- How far away from mindist scale reaches 0
local updatedelay = 5 -- How often to run the distance check
local approach = 0.5 -- How much the client interpolates last known to recently updated per second (smoothens)

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
		if self.Cleansing then SWEP:StopDollCleanse(self.Cleansing) end

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

		local e = EffectData()
		e:SetOrigin(doll:GetPos())
		util.Effect("Explosion", e, false, true)

		losedoll(self)
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
	end

	function SWEP:StopDollCharge(doll)
		self.Charging = nil
		--self.NextIdleTime = nil
		UpdateAnimations(self)
	end

	function SWEP:CompleteDollCharge(doll)
		self.Charging = nil
		doll:Pickup(self.Owner)
		self:Charge()
		self:PlayActAndWait(ACT_VM_PICKUP) -- Replace with charge anim
	end

	function SWEP:StopDollCleanse(circle)
		if not circle:AllowCleanse(self) then return end

		self.Cleansing = nil
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT)
	end

	function SWEP:CompleteCircle(circle)
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT)
		self.Cleansing = nil

		if self:GetCharged() and self.RitualCircle.Completed then
			self:Charge() -- Re-cleanse = reload ammo/charge
		else
			self.RitualCircle:Progress(circle, self.Owner)
		end
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
		local scale = math.Clamp(1 - (bestdist - mindist)/maxdist, 0, 1)
		self:SetEvilScale(scale)
	end

	function SWEP:Think()
		local ct = CurTime()

		if self.NextIdleTime and not self.Cleansing and ct > self.NextIdleTime then
			self:SendWeaponAnim(self.NextIdleAct or ACT_VM_IDLE)
			self.NextIdleTime = nil
		end

		if self.Owner:KeyDown(IN_FORWARD) then
			local vel = self.Owner:GetVelocity():Length2D()
			if self.Owner:KeyDown(IN_SPEED) and vel > 100 then
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
			self.NextEvilUpdate = ct + updatedelay
		end
	end
end

if CLIENT then
	local cleanseloop
	net.Receive("ritual_doll_cleanse", function()
		local b = net.ReadBool()
	end)

	-- Function run to draw the red eyes depending on distance to demon(s)
	-- Runs both on world model and viewmodel
	local particledelay = 0.05
	local gravity = Vector(0,0,100)
	local particles = {
		"panicritual/particles/fire/ritual_fire_cloud1",
		"panicritual/particles/fire/ritual_fire_cloud2",
	}
	local pcf = "ritual_doll_burn_eyes"
	local function drawredeyes(self, viewmodel)
		if not self.LEyeEffect == self:GetHasDoll() then
			if self.LEyeEffect then
				self.LEyeEffect:StopEmission(false,true)
				self.REyeEffect:StopEmission(false,true)

				self.LEyeEffect = nil
				self.REyeEffect = nil
			else
				self.LEyeEffect = CreateParticleSystem(viewmodel or self, pcf, PATTACH_POINT_FOLLOW, (viewmodel or self):LookupAttachment("doll_l_eye_vm"), Vector(10000,1000,100))
				self.LEyeEffect:SetControlPoint(1, Vector(1,0.5,1))
				self.LEyeEffect:SetShouldDraw(not viewmodel)

				self.REyeEffect = CreateParticleSystem(viewmodel or self, pcf, PATTACH_POINT_FOLLOW, (viewmodel or self):LookupAttachment("doll_r_eye_vm"), Vector(-10,0,0))
				self.REyeEffect:SetControlPoint(1, Vector(1,0.5,1))
				self.REyeEffect:SetShouldDraw(not viewmodel)
			end
		end

		if self.LEyeEffect then
			self.LEyeEffect:SetControlPoint(2, Vector(1,0,0)) -- Scale
			self.REyeEffect:SetControlPoint(2, Vector(1,0,0))

			if viewmodel then
				self.LEyeEffect:Render()
				self.REyeEffect:Render()
			end
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
	end

	function SWEP:GetViewModelPosition(pos,ang)
		--return pos + ang:Forward()*70, ang + Angle(0,CurTime()%360*30,0)
		--return pos + ang:Right()*10 + ang:Forward()*10, ang + Angle(0,90,0)
	end

	function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
		--return pos, ang
	end
	
	function SWEP:PostDrawViewModel(vm, wep, ply)
		drawredeyes(self, vm)
	end

	function SWEP:TestEffect(eff, att)
		if self:IsCarriedByLocalPlayer() then
			--[[local e = LocalPlayer():GetViewModel():CreateParticleEffect(eff or pcf, att,
				{
					{attachtype = PATTACH_POINT_FOLLOW, entity = LocalPlayer():GetViewModel()},
					{attachtype = PATTACH_POINT_FOLLOW, entity = LocalPlayer():GetViewModel()},
				}
			)]]
			local e = CreateParticleSystem(LocalPlayer():GetViewModel(), eff, PATTACH_POINT_FOLLOW, 4)
			e:SetIsViewModelEffect(true)
			--e:AddControlPoint(0, self, PATTACH_POINT_FOLLOW, att or 2)
			--e:SetControlPoint(0, Vector(100,0,0))
			e:SetControlPoint(1, Vector(1,1,1))
			e:SetControlPoint(2, Vector(1,0,0))
			timer.Simple(2, function() e:StopEmissionAndDestroyImmediately() end)
		else
			local e = self:CreateParticleEffect(eff or pcf, att or 1, {{attachtype = PATTACH_POINT_FOLLOW, entity = self, offset = Vector(100,10,10)}})
			--e:AddControlPoint(0, self, PATTACH_POINT_FOLLOW, att or 2)
			--e:SetControlPoint(0, Vector(100,0,0))
			--e:SetControlPoint(1, Vector(1,1,1))
			--e:SetControlPoint(2, Vector(1,0,0))
			timer.Simple(2, function() e:StopEmissionAndDestroyImmediately() end)
		end
	end

	function SWEP:DrawWorldModel()
		if self:GetHasDoll() then
			if self:GetShooting() ~= self.ShootHands then
				self.ShootHands = self:GetShooting()
				self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), self.ShootHands and Angle(0,70,0) or Angle(0,0,0))
			end

			self:DrawModel()

			drawredeyes(self)

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
		elseif self.LEyeEffect then
			drawredeyes(self) -- This removes the effect
		end
	end

	function SWEP:OnRemove()
		if self.ShootHands then -- Restore here
			self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"), Angle(0,0,0))
		end
		if self.Emitter then self.Emitter:Finish() end
	end
end

local firerate = 0.05
function SWEP:PrimaryAttack()
	if self:GetCharged() and (not self.NextShot or self.NextShot <= CurTime()) then
		self:FireBullets({
			Attacker = self.Owner,
			Damage = 2,
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