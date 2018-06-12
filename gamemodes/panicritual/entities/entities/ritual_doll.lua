
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
	
end

function ENT:Initialize()
	self:SetModel(model)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:PhysicsInit(SOLID_VPHYSICS)
	if SERVER then
		self:SetUseType(SIMPLE_USE)
		self:Reset(true)
	end

	if self:GetMoveType() ~= 0 then
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			--phys:Wake()
		end
	end
end

if SERVER then
	function ENT:TransferDollData(doll)
		self:SetRitualCircle(doll.RitualCircle)
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
		self:SetPos(self.RitualCircle:GetPos() + self.RitualCircle:GetAngles():Up()*50)
		self:SetAngles(self.RitualCircle:GetAngles())
		self:SetMoveType(MOVETYPE_NONE)
		self.OnRitual = true
		self.Complete = false
		self.ResetTime = nil
	end

	function ENT:Pickup(ply)
		-- Pick up, give as weapon to player and set relevant information
	end

	function ENT:Use(activator, caller)
		if IsValid(caller) and caller:IsPlayer() and caller:IsHuman() and not caller:HasWeapon("ritual_human_doll") and not self.RitualCircle.Complete then
			local wep = caller:Give("ritual_human_doll")
			wep:TransferDollData(self)
			self.RitualCircle:SetDoll(wep)
			self:Remove()
		end
	end
end

function ENT:Think()
	if self.ResetTime and self.ResetTime < CurTime() then
		self:Reset()
	end
end