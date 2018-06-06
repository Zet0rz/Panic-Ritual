if SERVER then
	AddCSLuaFile("thisfile.lua")
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false	
end

if CLIENT then

	SWEP.PrintName     	    = "Hands"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end

local charger = 2

SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Doll"
SWEP.Instructions	= "Stuff"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

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

if SERVER then 
	--util.AddNetworkString("HasBall")
end

function SWEP:SetupDataTables()

end

function SWEP:Initialize()

end

function SWEP:Deploy()
	
end

function SWEP:PrimaryAttack()
	
end

function SWEP:SecondaryAttack()
	
end

function SWEP:DrawHUD()

end

function SWEP:DrawWorldModel()
end

function SWEP:OnRemove()
	
end

function SWEP:PreDrawViewModel(vm, ply, wep)
end