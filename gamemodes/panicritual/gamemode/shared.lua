GM.Name = "Panic Ritual"
GM.Author = "Zet0r"
GM.Email = "N/A"
GM.Website = "https://youtube.com/Zet0r"

TEAM_HUMANS = 1
TEAM_DEMONS = 2
TEAM_SPECTATORS = 3

team.SetUp(TEAM_HUMANS, "Humans", Color(100,125,255), true)
team.SetUp(TEAM_DEMONS, "Demons", Color(255,100,100), true)
team.SetUp(TEAM_SPECTATORS, "Spectators", Color(150,150,150), true)

game.AddParticles("particles/panicritual/ritual_particles.pcf")