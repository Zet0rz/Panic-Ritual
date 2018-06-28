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
	-	Round Effects
		-	Color Correction
		-	Fog
	-	Post-round logic (What should happen?)

	OBJECTIVE
	*	Ritual Circle
		✓	Entity
		*	Light Candles/Progress indicators
		-	Completion indicator
		?	Variable required total number of circles
	*	Dolls
		✓	Dropped Entity
		-	Evil Rate
		✓	Weapon
			-	Burning eye effect
		✓	Progress checking
		✓	Completion
		?	Variable required total number of circles to run past
			?	Support '-X' to mean "all except X"
		-	Better model?
		✓	Cleanse time
	-	Win Condition
		?	Variable required completion number
		-	Light weapon
		-	Light weapon dropping/re-picking up
		-	Light weapon reset (if lost for too long)
		-	Ritual action (That enables win condition on completed circles)

	DEMON
	-	Model (Hooded demon? BO3 Zombies Keeper?)
	-	Weapon
	-	Invisibility ability?
	✓	Ritual Circle placement (New weapon or same weapon? Or no weapon at all?)
		-	Space checking
		-	Distance condition?
		-	Handling of multiple demons (all place or just one? Vote? Place one each?)
	-	Evil Rate sensing

	HUMANS
	*	Models (Human models. Randomly colored or all blue?)
	*	Weapon (No-doll. Maybe merged with doll?)
		✓	Logic
		-	Model/Viewmodel
		-	Worldmodel (draw doll in hand)
	-	Evil Rate influence (fade)
	-	Corner peeking
	*	Jumpscares


	
]]