
local fadetime = 5

if SERVER then
	local fov = 50

	local stop = Vector(0.0,0,0)
	local sbot = Vector(0.1,0,0)
	local sdusk = Vector(0,0,0)
	local sdint = 0
	local sdsca = 1
	local ssun = Vector(0,0,1)

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
			local pct = 1 - (fadecomplete - CurTime())/fadetime
			if GAMEMODE.SkyPaint then
				GAMEMODE.SkyPaint:SetTopColor(LerpVector(pct, GAMEMODE.SkyTopColor, stop))
				GAMEMODE.SkyPaint:SetBottomColor(LerpVector(pct, GAMEMODE.SkyBottomColor, sbot))
				GAMEMODE.SkyPaint:SetDuskColor(LerpVector(pct, GAMEMODE.SkyDuskColor, sdusk))
				GAMEMODE.SkyPaint:SetDuskIntensity(Lerp(pct, GAMEMODE.SkyDuskIntensity, sdint))
				GAMEMODE.SkyPaint:SetDuskScale(Lerp(pct, GAMEMODE.SkyDuskScale, sdsca))
				GAMEMODE.SkyPaint:SetSunNormal(LerpVector(pct, GAMEMODE.SkySunNormal, ssun))
			end
			if pct >= 1 then
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

	hook.Add("Ritual_RoundPrepare", "Ritual_ResetSkyPaint", function()
		if GAMEMODE.SkyPaint then
			GAMEMODE.SkyPaint:SetTopColor(GAMEMODE.SkyTopColor)
			GAMEMODE.SkyPaint:SetBottomColor(GAMEMODE.SkyBottomColor)
			GAMEMODE.SkyPaint:SetDuskColor(GAMEMODE.SkyDuskColor)
			GAMEMODE.SkyPaint:SetDuskIntensity(GAMEMODE.SkyDuskIntensity)
			GAMEMODE.SkyPaint:SetDuskScale(GAMEMODE.SkyDuskScale)
			GAMEMODE.SkyPaint:SetSunNormal(GAMEMODE.SkySunNormal)
		end
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
			render.FogMaxDensity(fogdensity*0.95)
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
	hook.Add("Ritual_RoundPrepare", "Ritual_RoundFadeOff", function()
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

	--[[-------------------------------------------------------------------------
	Shiver Horror Aspect:	When the Demon looks in your direction, the closer he is
							the more tension you feel. Play a rising stinger that increases
							pitch based on distance and dot product of demon's aim
							and towards yourself
	---------------------------------------------------------------------------]]
	local nextcheck = 0
	local mindist = 300
	local maxdist = 600
	local dotdist = 300
	local checkdelay = 1.5
	local minpitch = 60
	local scalepitch = 40
	local fadetime = 2
	local resetpitch = 0.05 -- The scale at which the pitch can lower itself (should be very near 0, if not exact 0)
	hook.Add("Think", "Ritual_ShiverThink", function()
		if CurTime() > nextcheck then
			local lp = LocalPlayer()
			local ply = lp:GetObserverTarget()
			if not IsValid(ply) or not ply:IsPlayer() then ply = lp end

			print("Playing:", lp.ShiverSound:IsPlaying())
			if ply:Alive() and ply:IsHuman() and GAMEMODE.RoundState == ROUND_ONGOING then
				local bestscale = 0
				for k,v in pairs(team.GetPlayers(TEAM_DEMONS)) do
					if v:Alive() then
						local dir = ply:GetPos() - v:GetPos() -- from demon to you
						local dist = dir:Length()
						local dot = dist - v:GetAimVector():Dot(dir:GetNormalized())*dotdist
						local scale = math.Clamp(1 - (dot - mindist)/maxdist, 0, 1)

						local tension = scale
						if tension > bestscale then bestscale = tension end
						if tension == 1 then break end
					end
				end

				if not lp.ShiverSound then
					local s = CreateSound(lp, "panicritual/suspense_loop.wav")
					s:PlayEx(0, 0)
					lp.ShiverSound:ChangeVolume(bestscale, fadetime)
					lp.ShiverSound:ChangePitch(minpitch + bestscale*scalepitch, fadetime)
					lp.ShiverSound = s
				else
					if not lp.ShiverSound:IsPlaying() then lp.ShiverSound:Play() end
					lp.ShiverSound:ChangeVolume(bestscale, fadetime)
					local pitch = minpitch + bestscale*scalepitch
					
					if pitch > lp.ShiverSound:GetPitch() or lp.ShiverSound:GetVolume() <= resetpitch then
						lp.ShiverSound:ChangePitch(pitch, fadetime)
					end
				end
			elseif lp.ShiverSound and lp.ShiverSound:IsPlaying() then
				lp.ShiverSound:ChangeVolume(0,3)
			end
			nextcheck = CurTime() + checkdelay
		end
	end)
	
	--[[-------------------------------------------------------------------------
	Insanity Horror Aspect:		Looking directly at a demon in sight distorts screen
								Empowers corner peeking by allowing players to detect demons
								through fog. Called from jumpscares rendering hook to save calculations
								(uses same dot, distance, visibility checks)
	---------------------------------------------------------------------------]]
	local MaxInsanityRefract = 0.1
	local MinDot = 0.98
	local FadeInSpeed = 0.05
	local FadeOutDelay = 0.2
	local FadeOutSpeed = 0.05

	local insanityamount = 0
	local insanityfadeout = 0
	hook.Add("Ritual_DemonVisible", "Ritual_InsanityAspect", function(demon, dot, dist)
		if dot >= MinDot then
			insanityfadeout = CurTime() + FadeOutDelay
		end
	end)
	-- 2000 dist: 0.998 -- Find a function for these to make it more reliable based on range?
	-- 1000 dist: 0.995
	-- 500 dist: 0.992
	-- 100 dist: 0.97
	-- 50 dist: 0.75
	hook.Add("RenderScreenspaceEffects", "Ritual_InsanityAspect", function()
		local ct = CurTime()
		if ct < insanityfadeout and insanityamount < MaxInsanityRefract then
			insanityamount = math.Approach(insanityamount, MaxInsanityRefract, FrameTime()*FadeInSpeed)
		elseif ct > insanityfadeout and insanityamount > 0 then
			insanityamount = math.Approach(insanityamount, 0, -FrameTime()*FadeOutSpeed)
		end
		DrawMaterialOverlay("panicritual/insanity_overlay_dodge", (math.sin(CurTime()/2))*insanityamount)
		--util.ScreenShake(EyePos(), insanityamount*5, insanityamount*5, FadeOutDelay, 50)
		--DrawMotionBlur(0.4, 4*insanityamount, 0.5*insanityamount)
	end)
end