local particledelay = 0.005

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
local headcolors = {
	{170,230,255},
	{255,255,255},
	{200,255,255},
}

function EFFECT:Init( data )
	self.Entity = data:GetEntity()
	self.Radius = data:GetScale()
	self.NumTrails = math.Round(data:GetMagnitude())

	local maxradius
	local minradius
	if self.Entity == LocalPlayer() then
		maxradius = 30
		minradius = 20
		
		self.Emitter = ParticleEmitter(EyePos())

		self.TrailPos = {}
		local aim = EyeAngles()
		for i = 1, self.NumTrails do
			local ran = math.Rand(minradius, maxradius)
			local ranang = (math.Rand(0,360/self.NumTrails)) * i
			self.TrailPos[i] = {{math.cos(ranang)*ran, math.sin(ranang)*ran},0}
		end

		self.IsLocalPlayer = true
	else
		maxradius = data:GetRadius()
		minradius = 1
		self.Offset = data:GetOrigin()

		self.MaxDist = maxradius^2
		self.MinDist = minradius^2

		self.Emitter = ParticleEmitter(self.Entity:GetPos() + self.Offset)

		self.TrailPos = {}
		for i = 1, self.NumTrails do
			local ran = math.Rand(minradius, maxradius)
			self.TrailPos[i] = {AngleRand():Forward()*ran,0}
		end
	end

	self.MaxDist = maxradius^2
	self.MinDist = minradius^2

	self.NextParticle = CurTime()
end

local particles = {
	"panicritual/particles/fade/fade_trail",
}
local headparticles = {
	"panicritual/particles/fade/fade_trail_head",
}
local turnaccel = 10
local eyedist = 50

function EFFECT:Think()
	local ct = CurTime()
	if ct >= self.NextParticle then
		local vel = self.Entity:GetVelocity():Angle()
		for k,v in pairs(self.TrailPos) do
			local pos

			if self.IsLocalPlayer then
				local entpos = EyePos() + vel:Forward()*eyedist
				local a = v[2] + math.Rand(-turnaccel, turnaccel)
				local p = {v[1][1] + math.sin(a), v[1][2] + math.cos(a)}

				local dist = p[1]^2 + p[2]^2
				if dist > self.MaxDist or dist < self.MinDist then
					a = a*-1
					p = {v[1][1] + math.sin(a), v[1][2] + math.cos(a)}
				end

				pos = entpos + vel:Up()*p[1] + vel:Right()*p[2]
				self.TrailPos[k] = {p,a}
			else
				local entpos = self.Entity:GetPos() + self.Offset
				local a = v[2] + math.Rand(-turnaccel, turnaccel)
				local p = v[1] + vel:Up()*math.sin(a) + vel:Right()*math.cos(a)

				local dist =p:DistToSqr(entpos) 
				if dist > self.MaxDist or dist < self.MinDist then
					a = a*-1
					p = v[1] + vel:Up()*math.sin(a) + vel:Right()*math.cos(a)
				end

				pos = entpos + p
				self.TrailPos[k] = {p,a}
			end

			

			local particle = self.Emitter:Add(particles[math.random(#particles)], pos)
			if (particle) then
				--particle:SetVelocity( Vector(0,0,100) )
				particle:SetColor(unpack(colors[math.random(#colors)]))
				particle:SetLifeTime(0)
				particle:SetDieTime(1)
				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)
				local r = self.Radius
				particle:SetStartSize(r)
				particle:SetEndSize(r)
			end

			particle = self.Emitter:Add(headparticles[math.random(#headparticles)], pos)
			if (particle) then
				--particle:SetVelocity( Vector(0,0,100) )
				particle:SetColor(unpack(headcolors[math.random(#headcolors)]))
				particle:SetLifeTime(0)
				particle:SetDieTime(0.2)
				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)
				local r = self.Radius*0.5
				particle:SetStartSize(r)
				particle:SetEndSize(r*0.9)
			end
		end
		self.NextParticle = CurTime() + particledelay
	end

	if not IsValid(self.Entity) or not self.Entity:GetFading() then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	
end
