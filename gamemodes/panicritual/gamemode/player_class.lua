DEFINE_BASECLASS( "player_default" )

local PLAYER = {}
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

function PLAYER:SetupDataTables()

end

function PLAYER:Loadout()

end

player_manager.RegisterClass( "player_ritual_base", PLAYER, "player_default" )