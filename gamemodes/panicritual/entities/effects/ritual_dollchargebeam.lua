
local beamtime = 0.5
local ringtime = 0.25
local beamdelay = 0.01
local numbeamrings = 5
local height = 500
local size = 50

local particles = {
	"panicritual/particles/fade/fade_trail_head",
}
local swirls = {
	"panicritual/particles/fade/fade_swirl_wave_8",
	"panicritual/particles/fade/fade_swirl_wave_7",
	"panicritual/particles/fade/fade_swirl_wave_6",
	"panicritual/particles/fade/fade_swirl_wave_5",
	"panicritual/particles/fade/fade_swirl_wave_4",
	"panicritual/particles/fade/fade_swirl_wave_3",
	"panicritual/particles/fade/fade_swirl_wave_2",
}
local colors = {
	{170,230,255},
	{255,255,255},
	{200,255,255},
}

function EFFECT:Init(data)
	self.Pos = data:GetOrigin()
	self.Height = data:GetMagnitude()*1.5
	self.Radius = data:GetRadius()
	self.ParticleSize = data:GetScale()

	self.KillTime = CurTime() + beamtime

	self.Emitter = ParticleEmitter(self.Pos)
	self.Emitter2 = ParticleEmitter(self.Pos, true)

	for i = 1, numbeamrings do
		local particle = self.Emitter2:Add(swirls[math.random(#swirls)], self.Pos)
		if particle then
			particle:SetColor(unpack(colors[math.random(#colors)]))
			particle:SetLifeTime(0)
			particle:SetAngles(Angle(90 + math.random(-10,10),math.random(360), math.random(-10,10)))
			particle:SetDieTime(ringtime)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)
			particle:SetStartSize(0)
			particle:SetEndSize(self.Radius)
		end
	end

	self.NextBeamRise = 0
end

function EFFECT:Think()
	local ct = CurTime()
	
	if ct >= self.NextBeamRise then
		local particle = self.Emitter:Add(particles[math.random(#particles)], self.Pos + Angle(0,math.random(360),0):Forward()*self.Radius/10 - Vector(0,0,self.Height/2))
		if (particle) then
			particle:SetColor(unpack(colors[math.random(#colors)]))
			local diff = self.KillTime - ct
			particle:SetLifeTime(beamtime - diff)
			particle:SetDieTime(beamtime)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			particle:SetStartSize(size*self.ParticleSize)
			particle:SetEndSize(size*self.ParticleSize)
			particle:SetStartLength(self.Height)
			particle:SetEndLength(self.Height)
			particle:SetVelocity(Vector(0,0,self.Height))
			particle:SetAirResistance(0)
		end
		self.NextBeamRise = ct + beamdelay
	end

	return ct < self.KillTime
end

function EFFECT:Render()
	
end
