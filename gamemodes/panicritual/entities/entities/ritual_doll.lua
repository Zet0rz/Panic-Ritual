
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
local model = ""

function ENT:SetupDataTables()
	
end

function ENT:Initialize()
	
end

if SERVER then
	function ENT:SetRitualCircle(circle)
		self.RitualCircle = circle
	end

	function ENT:Reset()
		-- Burn and disappear, then reset to home circle
		self:SetPos(self.RitualCircle:GetPos())
		self:SetAngles(self.RitualCircle:GetAngles())
		self.OnRitual = true
		self.Complete = false
		self.ResetTime = nil
	end

	function ENT:Pickup(ply)
		-- Pick up, give as weapon to player and set relevant information
	end
end

function ENT:Think()
	if self.ResetTime and self.ResetTime < CurTime() then
		self:Reset()
	end
end