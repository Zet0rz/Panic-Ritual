
--local mat = Material("panicritual/tracers/laserbeam")
--local mat = Material("panicritual/tracers/crystal_beam1")
local mat2 = Material("cable/xbeam")
local mat1 = Material("cable/hydra")

local size1 = 16
local size2 = 8

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment)
	self.EndPos = data:GetOrigin()

	self.Alpha = 255
	self.Life = 0

	self:SetRenderBoundsWS(self.StartPos, self.EndPos)

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 4
	self.Alpha = 255 * (1 - self.Life)

	return (self.Life < 1)

end

function EFFECT:Render()

	if (self.Alpha < 1) then return end

	local texcoord = math.Rand(0, 1)

	local norm = (self.StartPos - self.EndPos) * self.Life

	self.Length = norm:Length()

	render.SetMaterial(mat2)
	render.DrawBeam(self.StartPos,
					self.EndPos,
					size2,
					texcoord,
					texcoord + ((self.StartPos - self.EndPos):Length() / 128),
					Color(255, 255, 255, 128 * (1 - self.Life)))

	render.SetMaterial(mat2)
	for i = 1, 3 do
		render.DrawBeam(self.StartPos - norm,	-- Start
					self.EndPos,				-- End
					size1,						-- Width
					texcoord,					-- Start tex coord
					texcoord + self.Length/128,	-- End tex coord
					Color(255, 255, 255))		-- Color (optional)
	end

end