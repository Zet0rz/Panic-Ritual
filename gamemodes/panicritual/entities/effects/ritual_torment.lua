
local ghostlifetime = 5
local ghostdelay = 0.5
local numinitialperbone = 1
local bones = {
	{"ValveBiped.Bip01_Pelvis", Vector(0,0,0), 15},
	{"ValveBiped.Bip01_Spine", Vector(0,0,0), 14},
	{"ValveBiped.Bip01_Spine1", Vector(0,0,0), 13},
	{"ValveBiped.Bip01_Spine2", Vector(0,0,0), 14},
	{"ValveBiped.Bip01_Spine4", Vector(0,0,0), 15},

	--{"ValveBiped.Bip01_Head1", Vector(0,0,0)},
	{"ValveBiped.Bip01_Head1", Vector(5,0,0), 10},

	{"ValveBiped.Bip01_R_Clavicle", Vector(0,0,0), 8},
	{"ValveBiped.Bip01_R_UpperArm", Vector(0,0,0), 7},
	{"ValveBiped.Bip01_R_UpperArm", Vector(3,0,0), 7},
	{"ValveBiped.Bip01_R_UpperArm", Vector(6,0,0), 6},
	{"ValveBiped.Bip01_R_UpperArm", Vector(9,0,0), 6},
	{"ValveBiped.Bip01_R_Forearm", Vector(0,0,0), 6},
	{"ValveBiped.Bip01_R_Forearm", Vector(3,0,0), 6},
	{"ValveBiped.Bip01_R_Forearm", Vector(6,0,0), 6},

	{"ValveBiped.Bip01_L_Clavicle", Vector(0,0,0), 8},
	{"ValveBiped.Bip01_L_UpperArm", Vector(0,0,0), 7},
	{"ValveBiped.Bip01_L_UpperArm", Vector(3,0,0), 7},
	{"ValveBiped.Bip01_L_UpperArm", Vector(6,0,0), 6},
	{"ValveBiped.Bip01_L_UpperArm", Vector(9,0,0), 6},
	{"ValveBiped.Bip01_L_Forearm", Vector(0,0,0), 6},
	{"ValveBiped.Bip01_L_Forearm", Vector(3,0,0), 6},
	{"ValveBiped.Bip01_L_Forearm", Vector(6,0,0), 6},

	{"ValveBiped.Bip01_R_Thigh", Vector(0,0,0), 9},
	{"ValveBiped.Bip01_R_Thigh", Vector(5,0,0), 8},
	{"ValveBiped.Bip01_R_Thigh", Vector(9,0,0), 8},
	{"ValveBiped.Bip01_R_Calf", Vector(0,0,0), 8},
	{"ValveBiped.Bip01_R_Calf", Vector(4,0,0), 7},
	{"ValveBiped.Bip01_R_Calf", Vector(7,0,0), 7},
	{"ValveBiped.Bip01_R_Calf", Vector(11,0,0), 7},
	{"ValveBiped.Bip01_R_Foot", Vector(0,0,0), 6},

	{"ValveBiped.Bip01_L_Thigh", Vector(0,0,0), 9},
	{"ValveBiped.Bip01_L_Thigh", Vector(5,0,0), 8},
	{"ValveBiped.Bip01_L_Thigh", Vector(9,0,0), 8},
	{"ValveBiped.Bip01_L_Calf", Vector(0,0,0), 8},
	{"ValveBiped.Bip01_L_Calf", Vector(4,0,0), 7},
	{"ValveBiped.Bip01_L_Calf", Vector(7,0,0), 7},
	{"ValveBiped.Bip01_L_Calf", Vector(11,0,0), 7},
	{"ValveBiped.Bip01_L_Foot", Vector(0,0,0), 6},
}

local soundeffect = Sound("ambient/levels/citadel/portal_beam_shoot5.wav")
local particles = {
	"panicritual/particles/fade/fade_trail",
}
local ghostparticles = {
	"panicritual/particles/fade/fade_trail_head",
}

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
local ghostcolors = {
	{170,230,255},
	{255,255,255},
	{200,255,255},
}

local function ScaleDirection(ang, vec)
	return ang:Forward()*vec.x + ang:Right()*vec.y + ang:Up()*vec.z
end

function EFFECT:Init( data )
	self.Entity = data:GetEntity()
	self.Radius = data:GetRadius()
	
	self.GhostAppear = CurTime() + ghostdelay
	
	self.Emitter = ParticleEmitter(self.Entity:GetPos())
	
	sound.Play(soundeffect, self.Entity:GetPos(), 75, 100, 1)

	for k,v in pairs(bones) do
		for i = 1, numinitialperbone do
			local pos, ang = self.Entity:GetBonePosition(self.Entity:LookupBone(v[1]))

			local particle = self.Emitter:Add(particles[math.random(#particles)], pos + ScaleDirection(ang, v[2]))
			if (particle) then
				--particle:SetVelocity( Vector(0,0,100) )
				particle:SetColor(unpack(colors[math.random(#colors)]))
				particle:SetLifeTime(0)
				particle:SetDieTime(ghostdelay)
				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)
				particle:SetStartSize(self.Radius)
				particle:SetVelocity(VectorRand()*500)
				particle:SetAirResistance(1750)
			end
		end
	end	
end

function EFFECT:Think()
	local ct = CurTime()
	if ct >= self.GhostAppear then
		for k,v in pairs(bones) do
			local pos, ang = self.Entity:GetBonePosition(self.Entity:LookupBone(v[1]))

			local particle = self.Emitter:Add(ghostparticles[math.random(#ghostparticles)], pos + ScaleDirection(ang, v[2]))
			if (particle) then
				--particle:SetVelocity( Vector(0,0,100) )
				particle:SetColor(unpack(ghostcolors[math.random(#ghostcolors)]))
				particle:SetLifeTime(0)
				particle:SetDieTime(ghostlifetime)
				particle:SetStartAlpha(150)
				particle:SetEndAlpha(0)
				particle:SetStartSize(v[3])
				particle:SetEndSize(v[3])
			end
		end
		return false
	end
	return true
end

function EFFECT:Render()
	
end
