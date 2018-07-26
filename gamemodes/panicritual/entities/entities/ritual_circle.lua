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
	self:NetworkVar("Int", 0, "Progress")
	self:NetworkVar("Int", 1, "RequiredCharge")
	self:NetworkVar("Bool", 0, "Completed")
	self:NetworkVar("Bool", 1, "HasDoll")
end

local model = "models/panicritual/ritual_circle.mdl"
local candledistance = 100 -- Distance from center to candle positions
function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	--self:SetModel(model)

	self:SetNotSolid(true)
	self:DrawShadow(false)

	if SERVER then
		local size = candledistance --candledistance*0.75
		self:PhysicsInitSphere(size, "default_silent")
		self:SetCollisionBounds(Vector(-size, -size, -size), Vector(size, size, size))

		self:SetTrigger(true)

		self:SetProgress(0)
		self:SetCompleted(false)
		self.VisitedCircles = {}
		self.Candles = {}

		local ang = Angle(0, 360/(self:GetRequiredCharge()), 0)
		for i = 0, self:GetRequiredCharge() - 1 do
			local candle = ents.Create("ritual_circle_candle")
			local pos = self:GetAngles():Forward()*candledistance
			pos:Rotate(ang*i)
			candle:SetPos(self:GetPos() + pos)
			candle:SetAngles((pos:GetNormal()*-1):Angle())
			candle:Spawn()

			self.Candles[i] = candle
		end
	else
		self.Circle = ClientsideModel(model, RENDERGROUP_TRANSLUCENT)
		self.Circle:SetPos(self:GetPos())
		self.Circle:SetAngles(self:GetAngles())
		self.Circle:SetParent(self)
		self.Circle:SetMoveType(MOVETYPE_NONE)
		self.Circle:SetNotSolid(true)
		
		if not LocalPlayer():IsDemon() and GAMEMODE.RoundState == ROUND_PREPARE then
			self.Circle:SetNoDraw(true)
		else
			self:Appear()
		end

		self:SetRenderBounds(Vector(-candledistance,-candledistance,-candledistance), Vector(candledistance,candledistance,candledistance))
	end
end

function ENT:OnRemove()
	if CLIENT and IsValid(self.Circle) then self.Circle:Remove() end
end

if SERVER then
	function ENT:SetProgressRequirement(num)
		self:SetRequiredCharge(num)
	end

	function ENT:SetDoll(doll)
		self.Doll = doll -- Could be a weapon, could be a dropped entity
		self:SetHasDoll(doll.OnRitual)
	end

	-- Spawn or respawn doll on this circle
	function ENT:Reset()
		if not IsValid(self.Doll) then
			local doll = ents.Create("ritual_doll")
			doll:SetRitualCircle(self)
			doll:Spawn()
			self:SetDoll(doll)
		else
			self.Doll:Reset(true)
		end
		
		if not self:GetCompleted() then self:SetProgress(0) end
		self.VisitedCircles = {}
		self:SetHasDoll(true)
	end

	function ENT:StartTouch(ent)
		print(ent, "TOUCHED")
		print(GAMEMODE.RoundState == ROUND_ONGOING and IsValid(ent) and ent:IsPlayer() and ent:IsHuman())
		if GAMEMODE.RoundState == ROUND_ONGOING and IsValid(ent) and ent:IsPlayer() and ent:IsHuman() then
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
				wep:StopDollCleanse(self)
			end
		end
	end

	function ENT:Progress(circle, caller)
		local req = self:GetRequiredCharge() - 1
		if circle == self then
			if self:GetProgress() >= req then
				print("Completed", self)
				self:Complete(caller)
			end
		elseif self:GetProgress() < req and not self.VisitedCircles[circle] then
			self:SetProgress(self:GetProgress() + 1)
			local candle = self.Candles[self:GetProgress()]
			if IsValid(candle) then candle:Complete() end
			self.VisitedCircles[circle] = true
			hook.Run("Ritual_CircleProgressed", self, circle, caller)
		end
	end

	function ENT:AllowCleanse(doll)
		local circle = doll.RitualCircle
		return (circle:GetProgress() >= circle:GetRequiredCharge() - 1) == (circle == self) and not circle:HasCompletedCircle(self)
	end

	function ENT:HasCompletedCircle(circle)
		return self.VisitedCircles[circle] or false
	end

	function ENT:Complete(caller)
		local candle = self.Candles[0]
		if IsValid(candle) then candle:Complete() end

		self.Doll:Reset(true)
		self:SetCompleted(true)

		self:SetProgress(self:GetRequiredCharge())

		hook.Run("Ritual_CircleCompleted", self, caller)
	end
end

if CLIENT then
	function ENT:Draw()
		-- Don't draw the model
	end

	function ENT:Appear()
		if IsValid(self.Circle) then
			self.Circle:SetNoDraw(false)
		end
		
		local e = EffectData()
		e:SetOrigin(self:GetPos())
		e:SetAngles(self:GetAngles())
		e:SetRadius(100) -- Size of bottom circulation
		e:SetScale(100) -- Height of pillar
		e:SetMagnitude(10) -- "thickness" of particles (amount/scale)
		util.Effect("ritual_circlesummon", e, true, true)

		--[[local pcf = CreateParticleSystem(self, "ritual_circle_summon", PATTACH_ABSORIGIN)
		pcf:SetControlPoint(0, self:GetPos())
		pcf:SetControlPoint(1, self:GetPos())]]
	end

	hook.Add("Ritual_RoundBegin", "Ritual_ShowCircles", function()
		for k,v in pairs(ents.FindByClass("ritual_circle_candle")) do
			v:SetNoDraw(false)
		end
		for k,v in pairs(ents.FindByClass("ritual_circle")) do
			if IsValid(v.Circle) and v.Circle:GetNoDraw() then
				v:Appear()
			end
		end
	end)
end