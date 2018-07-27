
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Ritual Doll"
ENT.Author			= "Zet0r"
ENT.Information		= "The main objective of Panic Ritual"
ENT.Category		= "Panic Ritual"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_BOTH

local resettime = 10
local model = "models/props_c17/doll01.mdl"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 1, "Charged")
end

function ENT:Initialize()
	self:SetModel(model)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:PhysicsInit(SOLID_VPHYSICS)
	if SERVER then
		self:SetUseType(SIMPLE_USE)
		if not self.Dropped then
			self:Reset(true)
		else
			self.ResetTime = CurTime() + resettime
		end
		self.AmmoCharge = 0
	end

	if self:GetMoveType() ~= 0 then
		local phys = self:GetPhysicsObject()
		if SERVER and IsValid(phys) then
			phys:Wake()
		end
	end
end

if SERVER then
	function ENT:TransferDollData(doll)
		self:SetRitualCircle(doll.RitualCircle)
		self:SetCharged(doll:GetCharged())
		self.AmmoCharge = doll.AmmoCharge
	end

	function ENT:SetRitualCircle(circle)
		self.RitualCircle = circle
	end

	function ENT:Reset(fromcircle)
		if not fromcircle then
			self.RitualCircle:Reset()
			return
		end

		-- Burn and disappear, then reset to home circle
		net.Start("Ritual_DollReset")
			net.WriteEntity(self)
		net.Broadcast()
		
		self:SetPos(self.RitualCircle:GetPos() + self.RitualCircle:GetAngles():Up()*50)
		self:SetAngles(self.RitualCircle:GetAngles())
		self:SetMoveType(MOVETYPE_NONE)
		self.OnRitual = true
		self.Complete = false
		self.ResetTime = nil
		self.RitualCircle:SetHasDoll(true)

		self:SetCharged(false)
	end

	function ENT:Pickup(ply)
		-- Pick up, give as weapon to player and set relevant information
		local wep = ply:GetWeapon("ritual_human")
		if not IsValid(wep) then return end

		print("Picked up")
		wep:PickupDoll(self)
		self.RitualCircle:SetDoll(wep)
		hook.Run("Ritual_DollPickedUp", self, wep, caller)
		self:Remove()
	end

	function ENT:Use(activator, caller)
		if IsValid(caller) and caller:IsPlayer() and caller:IsHuman() then
			local wep = caller:GetWeapon("ritual_human")
			if IsValid(wep) and not wep:GetHasDoll() then
				if hook.Run("Ritual_CanPickUpDoll", self, wep, caller) then
					self:Pickup(caller)
				else
					wep:StartDollCharge(self)
				end
			end
		end
	end

	function ENT:AllowCharge(wep)
		return hook.Run("Ritual_CanChargeDoll", self, wep, wep.Owner)
	end
end

function ENT:Think()
	if self.ResetTime and self.ResetTime < CurTime() then
		self:Reset()
	end
end