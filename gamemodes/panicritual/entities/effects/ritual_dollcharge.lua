
local numparticles = 10
local particlesize = 100

local particles = {
	"panicritual/particles/fade/fade_trail_head",
}
local colors = {
	{170,230,255},
	{255,255,255},
	{200,255,255},
}

function EFFECT:Init(data)
	self.Entity = data:GetEntity()

	print(self.Entity, self, self.Entity.ChargeEffect)

	local flags = data:GetFlags()
	if flags and data:GetFlags() == 1 then
		if IsValid(self.Entity.ChargeEffect) then
			print("Killing", self.Entity.ChargeEffect.Emitter)
			self.Entity.ChargeEffect.Emitter:Finish()
			self.Entity.ChargeEffect:Remove()
		end
		self:Remove()
		print("Should kill")
	return end

	self.Radius = data:GetRadius()
	self.TargetPos = data:GetOrigin()
	self.ParticleSize = data:GetMagnitude() or 1
	local time = data:GetScale() or 5
	self.Time = CurTime() + time
	
	self.Pos = data:GetStart()
	self.Emitter = ParticleEmitter(self.Pos)

	local grav = (self.TargetPos - self.Pos)/time/2

	local ang = Angle(0,360/numparticles,0)
	for i = 1, numparticles do
		local a = (ang*i):Forward()
		local particle = self.Emitter:Add(particles[math.random(#particles)], self.Pos + a*self.Radius)
		if (particle) then
			particle:SetColor(unpack(colors[math.random(#colors)]))
			particle:SetLifeTime(0)
			particle:SetDieTime(time)
			particle:SetStartAlpha(0)
			particle:SetEndAlpha(255)
			particle:SetStartSize(self.ParticleSize*particlesize)
			particle:SetVelocity((a*-self.Radius)/time)
			particle:SetAirResistance(0)
			particle:SetGravity(grav)
			particle:SetAlpha(0)
		end
	end
	self.KillTime = CurTime() + time

	self.Entity.ChargeEffect = self
end

function EFFECT:Think()
	return not self.KILL and CurTime() < self.KillTime
end

function EFFECT:Render()
	
end
