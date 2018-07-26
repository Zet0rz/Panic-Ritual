--[[ Things to fix:
	
	✓ 	 = Done
	*	 = Partially done/Working on
	-	 = Not Done
	?	 = Needs Testing
	X	 = Decided not to implement
	/	 = Couldn't do

	CORE
	✓	Teams set up
	*	Round system
	✓	Team picker (Weighted Random Demon)
	*	Round Effects
		*	Color Correction
		✓	Fog
	✓	Post-round logic (Round restarts after 10 sec)

	OBJECTIVE
	*	Ritual Circle
		✓	Entity
		✓	Light Candles/Progress indicators
		-	Completion indicator
		?	Variable required total number of circles
	✓	Dolls
		✓	Dropped Entity
		✓	Evil Rate
		✓	Weapon
			✓	Burning eye effect
		✓	Progress checking
		✓	Completion
		?	Variable required total number of circles to run past
			?	Support '-X' to mean "all except X"
		/	Better model?
		✓	Cleanse time
	✓	Win Condition
		?	Variable required completion number
		✓	Light weapon
		✓	Light weapon dropping/re-picking up
		✓	Light weapon reset (if lost for too long)
		✓	Ritual action (That enables win condition on completed circles)

	DEMON
	✓	Model (BO3 Zombies Keeper)
	✓	Weapon
	/	Invisibility ability?
	✓	Ritual Circle placement (New weapon or same weapon? Or no weapon at all?)
		-	Space checking
		-	Distance condition?
		-	Handling of multiple demons (all place or just one? Vote? Place one each?)
	/	Evil Rate sensing

	HUMANS
	*	Models (Human models. Randomly colored or all blue?)
	✓	Weapon (No-doll. Maybe merged with doll?)
		✓	Logic
		✓	Model/Viewmodel
		✓	Worldmodel (draw doll in hand)
	/	Evil Rate influence (fade)
	✓	Corner peeking
	✓	Jumpscares


	ADDITIONAL
	✓	Fix weapon and model distribution
	✓	Fix host almost always demon
	✓	HUD Target ID (E to pick up, player names)
		✓	Player (humans only though)
		✓	Doll (E to pick up)
	✓	Spectating
	✓	Death/Respawning handling
	/	Permanent spectating?
	✓	Demon circle placement logic
			How?
			✓	Candles must be accessible by Hull Trace (straight up, straight down)
			✓	Center must be accessible by Hull Trace
			✓	Distance to all circles must be above 500
	✓	Demon AFK system
	-	Too long round handling (Demon benefit? Just end round?)
	✓	Ritual circles invisible during pre-round
		-	Candles too
	✓	Demons invisible during pre-round
	✓	Demons no collide during preround
	✓	Demons exit preround fade (to kill anyone inside them)
	✓	Demon torment circular range instead of hull trace (and effect)
	✓	Demon movement during preround (make sure circles can be reached by humans)
	✓	Demon damage control (only damage by world or doll weapon)
	✓	Fall damage calculation
	-	Doll charge effect
	-	Doll cleanse viewmodel effect
	-	Circle completed effect
	-	Louder jumpscare sounds
	✓	Scream and Shout
		-	Demon sounds
		-	Play round begin logic
	-	Proper red eye drawing (over fog)
	-	Adjust color correction
	✓	Hints/Guides
	-	Demon viewmodel adjustments
		-	Idle animation improvements (finger anim + slower speed)
		-	Fix idle animations on demon weapon viewmodel
	-	Human viewmodel adjustments
		-	Throw anim?
		-	Slightly faster sprint anim
	-	Fix ritual circle model clipping?
	✓	Suicide respawn during preround
	/	Demon respawn conditions?
	-	Fix circle summon particle effect
			Appears to be same Control point (1) for color and swirl center

	POTENTIAL
	-	Shiver horror aspect
	-	Rising stinger horror aspect
	-	Doll whisper horror aspect
	-	Round over music
	-	Demon sounds
	-	Human spawn voicelines
	-	Additional particle effects?
		-	Circle completed particles rising
		-	Demon appear effect (initial at round)
		-	Doll charged viewmodel effect
		-	Candlefire
		-	Doll charged world model effect?

	CLEANUP
	-	Stop round from starting every player initial spawn
	-	Remove debug prints and functions
	-	material models/player/panicritual/keeper_hooded_red_tattered_parts has a normal map and an envmapmask.  Must use $normalmapalphaenvmapmask.
			for all Demon materials
	-	Remove unused weapons and lua files
	-	Package demon model as global playermodel
	-	Test packaging of "content" (maybe needs to be moved to addon root)
	-	Menu logo
	-	Menu icon
	-	Workshop thumbnail
	-	PLAYTEST
			Adjustments after
	-	Workshop screenshots
	-	Workshop description
	-	Github description


	
]]