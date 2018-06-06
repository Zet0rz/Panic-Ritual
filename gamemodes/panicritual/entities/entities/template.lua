
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Empty"
ENT.Author			= "Zet0r"
ENT.Information		= "Copy paste template"
ENT.Category		= "Panic Ritual"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_BOTH

function ENT:SetupDataTables()
	--self:NetworkVar( "Bool", 0, "PlayerExplosion")
	--self:NetworkVar( "Int", 0, "SoundID", { KeyName = "soundid", Edit = {  } } )
end

function ENT:Initialize()
	
end

function ENT:UpdateTransmitState()
	--return TRANSMIT_ALWAYS
end

if CLIENT then
	function ENT:Draw()
		return
	end
end

function ENT:Think()
	
end