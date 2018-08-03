local PLAYER = FindMetaTable("Player")

if SERVER then
	function PLAYER:SetHuman()
		self:SetTeam(TEAM_HUMANS)
		self:AllowFlashlight(true)
		player_manager.SetPlayerClass(self, "player_ritual_human")
	end

	function PLAYER:SetDemon()
		self:SetTeam(TEAM_DEMONS)
		self:AllowFlashlight(false)
		player_manager.SetPlayerClass(self, "player_ritual_demon")
	end
end

function PLAYER:IsHuman() return self:Team() == TEAM_HUMANS end
function PLAYER:IsDemon() return self:Team() == TEAM_DEMONS end

local bonestocheck = {
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_Pelvis",
}
function PLAYER:VisibleTo(ply, c)
	local epos = c and CLIENT and EyePos() or ply:EyePos()
	for k,v in pairs(bonestocheck) do
		local bid = self:LookupBone(v)
		if bid then
			local tr = util.TraceLine({
				start = epos,
				endpos = self:GetBonePosition(bid),
				mask = MASK_SHOT,
				filter = ply,
			})
			if tr.Entity == self then return true, tr end
		end
	end
	return false
end

function PLAYER:CanSee(ply, c)
	return ply:VisibleTo(self, c)
end

if SERVER then
	util.AddNetworkString("ritual_progress")
	-- Networked to cl_hud.lua
	function PLAYER:DisplayProgress(time, start)
		net.Start("ritual_progress")
			net.WriteBool(true)
			net.WriteFloat(time)
			if start then
				net.WriteBool(true)
				net.WriteFloat(start)
			else
				net.WriteBool(false)
			end
		net.Send(self)
	end
	function PLAYER:HideProgress()
		net.Start("ritual_progress")
			net.WriteBool(false)
		net.Send(self)
	end
end