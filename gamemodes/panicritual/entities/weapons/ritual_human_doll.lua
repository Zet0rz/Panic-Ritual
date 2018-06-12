if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false
end

if CLIENT then
	SWEP.PrintName     	    = "Corrupt Doll"			
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

SWEP.ViewModel	= "models/weapons/c_grenade.mdl"
SWEP.WorldModel	= "models/weapons/w_grenade.mdl"
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

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "CirclesToPlace")
end

function SWEP:Initialize()

end

if SERVER then
	function SWEP:SetRitualCircle(circle)
		self.RitualCircle = circle
	end

	function SWEP:TransferDollData(doll)
		self:SetRitualCircle(doll.RitualCircle)
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

		self.Owner:StripWeapon(self:GetClass())
	end

	function SWEP:Drop() -- Drop this as a doll entity!
		local doll = ents.Create("ritual_doll")
		doll:TransferDollData(self)
		self.RitualCircle:SetDoll(doll)
		doll:SetPos(self.Owner:GetShootPos())
		doll:SetAngles(self.Owner:GetAngles())
		doll:SetMoveType(MOVETYPE_VPHYSICS)
		doll:Spawn()

		self.Dropped = true

		self.Owner:StripWeapon(self:GetClass())
	end

	function SWEP:StartDollCleanse(circle)
		self:CompleteCircle(circle)
		-- Later replace this with some short timed sequence?
	end

	function SWEP:StopDollCleanse(circle)

	end

	function SWEP:CompleteCircle(circle)
		self.RitualCircle:Progress(circle)
	end
end

function SWEP:PrimaryAttack()
	-- Drop it here?
end