AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Ritual Circle Candle"
ENT.Author			= "Zet0r"
ENT.Information		= "An indicator of this Circle's progress."
ENT.Category		= "Panic Ritual"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_BOTH

local offmodel = "models/Gibs/HGIBS_spine.mdl"
local onmodel = "models/Gibs/HGIBS.mdl"

util.PrecacheModel(offmodel)
util.PrecacheModel(onmodel)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
end

function ENT:Initialize()
	self:SetModel(offmodel)
	self:SetLit(false)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetNotSolid(true)
end

function ENT:Complete()
	self:SetModel(onmodel)
	self:SetLit(true)
end

if CLIENT then
	
end