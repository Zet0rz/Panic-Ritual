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
	self:SetModel(model)

	self:SetNotSolid(true)

	if SERVER then
		local size = candledistance --candledistance*0.75
		self:PhysicsInitSphere(size, "default_silent")
		self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))

		self:SetTrigger(true)

		self.CurrentProgress = 0
		self.VisitedCircles = {}
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

	-- Spawn or respawn doll on this circle
	function ENT:Reset()
		if not IsValid(self.Doll) then
			local doll = ents.Create("ritual_doll")
			doll:SetRitualCircle(self)
			self:SetDoll(doll)
			doll:Spawn()
		else
			self.Doll:Reset(true)
		end
		
		self.CurrentProgress = 0
		self.VisitedCircles = {}
	end

	function ENT:StartTouch(ent)
		if IsValid(ent) and ent:IsPlayer() and ent:IsHuman() then
			local wep = ent:GetWeapon("ritual_human")
			if IsValid(wep) and wep:GetHasDoll() then
				print("Starting cleanse")
				wep:StartDollCleanse(self)
			end
		end
	end

	function ENT:EndTouch(ent)
		if IsValid(ent) and ent:IsPlayer() and ent:IsHuman() then
			local wep = ent:GetWeapon("ritual_human")
			if IsValid(wep) and wep:GetHasDoll() then
				print("Stopping cleanse")
				wep:StopDollCleanse(self)
			end
		end
	end

	function ENT:Progress(circle)
		if circle == self then
			if self.CurrentProgress >= self.RequiredCharge then
				print("Completed", self)
				self:Complete()
			end
		elseif self.CurrentProgress < self.RequiredCharge and not self.VisitedCircles[circle] then
			self.CurrentProgress = self.CurrentProgress + 1
			print("Progressed", self, "to", self.CurrentProgress)
			local candle = self.Candles[self.CurrentProgress]
			if IsValid(candle) then candle:Complete() end
			self.VisitedCircles[circle] = true
		end
	end

	function ENT:AllowCleanse(doll)
		local circle = doll.RitualCircle
		return (circle.CurrentProgress >= circle.RequiredCharge) == (circle == self) and not circle:HasCompletedCircle(self)
	end

	function ENT:HasCompletedCircle(circle)
		return self.VisitedCircles[circle] or false
	end

	function ENT:Complete()
		local candle = self.Candles[0]
		if IsValid(candle) then candle:Complete() end

		self.Doll:Reset(true)
		self.IsComplete = true
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		--render.DrawSphere(self:GetPos(), candledistance, 100, 100, Color(255,255,255))
	end
end

function ENT:Think()
	
end