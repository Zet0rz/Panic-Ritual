AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Ritual Circle"
ENT.Author			= "Zet0r"
ENT.Information		= "The main objective of Panic Ritual"
ENT.Category		= "Panic Ritual"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Completed")
end

local model = "models/Gibs/HGIBS.mdl"
local candledistance = 100 -- Distance from center to candle positions
function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetNotSolid(true)
	self:SetModel(model)

	if SERVER then
		self.CurrentProgress = 0
		self.Candles = {}

		local ang = Angle(0, 360/(self.RequiredCharge + 1), 0)
		for i = 0, self.RequiredCharge do
			local candle = ents.Create("ritual_circle_candle")
			local pos = self:GetAngles():Forward()*candledistance
			pos:Rotate(ang*i)
			candle:SetPos(self:GetPos() + pos)
			candle:SetAngles((pos:GetNormal()*-1):Angle())
			candle:Spawn()

			self.Candles[i] = candle
		end
	end
end

if SERVER then
	function ENT:SetProgressRequirement(num)
		self.RequiredCharge = num
	end

	function ENT:SetDoll(doll)
		self.Doll = doll -- Could be a weapon, could be a dropped entity
	end
end

if CLIENT then
	
end

function ENT:Think()
	
end