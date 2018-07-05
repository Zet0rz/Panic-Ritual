
local animevents = {}
local animnumber = -1
local function AddAnimEvent(seq)
	animnumber = animnumber + 1
	animevents[animnumber] = seq
	return animnumber
end

ANIM_TORMENT = AddAnimEvent("death_04")

local PLAYER = FindMetaTable("Player")
function PLAYER:DoAnimationEventCallback(event, callback, block)
	if self.AnimEventBlock then return false end

	self.AnimEventCallback = callback
	self.AnimEventBlock = block
	self:DoAnimationEvent(event)

	return true
end

function GM:DoAnimationEvent(ply, event, data)
	if event == PLAYERANIMEVENT_CUSTOM_GESTURE then
		local seq = animevents[data]
		if seq then
			ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence(seq), 0, true)
		end
	end
end

function GM:UpdateAnimation(ply, vel, groundspeed)
	if ply.AnimEventCallback then
		print(ply:GetCycle())
		if ply:GetCycle() >= 1 then
			print("Done")
		end
	end
end