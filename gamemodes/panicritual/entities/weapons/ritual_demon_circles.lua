if SERVER then
	AddCSLuaFile("ritual_demon_circles.lua")
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false
end

if CLIENT then

	SWEP.PrintName     	    = "Ritual Circles"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end

SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Kill Humans"
SWEP.Instructions	= "Left Click to place Ritual Circle!"

SWEP.HoldType = "melee"

SWEP.ViewModel	= "models/weapons/c_ritual_human.mdl"
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

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "CirclesToPlace")
end

function SWEP:Initialize()

end

function SWEP:Deploy()
	
end

function SWEP:PrimaryAttack()
	if SERVER then
		GAMEMODE:PlaceRitualCircle(self.Owner:GetPos(), Angle(0,self.Owner:GetAngles().y,0))
	end
end

function SWEP:SecondaryAttack()
	
end

function SWEP:DrawHUD()

end

function SWEP:OnRemove()
	
end