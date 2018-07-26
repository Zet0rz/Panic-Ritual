
print("hints")

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
				self.DoubleTap = CurTime() + 0.1
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
			local str = type(tbl.Header) == "table" and tbl.Header[math.random(#tbl.Header)] or tbl.Header
			
			surface.SetFont("Ritual_HUDFont")
			local x,y = surface.GetTextSize(str)
			width = math.Max(x + 20, width)
			height = height + y + 10

			panel.Header:SetSize(x, y)
			panel.Header:DockMargin(10,10,10,0)
			panel.Header:Dock(TOP)

			local col = Color(255,100,100)
			function panel.Header:Paint(w,h)
				draw.SimpleTextOutlined(str, "Ritual_HUDFont", 0, 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, color_black)
			end
		end

		if tbl.Text then
			panel.Text = panel:Add("Panel")
			local str = type(tbl.Text) == "table" and tbl.Text[math.random(#tbl.Text)] or tbl.Text
			
			surface.SetFont("Ritual_ScrollAlive")
			local x,y = surface.GetTextSize(str)
			width = math.Max(x + 20, width)
			height = height + y*math.ceil((x+20)/width) + 10

			panel.Text:SetSize(x,y)
			panel.Text:DockMargin(10,0,10,10)
			panel.Text:Dock(FILL)

			local col = Color(255,150,150)
			function panel.Text:Paint(w,h)
				draw.SimpleTextOutlined(str, "Ritual_ScrollAlive", 0, 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, color_black)
			end
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
		end,
		[HINT_CENTERBOX] = function(tbl)
			local panel = hintbox(tbl)
			local width, height = panel:GetSize()
			
			panel:SetPos(ScrW()/2 - width/2, ScrH()/2 - height/2)
			panel.HintType = HINT_BOTTOMBOX
		end,
		[HINT_BOTTOM] = function(tbl)
			
		end,
		[HINT_CENTER] = function(tbl)
			local panel = floatingpanel(tbl)
			local width, height = panel:GetSize()
			
			panel:SetPos(ScrW()/2 - width/2, ScrH()/2 - height/2)
			panel.HintType = HINT_BOTTOMBOX
		end,
	}
	
	local function displayhint(tbl)
		local area = tbl.Position or HINT_BOTTOMBOX
		if shownhints[area] then shownhints[area]:Remove() end

		shownhints[area] = areafuncs[area](tbl)
	end

	function PLAYER:SendHint(id)
		local hint = GAMEMODE:GetHint(id)
		if hint then displayhint(hint) end
	end

	net.Receive("Ritual_Hint", function()
		local id = net.ReadString()
		if id then
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
	Text = "Find the Ritual Circles and cleanse the Dolls by grabbing them and bringing them to the other Ritual Circles and back! But watch out for the summoned Demon protecting them!",
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

GM:AddHint("demon_spawn", {
	Text = "Position 3 Ritual Circles as far from each other as possible. Protect the Dolls that spawn on the Circles and kill all Humans before they can cleanse the Dolls by running with them to all other Circles!",
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

GM:AddHint("demon_circle_nospace", {
	--Text = nil,
	--Icon = "panicritual/hud/team_demon.png",
	Header = {
		"Not enough space",
	},
	Position = HINT_CENTER,
	Time = 1,
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