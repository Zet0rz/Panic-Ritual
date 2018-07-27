
local fadetime = 5

if SERVER then
	local fov = 50
	hook.Add("Ritual_RoundBegin", "Ritual_BeginFOV", function()
		for k,v in pairs(team.GetPlayers(TEAM_HUMANS)) do
			v:SetFOV(fov,fadetime)
		end

		--[[for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
			v:SetFading(true)
			v:SetNoDraw(false)
		end]]

		local fadecomplete = CurTime() + fadetime
		hook.Add("Think", "Ritual_RoundFade", function()
			if CurTime() >= fadecomplete then
				for k,v in pairs(team.GetPlayers(TEAM_HUMANS)) do
					v:SetFOV(0,0.2)
				end

				--[[for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
					v:SetFading(false)
				end]]

				hook.Remove("Think", "Ritual_RoundFade")
			end
		end)
	end)
end

if CLIENT then
	local fogminrange = 600
	local fogmaxrange = 5000
	local fadesound = Sound("panicritual/roundstart.wav")
	local ccRound = {
		["$pp_colour_addr"] = 0.02,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1,
		["$pp_colour_mulr"] = 1,
		["$pp_colour_mulg"] = 1,
		["$pp_colour_mulb"] = 1
	}

	local skytopcolor = Vector(1,1,1)

	local fogdensity = 0
	local fogrange = fogmaxrange
	local cc = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1,
		["$pp_colour_mulr"] = 1,
		["$pp_colour_mulg"] = 1,
		["$pp_colour_mulb"] = 1
	}
	local function RoundEffectChange(b)
		local starttime = CurTime()
		local finishtime = starttime + fadetime
		if b then
			util.ScreenShake(EyePos(), 5, 5, fadetime, 50)
			surface.PlaySound(fadesound)
		end

		hook.Add("RenderScreenspaceEffects", "Ritual_RoundFade", function()
			local ct = CurTime()
			local range
			local toremove = ct >= finishtime
			local range = toremove and 1 or (ct - starttime)/fadetime

			if not b then range = 1 - range end

			fogdensity = range
			fogrange = Lerp(range, fogmaxrange, fogminrange)
			cc["$pp_colour_addr"] = range*ccRound["$pp_colour_addr"]
			cc["$pp_colour_addg"] = range*ccRound["$pp_colour_addg"]
			cc["$pp_colour_addb"] = range*ccRound["$pp_colour_addb"]
			cc["$pp_colour_brightness"] = range*ccRound["$pp_colour_brightness"]
			cc["$pp_colour_contrast"] = Lerp(range, 1, ccRound["$pp_colour_contrast"])
			cc["$pp_colour_colour"] = Lerp(range, 1, ccRound["$pp_colour_colour"])
			cc["$pp_colour_mulr"] = Lerp(range, 1, ccRound["$pp_colour_mulr"])
			cc["$pp_colour_mulg"] = Lerp(range, 1, ccRound["$pp_colour_mulg"])
			cc["$pp_colour_mulb"] = Lerp(range, 1, ccRound["$pp_colour_mulb"])

			
			if b then
				DrawMotionBlur(0.4, 0.6, 0.05)
			end

			if toremove then
				hook.Remove("RenderScreenspaceEffects", "Ritual_RoundFade")
			end
		end)
	end
	
	function GM:SetupWorldFog()
		render.FogMode(MATERIAL_FOG_LINEAR)
		render.FogColor(15,0,0)
		render.FogEnd(fogrange)
		if LocalPlayer():IsDemon() then
			render.FogStart(-1000)
			render.FogMaxDensity(fogdensity*0.99)
		else
			render.FogStart(-1000)
			render.FogMaxDensity(fogdensity)
		end

		return true
	end

	function GM:SetupSkyboxFog()
		render.FogMode(MATERIAL_FOG_LINEAR)
		render.FogColor(15,0,0)
		render.FogStart(-10000)
		render.FogEnd(fogrange*0.5)
		render.FogMaxDensity(fogdensity)

		return true
	end

	function GM:RenderScreenspaceEffects()
		DrawColorModify(cc)
	end

	hook.Add("Ritual_RoundBegin", "Ritual_RoundFadeIn", function() RoundEffectChange(true) end)
	hook.Add("Ritual_RoundInit", "Ritual_RoundFadeOff", function()
	--hook.Add("PostCleanupMap", "Ritual_RoundFadeOff", function()
		fogdensity = 0
		fogrange = fogmaxrange
		cc = {
			["$pp_colour_addr"] = 0,
			["$pp_colour_addg"] = 0,
			["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = 0,
			["$pp_colour_contrast"] = 1,
			["$pp_colour_colour"] = 1,
			["$pp_colour_mulr"] = 1,
			["$pp_colour_mulg"] = 1,
			["$pp_colour_mulb"] = 1
		}
	end)

	-- Our own skypaint modifier
	local skypaint = {
		TopColor = Vector(0,0,0),
		BottomColor = Vector(0,0,0),
		SunNormal = Vector(0,0,-1),
		SunColor = Vector(0,0,0),
		DuskColor = Vector(0.1,0,0),
		FadeBias = 1,
		HDRScale = 1,
		DuskScale = 1,
		DuskIntensity = 1,
		SunSize = 0
	}
	function skypaint:GetTopColor() return self.TopColor end
	function skypaint:GetBottomColor() return self.BottomColor end
	function skypaint:GetSunNormal() return self.SunNormal end
	function skypaint:GetSunColor() return self.SunColor end
	function skypaint:GetDuskColor() return self.DuskColor end
	function skypaint:GetFadeBias() return self.FadeBias end
	function skypaint:GetHDRScale() return self.HDRScale end
	function skypaint:GetDuskScale() return self.DuskScale end
	function skypaint:GetDuskIntensity() return self.DuskIntensity end
	function skypaint:GetSunSize() return self.SunSize end

	function skypaint:GetDrawStars() return false end

	g_SkyPaint = skypaint
end