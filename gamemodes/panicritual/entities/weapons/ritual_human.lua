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

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

local cleansetime = 3

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "HasDoll")

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
		self:PlayActAndWait(ACT_VM_DEPLOY)
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

		self:SetHasDoll(false)
		self.Cleansing = nil
		self:PlayActAndWait(ACT_VM_UNDEPLOY, 0.2)
		UpdateAnimations(self)
	end

	function SWEP:Drop() -- Drop this as a doll entity!
		local doll = ents.Create("ritual_doll")
		doll:TransferDollData(self)
		self.RitualCircle:SetDoll(doll)
		doll:SetPos(self.Owner:GetShootPos())
		doll:SetAngles(self.Owner:GetAngles())
		doll:SetMoveType(MOVETYPE_VPHYSICS)
		doll:Spawn()

		self:SetHasDoll(false)
		self:StopDollCleanse()
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

	function SWEP:StopDollCleanse(circle)
		if not circle:AllowCleanse(self) then return end

		self.Cleansing = nil
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT)
	end

	function SWEP:CompleteCircle(circle)
		self:PlayActAndWait(ACT_VM_DEPLOYED_LIFTED_OUT)
		self.Cleansing = nil
		self.RitualCircle:Progress(circle)
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
		end
	end
end

if CLIENT then
	local cleanseloop
	net.Receive("ritual_doll_cleanse", function()
		local b = net.ReadBool()
	end)

	function SWEP:Think()
		local ct = CurTime()

		
	end
end

function SWEP:PrimaryAttack()
	-- Drop it here?
end