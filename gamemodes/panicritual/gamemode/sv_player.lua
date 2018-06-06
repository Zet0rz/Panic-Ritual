local PLAYER = FindMetaTable("Player")

function PLAYER:SetHuman()
	player_manager.SetPlayerClass(self, "player_ritual_human")
	self:SetTeam(TEAM_HUMANS)
end

function PLAYER:SetDemon()
	player_manager.SetPlayerClass(self, "player_ritual_demon")
	self:SetTeam(TEAM_DEMONS)
end