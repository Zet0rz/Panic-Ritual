local lifetime = 0.1 -- Time with total effect (rising particles)
local riseparticledelay = 0.01
local numswirls = 10

local soundeffect = Sound("ambient/levels/citadel/portal_beam_shoot5.wav")
local swirl = "panicritual/particles/fade/fade_swirl_01"
local range = 0.25

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

function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Radius = data:GetRadius()

	self.MaxRadius = self.Radius + self.Radius*range
	self.MinRadius = self.Radius - self.Radius*range
	
	self.NextRiseParticle = CurTime()
	self.KillTime = CurTime() + lifetime
	
	self.Emitter = ParticleEmitter(self.Pos)
	
	sound.Play(soundeffect, self.Pos, 75, 100, 1)
	
	--print(self.Emitter, self.NextParticle, self, self.Player)

	for i = 1, numswirls do
		local particle = self.Emitter:Add(swirl, self.Pos)
		if (particle) then
			--particle:SetVelocity( Vector(0,0,100) )
			particle:SetColor(unpack(colors[math.random(#colors)]))
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.25,0.35))
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)
			particle:SetStartSize(0)
			particle:SetEndSize(math.Rand(self.MinRadius,self.MaxRadius))
			particle:SetRoll(math.Rand(0, 36)*10)
			particle:SetRollDelta(math.Rand(20,30))
		end
	end
	
end

local swirls = {
	"panicritual/particles/fade/fade_swirl_wave_8",
	"panicritual/particles/fade/fade_swirl_wave_7",
	"panicritual/particles/fade/fade_swirl_wave_6",
	"panicritual/particles/fade/fade_swirl_wave_5",
	"panicritual/particles/fade/fade_swirl_wave_4",
	"panicritual/particles/fade/fade_swirl_wave_3",
	"panicritual/particles/fade/fade_swirl_wave_2",
}

function EFFECT:Think()
	local ct = CurTime()
	if ct >= self.NextRiseParticle then
		local particle = self.Emitter:Add(swirls[math.random(#swirls)], self.Pos)
		if (particle) then
			--particle:SetVelocity( Vector(0,0,100) )
			particle:SetColor(unpack(colors[math.random(#colors)]))
			particle:SetLifeTime(0)
			particle:SetDieTime(0.5)
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(0)
			local r = math.Rand(self.MinRadius,self.MaxRadius)
			particle:SetStartSize(r*0.25)
			particle:SetEndSize(r*0.75)
			particle:SetRoll(math.Rand(0, 36)*10)
			particle:SetRollDelta(math.Rand(5,10))
			
			self.NextRiseParticle = CurTime() + riseparticledelay
			return true
		end
	end
	if self.KillTime < ct then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	
end
