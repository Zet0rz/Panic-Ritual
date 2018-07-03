
local jumpscares = {distances = {}, sounds = {}}
local function addjumpscaregroup(range, sounds)
	local index = 1
	for k,v in pairs(jumpscares.distances) do
		if v > range then break end
		index = k
	end
	table.insert(jumpscares.distances, index, range)
	table.insert(jumpscares.sounds, index, sounds)

	for k,v in pairs(sounds) do
		util.PrecacheSound(v)
	end
end

-- Far sounds
addjumpscaregroup(600, {
	"panicritual/jumpscares/far1.wav",
	"panicritual/jumpscares/far2.wav",
	"panicritual/jumpscares/far3.wav",
	"panicritual/jumpscares/far4.wav",
})

-- Medium sounds
addjumpscaregroup(400, {
	"panicritual/jumpscares/medium1.wav",
	"panicritual/jumpscares/medium2.wav",
	"panicritual/jumpscares/medium3.wav",
})

-- Close sounds
addjumpscaregroup(150, {
	"panicritual/jumpscares/close1.wav",
	"panicritual/jumpscares/close2.wav",
})

--[[-------------------------------------------------------------------------
	Scare Configuration
---------------------------------------------------------------------------]]

-- Calculate scares by an "Intensity" scale (based on distance)
-- Give the player a "Scare Immunity" that blocks any scares less intense than this
-- Base immunity levels on the intensity of the newly given jumpscare
-- Make immunity decay over time
-- Add a per-player immunity time so you can't be scared by the same Demon within a short time

-- Result: Player can only be scared once, however a second demon can double-scare if he is closer than Intensity Immunity
-- Alternative: Only per-player immunity? Second demon can always double scare?

local LocationForgetTime = 3 -- The amount of time of not having seen a demon to "forget" his location
local DoubleScareDistance = function(x) return x < 100 and 0 or x/3 end -- How close the same demon has to be to double-scare
local ScareResetTime = 15 -- The time until scares completely reset distance-wise

--[[-------------------------------------------------------------------------
	VERSION 1: 	Players can only scare after 5 seconds of not being seen
				Double scares only after LocationForgetTime
				Scares reset after ScareResetTime

				More efficient, but awkward 5-second initial scares
---------------------------------------------------------------------------]]

--[[local scares = {}
hook.Add("PostPlayerDraw", "Ritual_Jumpscares", function(ply)
	local ct = CurTime()

	local lp = LocalPlayer()
	if lp:IsHuman() and ply:IsDemon() then
		local vis, tr = ply:VisibleTo(lp)
		if vis then
			if not scares[ply] or (scares[ply].reset and scares[ply].reset < ct) then
				scares[ply] = {next = 0}
			end

			if scares[ply].next < ct then
				local dist = ply:GetPos():Distance(lp:GetPos())

				if not scares[ply].double or scares[ply].double > dist then
					local index
					for k,v in ipairs(jumpscares.distances) do
						if v > dist then index = k break end
					end
					if index then
						local sounds = jumpscares.sounds[index]
						surface.PlaySound(sounds[math.random(#sounds)])
						scares[ply].double = DoubleScareDistance(dist)
						scares[ply].reset = ct + ScareResetTime
					end
				end
			end

			scares[ply].next = ct + LocationForgetTime
		end
	end
end)]]

--[[-------------------------------------------------------------------------
	VERSION 2:	Scares are constantly calculated by distance
				Doubles scares are always possible if within DoubleScareDistance
				Initial scares also only if within DoubleScareDistance of last seen
				Last seen distance returns to huge after ScareResetTime

				Constant distance calculation, but better gameplay-wise
---------------------------------------------------------------------------]]

local scares = {}
hook.Add("PostPlayerDraw", "Ritual_Jumpscares", function(ply)
	local lp = LocalPlayer()
	if lp:IsHuman() and ply:IsDemon() then
		local vis, tr = ply:VisibleTo(lp)
		if vis then
			local ct = CurTime()
			local dist = ply:GetPos():Distance(lp:GetPos())

			if not scares[ply] or (scares[ply].reset and scares[ply].reset < ct) then
				scares[ply] = {next = math.huge}
			end

			if scares[ply].next > dist then
				local index
				for k,v in ipairs(jumpscares.distances) do
					if v > dist then index = k break end
				end
				if index then
					local sounds = jumpscares.sounds[index]
					surface.PlaySound(sounds[math.random(#sounds)])
				end
			end

			scares[ply].reset = ct + ScareResetTime
			scares[ply].next = DoubleScareDistance(dist)
		end
	end
end)