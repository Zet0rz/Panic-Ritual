
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

local nextscare = 0
hook.Add("PostPlayerDraw", "Ritual_Jumpscares", function(ply)
	if nextscare < CurTime() then
		local lp = LocalPlayer()
		if lp:IsHuman() and ply:IsDemon() then
			if ply:VisibleTo(lp) then
				local dist = ply:GetPos():Distance(lp:GetPos())

				local index
				for k,v in ipairs(jumpscares.distances) do
					if v > dist then index = k break end
				end
				if index then
					surface.PlaySound(jumpscares.sounds[index][math.random(#jumpscares.sounds[index])])
					nextscare = CurTime() + 2
				end
			end
		end
	end
end)