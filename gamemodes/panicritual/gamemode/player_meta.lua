local PLAYER = FindMetaTable("Player")

if SERVER then
	function PLAYER:SetHuman()
		self:SetTeam(TEAM_HUMANS)
		player_manager.SetPlayerClass(self, "player_ritual_human")
	end

	function PLAYER:SetDemon()
		self:SetTeam(TEAM_DEMONS)
		print("Set to demon")
		player_manager.SetPlayerClass(self, "player_ritual_demon")
	end
end

function PLAYER:IsHuman() return self:Team() == TEAM_HUMANS end
function PLAYER:IsDemon() return self:Team() == TEAM_DEMONS end

function PLAYER:VisibleTo(ply)
	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = self:EyePos(),
		mask = MASK_SHOT,
		filter = ply,
	})

	return tr.Hit and tr.Entity == self, tr
end

function PLAYER:CanSee(ply)
	return ply:VisibleTo(self)
end