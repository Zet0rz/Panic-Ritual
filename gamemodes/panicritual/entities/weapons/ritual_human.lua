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

SWEP.ViewModel	= "models/weapons/c_ritual_human.mdl"
SWEP.WorldModel	= "models/weapons/w_grenade.mdl"
SWEP.UseHands = true

local cleansetime = 3
local chargetime = 5
local ammo_type = "GaussEnergy"
local chargeammo = 100

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

	if SERVER then
		self:NetworkVarNotify("HasDoll", self.DollPickupAnimation)
	end
end

function SWEP:Initialize()
	if SERVER then self:SetHasDoll(false) end
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
		self.Owner:SetAmmo(0, ammo_type)
		self.Charging = nil
		if self.Cleansing then SWEP:StopDollCleanse(self.Cleansing) end
		UpdateAnimations(self)
	end

	function SWEP:Reset(fromcircle) -- Called from the ritual circle. Burn up and reset!
		if not fromcircle then
			self.RitualCircle:Reset()
			return
		end

		local doll = ents.Create("ritual_doll")
		doll:SetRitualCircle(self.RitualCircle)
		self.RitualCircle:SetDoll(doll)
		doll:Spawn()
		doll:Reset(fromcircle)

		losedoll(self)

		self:PlayActAndWait(ACT_VM_UNDEPLOY, 0.2)
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
		local time = self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_IN) -- Replace with charge anim
		self.InCleanseLoop = false
		self.CleanseLoop = ct + time
		self.CleanseFinish = ct + cleansetime
		self.Charging = doll
	end

	function SWEP:StopDollCharge(doll)
		self.Charging = nil
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT) -- Replace with charge anim
	end

	function SWEP:CompleteDollCharge(doll)
		self.Charging = nil
		doll:Pickup(self.Owner)
		self:Charge()
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT) -- Replace with charge anim
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
					self:SendWeaponAnim(ACT_VM_DEPLOYED_LIFTED_IDLE) -- Replace with charge anim
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
		end
	end
end

if CLIENT then
	local cleanseloop
	net.Receive("ritual_doll_cleanse", function()
		local b = net.ReadBool()
	end)

	function SWEP:PostDrawViewModel(vm, wep, ply)

	end
end

local firerate = 0.05
function SWEP:PrimaryAttack()
	if self:GetCharged() and (not self.NextShot or self.NextShot <= CurTime()) then
		print("SHOT!")
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
		if SERVER and self.Owner:GetAmmoCount(ammo_type) <= 0 then self:Reset() end
	end
end