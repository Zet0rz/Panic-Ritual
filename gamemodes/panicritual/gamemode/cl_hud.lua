
print("hi")

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudWeaponSelection"] = true,
}

function GM:HUDShouldDraw(name)
	if (hide[name]) then return false end
	return true
end

surface.CreateFont("Ritual_HUDFont", {
	font = "October Crow",
	extended = false,
	size = 38,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont("Ritual_HUDFont_Small", {
	font = "October Crow",
	extended = false,
	size = 24,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont("Ritual_HUDFont_Large", {
	font = "October Crow",
	extended = false,
	size = 46,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont("Ritual_ScrollAlive", {
	font = "Haunt AOE",
	extended = false,
	size = 38,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont("Ritual_Demons", {
	font = "October Crow",
	extended = false,
	size = 36,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

local blood_blob = Material("panicritual/hud/blood_blob.png", "noclamp")
local blood_bar = Material("panicritual/hud/blood_bar.png", "noclamp")
local team_human = Material("panicritual/hud/team_human.png", "noclamp")
local team_demon = Material("panicritual/hud/team_demon.png", "noclamp")
local human_contract = Material("panicritual/hud/scroll_small.png", "noclamp")

local pad = 50
local pad2 = 10
local padinner = 5
local iconsize = 150
local iconsize2 = 75
local barthickness = 70

-- Demon circle indicators
local offset = Vector(0,0,10) -- World space offset of drawing
local candlesize = 50
local candledist = 60
local circlesize = 100
local circle_doll = Material("panicritual/hud/circle_doll.png", "noclamp")
local circle_nodoll = Material("panicritual/hud/circle_nodoll.png", "noclamp")
local candle_off = Material("panicritual/hud/candle_off.png", "noclamp")
local candle_on = Material("panicritual/hud/candle_on.png", "noclamp")

local circle_ents = {}
for k,v in pairs(ents.FindByClass("ritual_circle")) do -- for Lua refresh
	circle_ents[v] = true
end
hook.Add("OnEntityCreated", "Ritual_CatchCircles", function(ent)
	if ent:GetClass() == "ritual_circle" then circle_ents[ent] = true end
end)

-- Target ID on humans
local human_mask = Material("panicritual/hud/human_mask.png", "noclamp")
local masksize = 75
local lower = 150
local targetidfont = "Ritual_HUDFont"

-- Target ID on dolls
local doll_icon = Material("panicritual/hud/doll_ground.png", "noclamp")
local dollsize = 100
local dolllower = 75

local drawresettime = 0
local nextdrawtime = 0
local targetplayer
local targetids = {
	["player"] = function(ply,w,h,w2,h2)
		if ply:IsHuman() then
			local name = ply:Nick()
			surface.SetFont(targetidfont)
			local w3,h3 = surface.GetTextSize(name)
			w3 = w3 + masksize

			surface.SetMaterial(human_mask)
			surface.DrawTexturedRect(w2 - w3/2, h2 - masksize/2 + lower, masksize, masksize)
			draw.SimpleTextOutlined(name, targetidfont, w2 - w3/2 + masksize, h2 + lower, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, color_black)
		end
	end,
	["ritual_doll"] = function(doll,w,h,w2,h2)
		surface.SetMaterial(doll_icon)
		surface.DrawTexturedRect(w2 - dollsize/2, h2 - dollsize/2 + dolllower, dollsize, dollsize)
		if LocalPlayer():IsHuman() then
			local wep = LocalPlayer():GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "ritual_human" and not wep:GetHasDoll() then
				draw.SimpleTextOutlined("E", "Ritual_HUDFont_Large", w2, h2 + dolllower + dollsize - 50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
			end
		end
	end,
}

local targetdelay = 0.25
local targetident, targetidfunc
local nexttargetiddraw = 0
local demonlight
function GM:HUDPaint()
	local w,h = ScrW(), ScrH()
	local ypad = h - (pad + iconsize)

	-- Health bar backdrop
	surface.SetDrawColor(0,0,0,250)
	surface.SetMaterial(blood_bar)
	surface.DrawTexturedRect(iconsize + pad - 25, ypad + iconsize2 - 2, 500, barthickness)

	-- Health bar front
	surface.SetDrawColor(150,150,150)
	local pct = LocalPlayer():Health()/LocalPlayer():GetMaxHealth()
	surface.DrawTexturedRectUV(iconsize + pad - 25, ypad + iconsize2 - 2, 500*pct, barthickness, 0,0,pct,1)

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blood_blob)
	surface.DrawTexturedRect(pad, ypad, iconsize, iconsize)
	

	-- Human Contract
	surface.SetMaterial(human_contract)
	surface.DrawTexturedRect(pad + pad2 + iconsize, ypad + pad2, iconsize2, iconsize2)
	local humans = team.GetPlayers(TEAM_HUMANS)
	local alive = 0
	for k,v in pairs(humans) do if v:Alive() then alive = alive + 1 end end
	draw.SimpleTextOutlined("x"..alive, "Ritual_HUDFont", pad + pad2 + iconsize + iconsize2, ypad + pad2 + iconsize2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)

	-- Team Icon
	surface.SetMaterial(LocalPlayer():IsDemon() and team_demon or team_human)
	surface.DrawTexturedRect(pad + padinner, ypad + padinner, iconsize - 2*padinner, iconsize - 2*padinner)

	-- Draw demon progress world icons
	if LocalPlayer():IsDemon() then
		for k,v in pairs(circle_ents) do
			if not IsValid(k) then circle_ents[k] = nil else
				local pos = k:GetPos() + offset
				local ts = pos:ToScreen()
				if ts.visible then
					surface.SetMaterial(k:GetHasDoll() and circle_doll or circle_nodoll)
					surface.SetDrawColor(255,255,255)
					surface.DrawTexturedRect(ts.x - circlesize/2, ts.y - circlesize, circlesize, circlesize)

					local req = k:GetRequiredCharge()
					local charge = k:GetProgress()
					local ang = (2*math.pi)/req
					local halfcandle = candlesize/2
					for i = 1, req do
						local a = i*ang - math.pi/2
						surface.SetMaterial(i <= charge and candle_on or candle_off)
						local x = ts.x + math.cos(a)*(candledist)
						local y = ts.y - circlesize/2 + math.sin(a)*(candledist)
						surface.DrawTexturedRect(x - halfcandle, y - halfcandle, candlesize, candlesize)
					end
				end
			end
		end

		if not demonlight then
			demonlight = ProjectedTexture()
			demonlight:SetTexture("vgui/white")
			demonlight:SetFarZ(600)
			demonlight:SetFOV(170)
			demonlight:SetBrightness(0.2)
			demonlight:SetColor(Color(255,100,100))
			print("Created demonlight")
		end
		demonlight:SetPos(EyePos())
		demonlight:SetAngles(EyeAngles())
		demonlight:Update()
	elseif demonlight then
		demonlight:Remove()
		print("removed demonlight")
		demonlight = nil
	end

	-- Target ID
	local tr = LocalPlayer():GetEyeTrace()
	local ct = CurTime()
	local enttotarget = IsValid(tr.Entity) and targetids[tr.Entity:GetClass()] and tr.Entity or nil
	if enttotarget ~= targetident then
		targetident = tr.Entity
		targetidfunc = tr.Entity and targetids[tr.Entity:GetClass()]
		nexttargetiddraw = ct + targetdelay
	end
	if targetident and ct >= nexttargetiddraw then
		local w2,h2 = w/2, h/2
		targetidfunc(targetident,w,h,w2,h2)
	end
end

local PLAYER_LINE = {
	Init = function(self)
		self.Name = self:Add("DLabel")
		self.Name:Dock(FILL)
		--self.Name:SetContentAlignment(0)
		self.Name:SetFont("Ritual_ScrollAlive")
		self.Name:SetTextColor(color_black)
		self.Name:DockMargin(30, -1, 0, 0)

		self.Mute = self:Add("DImageButton")
		self.Mute:SetSize(32, 32)
		self.Mute:Dock(RIGHT)

		self:Dock(TOP)
		self:DockPadding(3, 3, 3, 3)
		self:SetHeight(32 + 3 * 2)
		--self:DockMargin(2, 0, 2, 2)

		self.PaintOver = function(self, w, h)
			--surface.SetDrawColor(200,0,0)
			--surface.DrawRect(20, 14, w-62, 10)

			if not IsValid(self.Player) or not self.Player:Alive() then
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(blood_bar)
				surface.DrawTexturedRect(20, 14, w-62, 10)
			end
		end
	end,

	Setup = function(self, pl)
		self.Player = pl
		if pl == LocalPlayer() then
			self:DockMargin(2, 0, 2, 5)
		end
		self:Think()
	end,

	--[[PerformLayout = function(self)
		self:SetSize(400, 30)
	end,]]

	Think = function(self)
		if not IsValid(self.Player) then
			self:SetZPos(9999)
			g_Scoreboard.NumPlayers = player.GetCount()
			self:Remove()
			return
		end

		if self.PName == nil or self.PName ~= self.Player:Nick() then
			self.PName = self.Player:Nick()
			self.Name:SetText(self.PName)
		end

		if self.PDemon == nil or self.PDemon ~= self.Player:IsDemon() then
			self.PDemon = self.Player:IsDemon()
			self.Name:SetTextColor(self.PDemon and Color(200,0,0) or color_black)
		end

		if self.Muted == nil or self.Muted ~= self.Player:IsMuted() then
			self.Muted = self.Player:IsMuted()
			self.Mute:SetImage(self.Muted and "panicritual/hud/muted.png" or "panicritual/hud/unmuted.png")
			self.Mute.DoClick = function() self.Player:SetMuted(not self.Muted) end
		end

		if self.Player:Team() == TEAM_CONNECTING then
			self:SetZPos(2000 + self.Player:EntIndex())
		end
		
		self:SetZPos(self.Player:EntIndex() - (self.Player:IsDemon() and 3200 or 0))
	end,

	Paint = function(self, w, h)
		--draw.RoundedBox(4, 0, 0, w, h, Color(0, 100, 0, 200))
	end
}
PLAYER_LINE = vgui.RegisterTable(PLAYER_LINE, "DPanel")

local scroll_top = Material("panicritual/hud/scroll_score_top.png", "noclamp")
local scroll_bottom = Material("panicritual/hud/scroll_score_bottom.png", "noclamp")
local scroll_mid = Material("panicritual/hud/scroll_score_mid.png", "noclamp")
local scrollheadsize = 50
local SCORE_BOARD = {
	Init = function(self)
		self.ScrollTop = self:Add("Panel")
		self.ScrollTop:Dock(TOP)
		self.ScrollTop:SetHeight(scrollheadsize)
		self.ScrollTop.Paint = function(self, w, h)
			surface.SetMaterial(scroll_top)
			surface.SetDrawColor(255,255,255)
			surface.DrawTexturedRect(0,0,w,h)
		end

		self.ScrollBottom = self:Add("Panel")
		self.ScrollBottom:Dock(BOTTOM)
		self.ScrollBottom:SetHeight(scrollheadsize)
		self.ScrollBottom.Paint = function(self, w, h)
			surface.SetMaterial(scroll_bottom)
			surface.SetDrawColor(255,255,255)
			surface.DrawTexturedRect(0,0,w,h)
		end

		self.Header = self:Add( "Panel" )
		self.Header:Dock(TOP)
		self.Header:SetHeight(75)

		self.Name = self.Header:Add("DLabel")
		self.Name:SetFont( "Ritual_HUDFont" )
		self.Name:SetTextColor(color_black)
		self.Name:Dock(TOP)
		self.Name:SetHeight(40)
		self.Name:SetContentAlignment(5)

		self.Scores = self:Add("DScrollPanel")
		self.Scores:DockMargin(20,0,30,0)
		self.Scores:Dock(FILL)

		self.TeamDemons = self.Scores:Add("Panel")
		self.TeamDemons:SetZPos(-32001)

		local summoned = self.TeamDemons:Add("DLabel")
		summoned:SetText("Summoned:")
		summoned:DockMargin(10, 0, 0, 0)
		summoned:SetFont("Ritual_Demons")
		summoned:SetTextColor(Color(200,0,0))
		summoned:Dock(FILL)

		local mute = self.TeamDemons:Add("DLabel")
		mute:SetText("Mute")
		mute:DockMargin(0, 0, 0, 0)
		mute:SetFont("Ritual_ScrollAlive")
		mute:SetTextColor(Color(200,0,0))
		mute:SetContentAlignment(6)
		mute:Dock(RIGHT)

		self.TeamDemons:Dock(TOP)
		self.TeamDemons:SetHeight(32)

		--[[self.TeamDemons = self.Scores:Add("DLabel")
		self.TeamDemons:SetZPos(-32001)
		self.TeamDemons:SetText("Summoned:")
		self.TeamDemons:DockMargin(10, 0, 0, 0)
		self.TeamDemons:SetFont("Ritual_Demons")
		self.TeamDemons:SetTextColor(Color(200,0,0))
		self.TeamDemons:Dock(TOP)
		self.TeamDemons:SetHeight(32)]]

		self.TeamHumans = self.Scores:Add("DLabel")
		self.TeamHumans:SetZPos(0)
		self.TeamHumans:SetText("Targets:")
		self.TeamHumans:DockMargin(10, 20, 0, 0)
		self.TeamHumans:SetFont("Ritual_Demons")
		self.TeamHumans:SetTextColor(Color(0,0,0))
		self.TeamHumans:Dock(TOP)
		self.TeamHumans:SetHeight(32)
	end,

	PerformLayout = function(self)
		self:SetSize(500, 600)
		self:SetPos(100, ScrH()/2 - 300)
	end,

	Paint = function(self, w, h)
		surface.SetMaterial(scroll_mid)
		surface.SetDrawColor(255,255,255)
		local p = scrollheadsize/2
		surface.DrawTexturedRect(0,p,w,h-p*2)
	end,

	Think = function(self, w, h)
		self.Name:SetText(GetHostName())

		local plys = player.GetAll()
		for id, pl in pairs(plys) do
			if IsValid(pl.ScoreEntry) then continue end

			pl.ScoreEntry = vgui.CreateFromTable(PLAYER_LINE, pl.ScoreEntry)
			pl.ScoreEntry:Setup(pl)
			self.Scores:AddItem(pl.ScoreEntry)
		end
	end
}

SCORE_BOARD = vgui.RegisterTable(SCORE_BOARD, "DPanel")

function GM:ScoreboardShow()
	if not IsValid(g_Scoreboard) then
		g_Scoreboard = vgui.CreateFromTable(SCORE_BOARD)
	end

	if IsValid(g_Scoreboard) then
		g_Scoreboard:Show()
		g_Scoreboard:MakePopup()
		g_Scoreboard:SetKeyboardInputEnabled(false)
	end
end

function GM:ScoreboardHide()
	if IsValid(g_Scoreboard) then
		g_Scoreboard:Hide()
	end
end