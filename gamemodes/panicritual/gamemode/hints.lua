
print("hints")

local function pickorgetval(val)
	local t = type(val)
	if t == "table" then
		return val[math.random(#val)]
	elseif t == "function" then
		return t()
	else
		return val
	end
end

local hints = {}
function GM:AddHint(id, tbl)
	hints[id] = tbl
	print("adding", id)
end
function GM:GetHint(id) return hints[id] end
function GM:GetHints(id) return hints end

HINT_BOTTOMBOX = 0
HINT_CENTERBOX = 1
HINT_BOTTOM = 2
HINT_CENTER = 3

local PLAYER = FindMetaTable("Player")
if SERVER then
	util.AddNetworkString("Ritual_Hint")
	util.AddNetworkString("Ritual_Hint_Custom")

	function GM:SendHint(id, recipient)
		net.Start("Ritual_Hint")
			net.WriteString(id)
		net.Send(recipient)
	end
	function GM:BroadcastHint(id, recipient)
		net.Start("Ritual_Hint")
			net.WriteString(id)
		net.Broadcast()
	end

	function GM:SendCustomHint(tbl, recipient)
		net.Start("Ritual_Hint_Custom")
			if tbl.Text then
				net.WriteBool(true)
				net.WriteString(tbl.Text)
			else
				net.WriteBool(false)
			end

			if tbl.Icon then
				net.WriteBool(true)
				net.WriteString(tbl.Icon)
			else
				net.WriteBool(false)
			end

			if tbl.Header then
				net.WriteBool(true)
				net.WriteString(tbl.Header)
			else
				net.WriteBool(false)
			end

			net.WriteUInt(tbl.Position or HINT_BOTTOMCENTER)
		net.Send(recipient)
	end
end

if CLIENT then
	local shownhints = {}

	local maxwidth = 400
	local function hintbox(tbl)
		local panel = vgui.Create("DPanel")
		--panel:SetSize(maxwidth,200)
		panel:SetBackgroundColor(Color(50,50,50,250))
		panel:DockPadding(5,5,5,5)

		local width, height = 10,15

		if tbl.Header and tbl.Header ~= "" then
			panel.Header = panel:Add("DLabel")
			local str = type(tbl.Header) == "table" and tbl.Header[math.random(#tbl.Header)] or tbl.Header
			panel.Header:SetText(str)
			panel.Header:SetTextColor(Color(255,100,100))
			panel.Header:SetFont("Ritual_ScrollAlive")
			panel.Header:SizeToContentsY()
			panel.Header:SetContentAlignment(4)
			panel.Header:DockMargin(10,10,10,0)
			panel.Header:Dock(TOP)

			surface.SetFont("Ritual_ScrollAlive")
			local x,y = surface.GetTextSize(str)
			width = math.Min(maxwidth, math.Max(x + 20, width))
			height = height + y + 10
		end

		if tbl.Text then
			panel.Text = panel:Add("DLabel")
			local str = type(tbl.Text) == "table" and tbl.Text[math.random(#tbl.Text)] or tbl.Text
			panel.Text:SetSize(maxwidth,200)
			panel.Text:SetText(str)
			panel.Text:SetTextColor(Color(225,225,225))
			panel.Text:SetFont("Trebuchet18")
			panel.Text:SetWrap(true)
			panel.Text:SetAutoStretchVertical(true)
			panel.Text:SetContentAlignment(7)
			panel.Text:DockMargin(10,0,10,10)
			panel.Text:Dock(FILL)

			surface.SetFont("Trebuchet18")
			local x,y = surface.GetTextSize(str)
			width = math.Min(maxwidth, math.Max(x + 20, width))
			height = height + y*math.ceil((x+20)/width) + 10
		end
		
		if tbl.Icon then
			panel.Icon = panel:Add("DImage")
			local str = type(tbl.Icon) == "table" and tbl.Icon[math.random(#tbl.Icon)] or tbl.Icon
			panel.Icon:SetImage(str)
			local size = math.Min(width, height)
			panel.Icon:SetSize(size, size)
			panel.Icon:Dock(LEFT)
			panel.Icon:SetZPos(-10)

			width = width + size
		end

		panel:SetSize(width, height)

		local tabindicator = panel:Add("DLabel")
		tabindicator:SetText("Double-tap TAB to close")
		tabindicator:SetPos(width - 120, 5)
		tabindicator:SizeToContents()

		panel.Think = function(self)
			local tab = LocalPlayer():KeyDown(IN_SCORE)
			if tab and not self.Tab then
				if self.DoubleTap and self.DoubleTap > CurTime() then self:Remove() else self.Tab = true end
			elseif not tab and self.Tab then
				self.DoubleTap = CurTime() + 0.2
				self.Tab = false
			end
		end

		panel.OnRemove = function(self)
			if shownhints[self.HintType] == self then shownhints[self.HintType] = nil end
		end

		return panel
	end

	local function floatingpanel(tbl)
		local panel = vgui.Create("DPanel")
		panel:SetBackgroundColor(Color(0,0,0,0))

		local width, height = 0,0

		if tbl.Header and tbl.Header ~= "" then
			panel.Header = panel:Add("Panel")
			local str = pickorgetval(tbl.Header)
			
			surface.SetFont("Ritual_HUDFont")
			local x,y = surface.GetTextSize(str)
			width = math.Max(x + 20, width)
			height = height + y + 10

			panel.Header:SetSize(x, y)
			panel.Header:DockMargin(10,10,10,0)
			panel.Header:Dock(TOP)

			local col = Color(255,100,100)
			function panel.Header:Paint(w,h)
				draw.SimpleTextOutlined(str, "Ritual_HUDFont", w/2, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
			end
		end

		if tbl.Text then
			panel.Text = panel:Add("Panel")
			local str = pickorgetval(tbl.Text)
			
			surface.SetFont("Ritual_ScrollAlive")
			local x,y = surface.GetTextSize(str)
			width = math.Max(x + 20, width)
			height = height + y*math.ceil((x+20)/width) + 10

			panel.Text:SetSize(x,y)
			panel.Text:DockMargin(10,0,10,10)
			panel.Text:Dock(FILL)

			local col = Color(255,150,150)
			function panel.Text:Paint(w,h)
				draw.SimpleTextOutlined(str, "Ritual_ScrollAlive", w/2, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
			end
		end
		
		if tbl.Icon then
			panel.Icon = panel:Add("DImage")
			local str = pickorgetval(tbl.Icon)
			panel.Icon:SetImage(str)
			local size = math.Min(width, height)
			panel.Icon:SetSize(size, size)
			panel.Icon:Dock(LEFT)
			panel.Icon:SetZPos(-10)

			width = width + size
		end

		panel:SetSize(width + 10, height)

		panel:AlphaTo(0, tbl.Fade or 2, tbl.Time or 5)
		panel.Think = function(self)
			if self:GetAlpha() <= 0 then self:Remove() end
		end

		panel.OnRemove = function(self)
			if shownhints[self.HintType] == self then shownhints[self.HintType] = nil end
		end

		return panel
	end

	local areafuncs = {
		[HINT_BOTTOMBOX] = function(tbl)
			local panel = hintbox(tbl)
			local width, height = panel:GetSize()

			panel:SetPos(ScrW()/2 - width/2, ScrH() - height - 200)
			panel.HintType = HINT_BOTTOMBOX
			return panel
		end,
		[HINT_CENTERBOX] = function(tbl)
			local panel = hintbox(tbl)
			local width, height = panel:GetSize()
			
			panel:SetPos(ScrW()/2 - width/2, ScrH()/2 - height/2)
			panel.HintType = HINT_CENTERBOX
			return panel
		end,
		[HINT_BOTTOM] = function(tbl)
			local panel = floatingpanel(tbl)
			local width, height = panel:GetSize()
			
			panel:SetPos(ScrW()/2 - width/2, ScrH()/4*3 - height/2)
			panel.HintType = HINT_BOTTOM
			return panel
		end,
		[HINT_CENTER] = function(tbl)
			local panel = floatingpanel(tbl)
			local width, height = panel:GetSize()
			
			panel:SetPos(ScrW()/2 - width/2, ScrH()/2 - height/2)
			panel.HintType = HINT_CENTER
			return panel
		end,
	}
	
	local function displayhint(tbl)
		local area = tbl.Position or HINT_BOTTOMBOX
		if shownhints[area] then shownhints[area]:Remove() end

		if tbl[1] then tbl = pickorgetval(tbl) end -- A table of hints numerically indexed
		if tbl.Function then tbl = tbl.Function() or tbl end
		if not tbl.Text and not tbl.Icon and not tbl.Header then return end
		shownhints[area] = areafuncs[area](tbl)
	end

	function PLAYER:SendHint(id)
		local hint = GAMEMODE:GetHint(id)
		if hint then displayhint(hint) end
	end

	net.Receive("Ritual_Hint", function()
		local id = net.ReadString()
		if id and IsValid(LocalPlayer()) then
			LocalPlayer():SendHint(id)
		end
	end)

	hook.Add("PostMapCleanup", "Ritual_CleanupHints", function()
		for k,v in pairs(shownhints) do
			if IsValid(v) then v:Remove() end
		end
		shownhints = {}
	end)
else
	function PLAYER:SendHint(id)
		GAMEMODE:SendHint(id,self)
	end
	function PLAYER:SendCustomHint(tbl)
		GAMEMODE:SendCustomHint(tbl,self)
	end
end

GM:AddHint("human_spawn", {
	Text = {
		"Something's wrong, the air feels heavier than it did before. Something changed but you can't quite put your finger on it yet. Maybe someone's behind this?",
		"You have gathered here with some other people, but feel the presence of one additional entity. There is no one in sight though, but probably best to stay on guard.",
		"Something brushes off of your shirt behind you! ... or was there anything? Maybe it was just the wind, but you can't help but feel like that wasn't the case.",
		"Something definitely feels off. Last time you were here it wasn't liket this. Someone did something, and whoever might be behind it is probably among you right now.",
		"You get an intense feeling that something is wrong. You feel distrust towards the other people you are with. One of you messed with things they don't understand.",
		"Dark powers are at play. One of you must have tried something they shouldn't have. Whoever it was can wait, right now you feel more important problems are shaping up.",
	},
	Icon = "panicritual/hud/team_human.png",
	Header = {
		"You are Human",
		"Something's off...",
		"Someone ruined your party",
		"An eerie chill runs down your spine...",
		"Something's not quite right",
		"You feel watched",
		"Someone caused this ...",
	},
	Position = HINT_BOTTOMBOX,
})

GM:AddHint("human_roundstart", {
	Text = "Find the Ritual Circles and cleanse the Dolls by bringing them to the other Ritual Circles and back! Listen for the whispers, but watch out for the summoned Demon hunting you down!",
	Icon = "panicritual/hud/circle_doll.png",
	Header = {
		"The round starts!",
		"Something has arrived!",
		"Someone's at fault for this",
		"A heavy fog materializes",
		"The hunt is on!",
		"Someone's hunting you!",
		"Try to stay calm ...",
		"You can find out who later",
	},
	Position = HINT_BOTTOMBOX,
})

GM:AddHint("demon_spawn", {
	Text = "You are not at your full power and are invisible to Humans. Position 3 Ritual Circles to materialize! They should be far from each other, as Humans have to cleanse them to exorcise you!",
	Icon = "panicritual/hud/team_demon.png",
	Header = {
		"You are the Demon",
		"Someone summoned you here ...",
		"The Ritual didn't quite bind you...",
		"You feel free ...",
		"You sense mortals ...",
	},
	Position = HINT_BOTTOMBOX,
})

-- These take the place of the demon's ability hints, whereas humans get them while spectating
GM:AddHint("demon_objective_humans", {
	Text = "You have materialized! Find and kill all Humans before they can exorcise you by cleansing the dolls at the circles! The number of Humans left is shown above your health bar.",
	Icon = "panicritual/hud/human_mask.png",
	Header = "The hunt is on!",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("demon_ability_fade", {
	Text = "Fade lasts for 0.5 seconds and gives you slightly higher movement speed. If you are inside a Human at the end of it, you will kill him. It has a cooldown and Stamina Stuns you after use.",
	Icon = "panicritual/hud/demon_fade.png",
	Header = "Fade Dash",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("demon_ability_leap", {
	Text = "Leap launches you the direction you're looking, and upon landing kills any Human nearby. The longer the air time, the bigger the radius. You can charge the Leap by HOLDING Right Click.",
	Icon = "panicritual/hud/demon_leap.png",
	Header = "Void Leap",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("demon_ability_stamina", {
	Text = "Your Stamina is limited and Humans sprint faster than you. Save your Stamina for the chase, and walk while seeking; Humans are under the same limitations and walk slower than you.",
	Icon = "panicritual/hud/team_demon.png",
	Header = "Stamina",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("demon_objective_circleindicators", {
	Text = "You can see the status of all your Ritual Circles. Each lit candle indicates how many Circles that doll has been cleansed at. If all are on, it means that circle is done!",
	Icon = "panicritual/hud/candle_on.png",
	Header = "Keep track",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("demon_ability_killing", {
	Text = "Your abilities lets you enter your Void Form, becoming non-solid to everyone else. Exiting Void Form inside a Human will rip their Soul free from their body, killing them!",
	Icon = "panicritual/hud/muted.png",
	Header = "Killing Humans",
	Position = HINT_BOTTOMBOX,
})
local demonstarthints = {
	"demon_objective_humans",
	"demon_ability_fade",
	"demon_ability_leap",
	"demon_objective_circleindicators",
	"demon_ability_stamina",
	"demon_ability_killing",
}
GM:AddHint("demon_roundstart", {
	Function = function()
		return GAMEMODE:GetHint(demonstarthints[math.random(#demonstarthints)])
	end,
	Position = HINT_BOTTOMBOX, -- This still picks the position for the picked table
})

GM:AddHint("human_ability_dollwhisper", {
	Text = "Listen out for the whispers from the Doll you're carrying. It is louder the closer you are to a Ritual Circle you can cleanse at.",
	Icon = "panicritual/hud/human_doll.png",
	Header = "Whispers",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_ability_dolleyes", {
	Text = "Notice the burning eyes of the Doll any Human is carrying. It burns brighter the closer the Demon is to that Doll!",
	Icon = "panicritual/hud/human_doll.png",
	Header = "Evil Influence",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_objective_dollcharging", {
	Text = "When 2 of the 3 Ritual Circles have been completed, particles will appear on them. This means you can Charge their Dolls, giving you the only weapon you have against the Demon!",
	Icon = "panicritual/hud/human_dollcharge.png",
	Header = "Charging Dolls",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_objective_dollreset", {
	Text = "Dropped Dolls will reset after not being picked up for too long. It will return to its Circle, and the Circle's candles will all be reset if it hasn't already been completed.",
	Icon = "panicritual/hud/human_nodoll.png",
	Header = "Doll Reset",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_ability_stamina", {
	Text = "Your stamina is limited. Humans walk slower than Demons, but sprint faster. Save your stamina for being chased, and move around slowly to avoid getting found!",
	Icon = "panicritual/hud/team_human.png",
	Header = "Stamina",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_objective_fog", {
	Text = "When the Demon materializes, it brings along with it a dense fog. However be aware that the Demon can see through it!",
	Icon = "panicritual/hud/team_demon.png",
	Header = "Red Fog",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_ability_cornerpeek", {
	Text = "Look near a corner and hold ALT to peek around it. This isn't visible to anyone else. Use it often to spot the Demon so you can sprint away before he sees you!",
	Icon = "panicritual/hud/human_peek.png",
	Header = "Corner Peeking",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_ability_dollthrow", {
	Text = "You can throw your Doll by pressing Right Click. Other Humans can pick it up and it will retain its progress and charge. But be aware of Doll Reset!",
	Icon = "panicritual/hud/human_throw.png",
	Header = "Throwing Dolls",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_objective_candle", {
	Text = "As a Circle's Doll is cleansed at another Circle, a Candle is lit up indicating progress. The last Candle is always the Circle itself!",
	Icon = "panicritual/hud/candle_on.png",
	Header = "Circle Candles",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_ability_tension", {
	Text = "Humans have an innate ability to sense danger approaching. When the Demon is looking in your direction, you will hear your tension rising the closer it gets.",
	Icon = "panicritual/hud/unmuted.png",
	Header = "Tension",
	Position = HINT_BOTTOMBOX,
})
GM:AddHint("human_objective_chargeddoll", {
	Text = "A Charged Doll is able to shoot a beam of light which can kill the Demon! Watch out for its energy, when it runs out it will go back to its Circle! It can be recharged at its home Circle.",
	Icon = "panicritual/hud/human_dollcharge.png",
	Header = "Charged Dolls",
	Position = HINT_BOTTOMBOX,
})

local humanspectatehints = {
	"human_ability_cornerpeek",
	"human_ability_dolleyes",
	"human_ability_dollthrow",
	"human_ability_dollwhisper",
	"human_ability_stamina",
	"human_ability_tension",
	"human_objective_candle",
	"human_objective_chargeddoll",
	"human_objective_dollcharging",
	"human_objective_dollreset",
	"human_objective_fog"
}
-- These explain Human abilities and are shown when a Human dies and spectates (well, also Demon but that'd end the round)
GM:AddHint("human_spectator_hint", {
	Position = HINT_BOTTOMBOX,
	Function = function()
		return GAMEMODE:GetHint(humanspectatehints[math.random(#humanspectatehints)])
	end
})

GM:AddHint("demon_circle_nospace", {
	Header = "Not enough space",
	Text = "There must be space for all candles and the doll.",
	Position = HINT_CENTER,
	Time = 3,
	Fade = 1,
})

GM:AddHint("demon_circle_tooclose", {
	Header = "Too close to another circle",
	Text = "Circles cannot be too close to each other.",
	Position = HINT_CENTER,
	Time = 3,
	Fade = 1,
})

GM:AddHint("afk", {
	Text = "If you don't press any buttons for 60 seconds, you will be slain.",
	Icon = "panicritual/hud/muted.png",
	Header = "You are going AFK",
	Position = HINT_BOTTOMBOX,
})

GM:AddHint("demon_circle_time", {
	Text = "If you don't position all Ritual Circles, you will not be able to materialize and you will return to the void!",
	Icon = "panicritual/hud/circle_doll.png",
	Header = "Hurry up!",
	Position = HINT_BOTTOMBOX,
})

GM:AddHint("demon_win", {
	Text = "The Demon killed all Humans before they could exorcise the Demon.",
	Icon = "panicritual/hud/team_demon.png",
	Header = {
		"The Demon wins!",
		"The Humans were perished",
		"All Humans were killed",
		"No Humans left",
		"The Demon is free",
		"The Demon was victorious",
	},
	Position = HINT_CENTERBOX,
})

GM:AddHint("human_win", {
	Text = "The Demon was killed before it could find and kill all Humans.",
	Icon = "panicritual/hud/team_human.png",
	Header = {
		"Humans wins!",
		"The Demon was exorcised",
		"Exorcism successful",
		"The Demon was returned",
		"The Demon was killed",
		"The Humans were victorious",
	},
	Position = HINT_CENTERBOX,
})

GM:AddHint("noone_win", {
	Text = "The Demon along with all Humans vanished into the void.",
	Icon = "panicritual/hud/human_nodoll.png",
	Header = {
		"No one wins!",
		"Everyone died",
		"No one was left",
		"Everyone perished",
		"Everyone vanished",
		"The world forgets",
	},
	Position = HINT_CENTERBOX,
})