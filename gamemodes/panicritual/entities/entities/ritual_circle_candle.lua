AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Ritual Circle Candle"
ENT.Author			= "Zet0r"
ENT.Information		= "An indicator of this Circle's progress."
ENT.Category		= "Panic Ritual"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_BOTH

local model = "models/panicritual/candle.mdl"

util.PrecacheModel(model)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
end

function ENT:Initialize()
	self:SetModel(model)
	if SERVER then self:SetLit(false) end
	self:SetMoveType(MOVETYPE_NONE)
	self:SetNotSolid(true)
end

function ENT:Complete()
	self:SetLit(true)
end

if CLIENT then
	local particle = "panicritual/particles/fire/ritual_candlefire"
	local particledelay = 0.05
	local gravity = Vector(0,0,10)
	function ENT:Draw()
		self:DrawModel()
		if self:GetLit() then
			local ct = CurTime()
			if not self.Emitter then
				self.Emitter = ParticleEmitter(self:GetPos())
				self.NextParticle = ct
			end


			local pos = self:GetAttachment(1).Pos
			if ct > self.NextParticle then
				local particle = self.Emitter:Add(particle, pos)
				if (particle) then
					--particle:SetColor(unpack(colors[math.random(#colors)]))
					particle:SetLifeTime(0)
					particle:SetDieTime(0.2)
					particle:SetStartAlpha(255)
					particle:SetEndAlpha(0)
					particle:SetStartLength(2)
					particle:SetEndLength(5)
					particle:SetStartSize(2)
					particle:SetEndSize(1)
					particle:SetGravity(gravity)
					
					self.NextParticle = ct + particledelay
				end
			end

			local dlight = DynamicLight(self:EntIndex())
			if (dlight) then
				dlight.pos = pos
				dlight.r = 255
				dlight.g = 150
				dlight.b = 50
				dlight.brightness = 2
				dlight.Decay = 1000
				dlight.Size = 256
				dlight.DieTime = CurTime() + 1
			end
		end
	end

	function ENT:OnRemove()
		if self.Emitter then self.Emitter:Finish() end
	end
end