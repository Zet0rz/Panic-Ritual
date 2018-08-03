--[[ Things to fix:
	
	✓ 	 = Done
	*	 = Partially done/Working on
	-	 = Not Done
	?	 = Needs Testing
	X	 = Decided not to implement
	/	 = Couldn't do

	CORE
	✓	Teams set up
	✓	Round system
	✓	Team picker (Weighted Random Demon)
	✓	Round Effects
		✓	Color Correction
		✓	Fog
	✓	Post-round logic (Round restarts after 10 sec)

	OBJECTIVE
	✓	Ritual Circle
		✓	Entity
		✓	Light Candles/Progress indicators
		✓	Completion indicator
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
			Fog replaces it
	✓	Ritual Circle placement (New weapon or same weapon? Or no weapon at all?)
		✓	Space checking
		✓	Distance condition?
		/	Handling of multiple demons (all place or just one? Vote? Place one each?)
				Any demon can place any, 3 = round start (there'll always be 1 demon anyway)
	X	Evil Rate sensing

	HUMANS
	✓	Models (Human models. Randomly colored or all blue?)
	✓	Weapon (No-doll. Maybe merged with doll?)
		✓	Logic
		✓	Model/Viewmodel
		✓	Worldmodel (draw doll in hand)
	X	Evil Rate influence (fade)
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
		✓	Candles too
	✓	Demons invisible during pre-round
	✓	Demons no collide during preround
	✓	Demons exit preround fade (to kill anyone inside them)
	✓	Demon torment circular range instead of hull trace (and effect)
	✓	Demon movement during preround (make sure circles can be reached by humans)
	✓	Demon damage control (only damage by world or doll weapon)
	✓	Fall damage calculation
	*	Doll charge effect
	✓	Doll cleanse viewmodel effect
	✓	Circle completed effect
	✓	Louder jumpscare sounds
	✓	Scream and Shout
		✓	Demon sounds
		-	Play round begin logic
	/	Proper red eye drawing (over fog)
	X	Custom flashlights (brighter to counter color correction)
		✓	Demon "night vision" flashlight?
	✓	Adjust color correction
	✓	Sky nighttime/color
	✓	Hints/Guides
	✓	Demon viewmodel adjustments
		✓	Idle animation improvements (finger anim + slower speed)
		✓	Fix idle animations on demon weapon viewmodel
	✓	Human viewmodel adjustments
		✓	Throw anim?
		✓	Slightly faster sprint anim
	/	Fix ritual circle model clipping?
	✓	Suicide respawn during preround
	✓	Demon respawn conditions?
	✓	Fix circle summon particle effect
			Appears to be same Control point (1) for color and swirl center
	✓	Show hints at round begin
	/	Make hints able to have a "max shown" option (or a disable console command?)
	✓	Keeper player model global playermodel
	✓	Dying with doll drops it
	*	Dropped doll reset burn effect
	✓	Molotov fire sound effect
	✓	Spectate on join mid-round
	✓	Spectate by suiciding within 3 seconds of round restart
	✓	Fix faceplant bug

	✓	Hint/effect for distance to circle
			Blood from eyes?
			Shake?
		✓	Whispers

	POTENTIAL
	✓	Shiver horror aspect
	^	Rising stinger horror aspect
	✓	Doll whisper horror aspect
	-	Round over music
	✓	Demon sounds
	*	Human spawn voicelines
	✓	Additional particle effects?
		✓	Circle completed particles rising
		X	Demon appear effect (initial at round)
		✓	Doll charged viewmodel effect
		✓	Candlefire
		✓	Doll charged world model effect?

	CLEANUP
	✓	Stop round from starting every player initial spawn
	-	Remove debug prints and functions
	✓	material models/player/panicritual/keeper_hooded_red_tattered_parts has a normal map and an envmapmask.  Must use $normalmapalphaenvmapmask.
			for all Demon materials
	✓	Remove unused weapons and lua files
	✓	Package demon model as global playermodel
		✓	Add black variant
	✓	Test packaging of "content" (maybe needs to be moved to addon root)
	✓	Menu logo
	✓	Menu icon
	✓	Workshop thumbnail
	*	PLAYTEST
			Adjustments after
	-	Workshop screenshots
	-	Workshop description
	-	Github description

	BALANCE POINTS
	✓	Circle candle distance (sphere distance)
	✓	Doll cleanse time (4 sec)
	✓	Doll charge time (10 sec)
	✓	Fade duration, kill radius, cooldown, speed (LMB)
		✓	Stun/slowdown? (stamina lock)
		^	Some type of punishment
		X	Fog fadein? Some way of making it easier for the human to get away
	✓	Leap kill radius, cooldown, power (4 sec cooldown)
	✓	Doll charge ammo, DPS (Damage upped to 4, DPS: 80)
	✓	Demon base movement speed (slightly slower)
	✓	Human base movement speed (same)
	✓	Color correction & Fog
	-	Anti-camping?
		-	Throw dolls to cleanse
		-	
	✓	Stamina system
		✓	Stamina for both demon and human
		✓	Demon walks faster than human
		✓	Human sprints faster than demon

	✓	Shiver Horror Aspect
		✓	Play stinger/violin sound effect as the demon looks your direction
		✓	Dot product (offset) times distance = volume
		✓	Volume fade

	✓	Demon break windows and breakables
	✓	Fix jumpscare inconsistencies
		✓	Perhaps just simplify jumpscare algorithm to just be timed + distance?
		✓	Using dot product to ensure direction
	?	Fix circles/candles left over?
	✓	Fix charged doll viewmodel particles
	✓	More hints for abilities
	✓	Show Leap charge bar
	✓	Spectating HUD
		✓	Using spectated player for HUD elements?
		✓	Using spectated player for jumpscares etc?
	-	ConVar settings for balance variables?
	X	Fixing red eyes horror aspect? (replaced by insanity aspect)
	-	Laser beam sound?
	-	Fix infinite circle placement bug (maybe some failsafe?)
	✓	Scoreboard ping
	✓	Voice chat hooks/logic
	✓	Voice chat HUD move
	✓	Insanity horror aspect
	✓	Peek look around
	✓	Multi-resolution HUD (No change was needed) (bars can overlap at smaller resolutions)
	
	HINTS
	✓	F1 Hints Menu
	✓	Hint additional Net capabilities
	✓	Hint ConVar
	-	Additional Hints
		✓	Insanity aspect
	-	New Hint icons
		✓	Whispers (Doll with wind out of mouth)
		✓	Burning Eyes (Doll with fire eyes)
		✓	Stamina (Foot, or energy bolt)
		✓	Tension (Looking over shoulder)
		✓	Charging Dolls (arms rising)
		✓	Doll Reset (doll in flames)
		✓	Cleansing Dolls (doll with rings)
		✓	Killing Humans (soul death pose)
		✓	Red Fog (misty stuff)
		✓	Insanity Aspect
]]