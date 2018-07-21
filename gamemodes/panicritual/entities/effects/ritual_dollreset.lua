
local particles = {}

particles[1] = {}
for i = 1, 18 do
	local str = tostring(i)
	for i = 1, 3-#str do str = "0"..str end
	particles[1][i] = Material("panicritual/particles/fire/particle_2_frames/"..str)
end

particles[2] = {}
for i = 1, 25 do
	local str = tostring(i)
	for i = 1, 3-#str do str = "0"..str end
	particles[2][i] = Material("panicritual/particles/fire/particle_7_frames_1/"..str)
end

particles[3] = {}
for i = 1, 28 do
	local str = tostring(i + 28)
	for i = 1, 3-#str do str = "0"..str end
	particles[3][i] = Material("panicritual/particles/fire/particle_7_frames_1/"..str)
end
particles[4] = nil

local mins = Vector(-1,-1,-1)
local maxs = Vector(1,1,1)

local numparticles = 5
local emitdelay = 0.05
local risetime = 0.2
local risefadeout = 0.5

local soundeffect = Sound("sound/ambient/fire/mtov_flame2.wav")

function EFFECT:Init( data )
	self.Ent = data:GetEntity()
	if self.Ent:IsWeapon() and self.Ent:IsCarriedByLocalPlayer() then self.Ent = LocalPlayer():GetViewModel() end

	local attachment = data:GetAttachment()
	if attachment > 0 then
		self.Attachment = attachment
	elseif data:GetFlags() == 1 then
		self.RelativeToView = true
	end

	self.StartPos = data:GetStart()
	self.EndPos = data:GetOrigin()
	self.Norm = (self.EndPos - self.StartPos):GetNormal()
	self.Radius = data:GetRadius()
	self.Scatter = data:GetScale()

	self:SetRenderBounds(self.StartPos, self.EndPos)
	self.KillTime = CurTime() + risetime + risefadeout
	self.StartTime = CurTime()

	self:SetParent(self.Ent)
	self:SetMoveType(MOVETYPE_NONE)

	sound.Play(soundeffect, self.StartPos, 75, 100, 1)

	local e = self.Ent

	-- Take over the rendering function of the entity
	self.OldRenderFunc = e.RenderOverride
	e.RenderOverride = function(ent)
		if not IsValid(self) then
			ent.RenderOverride = nil
			return
		end
		self:RenderClipPlane(ent)
	end

	self.Particles = {}
	for i = 1, numparticles do
		self.Particles[i] = {math.random(3), VectorRand()*self.Scatter}
	end
end

function EFFECT:Think()
	local ct = CurTime()
	if ct > self.KillTime then
		self.Ent.RenderOverride = self.OldRenderFunc -- Restore the function before killing
		return false
	end
	return true
end

function EFFECT:OnRemove()
	print("Effect: OnRemove")
	self.Ent.RenderOverride = self.OldRenderFunc -- This run?
end

function EFFECT:Render()

end

function EFFECT:RenderClipPlane(ent)
	local difft = CurTime() - self.StartTime
	local diff = difft/risetime

	local pos = LerpVector(diff, self.StartPos, self.EndPos)
	local norm = self.Norm

	if self.RelativeToView then
		local p,a = LocalToWorld(pos, Angle(), EyePos(), EyeAngles())
		pos = p
	elseif self.Attachment then
		local att
		if diff >= 1 then
			att = self.LastAttCache
		else
			att = ent:GetAttachment(self.Attachment)
			self.LastAttCache = att
		end

		local p,a = LocalToWorld(pos, Angle(), att.Pos, Angle(0,att.Ang[2],0))
		pos = p
		--norm = a:Forward()
	else
		pos = ent:GetPos() + pos
	end
	

	-- Render a clipping plane on the model to make it disappear behind the flame
	local oldclip = render.EnableClipping(true)
		render.PushCustomClipPlane(norm, norm:Dot(pos))
			ent:DrawModel()
		render.PopCustomClipPlane()
	render.EnableClipping(oldclip)

	local alpha = difft <= risetime and 255 or (1 - (difft - risetime)/risefadeout)*255
	local framepct = difft/(risetime + risefadeout)

	for k,v in pairs(self.Particles) do
		local ps = particles[v[1]]
		local numframes = #ps
		local frame = math.Clamp(math.Round(framepct*numframes), 1, numframes)

		render.SetMaterial(ps[frame])
		render.DrawSprite(pos + v[2], self.Radius, self.Radius, Color(255,255,255,alpha))
	end
end