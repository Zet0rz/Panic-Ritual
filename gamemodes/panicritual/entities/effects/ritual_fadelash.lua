local lifetime = 0.5
local growtime = 0.1
local numswirls = 20

local colors = {
	{100,0,150},
	{0,0,0},
	{150,0,150},
	{0,0,0},
	{50,0,150},
	{0,0,0},
	{50,0,100},
	{0,0,0},
	{20,0,50},
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

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Radius = data:GetRadius()
	
	self.KillTime = CurTime() + lifetime
	
	self.Emitter = ParticleEmitter(self.Pos, true)

	self.Particles = {}
	for i = 1, numswirls do
		self.Particles[i] = {
			color = colors[math.random(#colors)],
			mat = swirls[math.random(#swirls)],
			ang = Angle(90 + math.random(-10,10),math.random(360), math.random(-10,10)),
		}

		local particle = self.Emitter:Add(self.Particles[i].mat, self.Pos)
		if particle then
			particle:SetColor(unpack(self.Particles[i].color))
			particle:SetLifeTime(0)
			particle:SetAngles(self.Particles[i].ang)
			particle:SetDieTime(growtime)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)
			particle:SetStartSize(0)
			particle:SetEndSize(self.Radius)
		end
	end

	self.NextParticleSet = CurTime() + growtime
end



function EFFECT:Think()
	local ct = CurTime()

	if self.NextParticleSet and ct >= self.NextParticleSet then
		for k,v in pairs(self.Particles) do
			local particle = self.Emitter:Add(v.mat, self.Pos)
			if particle then
				particle:SetColor(unpack(v.color))
				particle:SetLifeTime(0)
				particle:SetAngles(v.ang)
				particle:SetDieTime(lifetime)
				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)
				particle:SetStartSize(self.Radius)
				particle:SetEndSize(self.Radius*1.2)
			end
		end

		self.NextParticleSet = nil
	end

	return ct < self.KillTime
end

function EFFECT:Render()
	
end
