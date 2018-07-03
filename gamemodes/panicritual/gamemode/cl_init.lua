include( "shared.lua" )
include( "cl_jumpscares.lua" )
include( "player_meta.lua" )
include("animations.lua")

--include("demonmaul.lua")
include("demonsoulsiphon.lua")

-- Sound effects used by the gamemode
util.PrecacheSound("sound/ambient/fire/mtov_flame2.wav") -- Reset doll burn
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing1.wav") -- Doll whisper
util.PrecacheSound("sound/ambient/creatures/town_scared_breathing2.wav") -- Doll whisper 2 (shorter)


local ccNight = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0.01,
	["$pp_colour_brightness"] = -0.03,
	["$pp_colour_contrast"] = 0.5,
	["$pp_colour_colour"] = 1,
	["$pp_colour_mulr"] = 1.5,
	["$pp_colour_mulg"] = 1.5,
	["$pp_colour_mulb"] = 1.5
}

-- Lightning strike! Then fade into dark fog + color correct
local roundon = false
local lightning = false
local fade = 0
local rising = true
function FogAppear()
	fade = 0
	rising = true
	lightning = true
end

function FogClear()
	roundon = false
end

function GM:RenderScreenspaceEffects()
	if roundon then DrawColorModify(ccNight) end

	if lightning then
		if rising then
			fade = fade + 5000*FrameTime()
			if fade >= 1000 then 
				fade = 255
				rising = false
				roundon = true
			end
		else
			fade = fade - 100*FrameTime()
			if fade <= 0 then
				lightning = false
			end
		end
		surface.SetDrawColor(200,200,200,fade)
		surface.DrawRect(-ScrW(),-ScrH(),ScrW()*2,ScrH()*2)
	end
end

function GM:SetupWorldFog()

	if roundon then
		render.FogMode(1)
		render.FogMaxDensity(1)
		render.FogColor(10,0,0)
		render.FogStart(-1000)
		render.FogEnd(650)
		
		return true
	end

end

function GM:SetupSkyboxFog(scale)
	if roundon then
		render.FogMode(1)
		render.FogMaxDensity(1)
		render.FogColor(0,0,0)
		render.FogStart(-100 * scale)
		render.FogEnd(650 * scale)
		return true
	end

end