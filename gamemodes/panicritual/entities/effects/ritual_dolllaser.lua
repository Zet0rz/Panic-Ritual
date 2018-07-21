
--local mat = Material("panicritual/tracers/laserbeam")
--local mat = Material("panicritual/tracers/crystal_beam1")
local mat2 = Material("effects/tool_tracer")
local mat1 = Material("cable/xbeam")

local size1 = 24
local size2 = 8
local lifetime = 10

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	-- Keep the start and end pos - we're going to interpolate between them
	--self.StartPos = self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment)
	self.EndPos = data:GetOrigin()

	self.Alpha = 255
	self.Life = 0

	self:SetRenderBoundsWS(self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment), self.EndPos)

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * lifetime
	self.Alpha = 255 * (1 - self.Life)

	return (self.Life < 1)

end

function EFFECT:Render()

	if (self.Alpha < 1) then return end

	local texcoord = math.Rand(0, 1)

	local spos = self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment)

	local norm = (spos - self.EndPos) * self.Life

	self.Length = norm:Length()

	render.SetMaterial(mat1)
	render.DrawBeam(spos,
					self.EndPos,
					size2,
					texcoord,
					texcoord + ((spos - self.EndPos):Length() / 128),
					Color(255, 255, 255, 128 * (1 - self.Life)))

	render.SetMaterial(mat2)
	for i = 1, 1 do
		render.DrawBeam(spos - norm,	-- Start
					self.EndPos,				-- End
					size1,						-- Width
					texcoord,					-- Start tex coord
					texcoord + self.Length/128,	-- End tex coord
					Color(255, 255, 255))		-- Color (optional)
	end

end