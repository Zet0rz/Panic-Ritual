if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false
end

if CLIENT then

	SWEP.PrintName     	    = "Demon Claws"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end

SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Kill Humans"
SWEP.Instructions	= "Left Click to leap!"

SWEP.HoldType = "knife"

SWEP.ViewModel	= "models/weapons/c_crowbar.mdl"
SWEP.WorldModel	= "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.vModel = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

local minleap = 300
local chargedleap = 300 -- +power for charging fully
local maxchargetime = 1.5 -- Seconds of LMB to reach full charge leap
local chargedelay = 0.1 -- Seconds until charging begins (click = just weak leap)

function SWEP:SetupDataTables()
	
end

function SWEP:Initialize()
	self.Owner.NextLeap = 0
end

function SWEP:Deploy()
	
end

-- Maul attacks
--[[function SWEP:PrimaryAttack()
	if SERVER and self.Owner.NextLeap and CurTime() > self.Owner.NextLeap then
		self.Owner.LeapCharging = CurTime()
		self.Owner:SetLeapCharging(true)
	end
end

function SWEP:Think()
	if SERVER then
		if self.Owner.LeapCharging then
			local ct = CurTime()
			local diff = ct - self.Owner.LeapCharging
			if not self.Owner:KeyDown(IN_ATTACK) or diff >= maxchargetime then
				local power = minleap + (diff/maxchargetime)*chargedleap
				self.Owner:SetGroundEntity(nil)
				self.Owner:SetVelocity((self.Owner:GetAimVector() + Vector(0,0,0.2))*power)
				self.Owner.NextLeap = nil
				self.Owner.LeapCharging = nil
				self.Owner:SetLeapCharging(false)
			end
		elseif not self.Owner.NextLeap then -- We're in mid-air leaping
			self:SeekLeapTarget()
		end
	end
end

local hullsize = 10
local distance = 50
function SWEP:SeekLeapTarget()
	local tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * distance),
		filter = self.Owner,
		mins = Vector(-hullsize, -hullsize, -hullsize),
		maxs = Vector(hullsize, hullsize, hullsize),
		--mask = MASK_SHOT_HULL
	})

	if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:IsHuman() then
		self:AttackTarget(tr.Entity)
		self.Owner.NextLeap = CurTime() + 3
	end
end

function SWEP:AttackTarget(ply)
	self.Owner:DemonicMaul(ply)
end

function SWEP:SecondaryAttack()
	if SERVER and IsValid(self.Owner:GetMauling()) then self.Owner:GetMauling():CollideWhenPossible() self.Owner:StopMaul() end
end]]

function SWEP:DrawHUD()

end

function SWEP:OnRemove()
	
end

-- Soul siphon
function SWEP:SecondaryAttack()
	if SERVER and self.Owner.NextLeap and CurTime() > self.Owner.NextLeap then
		self.Owner.LeapCharging = CurTime()
		self.Owner:SetLeapCharging(true)
	end
end

function SWEP:Think()
	if SERVER then
		if self.Owner.LeapCharging then
			local ct = CurTime()
			local diff = ct - self.Owner.LeapCharging
			if not self.Owner:KeyDown(IN_ATTACK2) or diff >= maxchargetime then
				local power = minleap + (diff/maxchargetime)*chargedleap
				self.Owner:SetGroundEntity(nil)
				self.Owner:SetVelocity((self.Owner:GetAimVector() + Vector(0,0,0.2))*power)
				self.Owner.NextLeap = nil
				self.Owner.LeapCharging = nil
				self.Owner:SetLeapCharging(false)
			end
		end
	end
end

local hullsize = 10
local distance = 50
function SWEP:SeekLeapTarget()
	local tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * distance),
		filter = self.Owner,
		mins = Vector(-hullsize, -hullsize, -hullsize),
		maxs = Vector(hullsize, hullsize, hullsize),
		--mask = MASK_SHOT_HULL
	})

	if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:IsHuman() then
		self:AttackTarget(tr.Entity)
		self.Owner.NextLeap = CurTime() + 3
	end
end

function SWEP:AttackTarget(ply)
	self.Owner:SiphonGrab(ply)
end

function SWEP:PrimaryAttack()
	if SERVER then
		self:SeekLeapTarget()
	end
end
