DEFINE_BASECLASS( "player_default" )

local PLAYER = {}
PLAYER.WalkSpeed 			= 200
PLAYER.RunSpeed				= 400

local function datatables(self)
	self.Player:NetworkVar("Bool", 0, "RitualFading")
	self.Player:NetworkVar("Bool", 1, "RitualTormented")
	self.Player:NetworkVar("Float", 0, "RitualStamina")
end

hook.Add("OnEntityCreated", "Ritual_InstallPlayerDataTables", function(ent)
	if ent:IsPlayer() then
		ent:InstallDataTable()
		datatables({Player = ent}) -- Dumb workaround
	end
end)

function PLAYER:SetupDataTables()
	datatables(self)
end

function PLAYER:Loadout()

end

function PLAYER:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

--[[local function staminamove(self, mv)
	--print("called for", self.Player)
	if SERVER and IsFirstTimePredicted() then
		local ply = self.Player
		local g_sprint = ply:Alive() and ply:IsSprinting()
		if g_sprint then
			local stamina = ply:GetStamina()
			--local stamina = ply.Ritual_Stamina
			if stamina <= 0 then
				if not ply.RitualWalking then
					ply:SetRunSpeed(self.WalkSpeed)
					ply.RitualWalking = true
					ply.NextStaminaRecover = CurTime() + self.StaminaRecoverDelay
				end
			else
				if ply.RitualWalking then
					ply:SetRunSpeed(self.RunSpeed)
					ply.RitualWalking = false
				end
				local val = math.Approach(stamina, 0, FrameTime()*self.StaminaLoss)
				ply:SetStamina(val)
			end
		else
			local ct = CurTime()
			if not ply.RitualWalking then
				ply.RitualWalking = true
				ply.NextStaminaRecover = ct + self.StaminaRecoverDelay
			end
			if ply.NextStaminaRecover and ct >= ply.NextStaminaRecover then
				local val = math.Approach(ply:GetRitualStamina(), 100, FrameTime()*self.StaminaRecover)
				ply:SetStamina(val)
			end
		end
	end
end]]

local function staminamove(self, mv)
	if IsFirstTimePredicted() then
		local ply = self.Player
		if mv:KeyPressed(IN_SPEED) then
			ply.Ritual_Stamina = ply:GetStamina()
			local ct = CurTime()
			if ply.Ritual_Stamina > 0 and (not ply.Ritual_StaminaLock or ct > ply.Ritual_StaminaLock) then
				ply.Ritual_SprintTime = ct
				ply.Ritual_SprintForceEndTime = ct + ply.Ritual_Stamina/self.StaminaLoss
				ply.Ritual_SprintRecovered = false
				ply.Ritual_Sprinting = true
			end
		elseif mv:KeyReleased(IN_SPEED) and ply.Ritual_Sprinting then
			ply.Ritual_Stamina = ply:GetStamina()
			ply.Ritual_SprintTime = CurTime() + self.StaminaRecoverDelay
			ply.Ritual_Sprinting = false
			ply.Ritual_SprintForceEndTime = nil
		elseif ply.Ritual_SprintForceEndTime then
			local ct = CurTime()
			if ct >= ply.Ritual_SprintForceEndTime then
				ply.Ritual_SprintTime = ct + self.StaminaRecoverDelay
				ply.Ritual_Sprinting = false
				ply.Ritual_Stamina = 0
				ply.Ritual_SprintForceEndTime = nil
				if SERVER then
					ply:SetRunSpeed(self.WalkSpeed)
				end
			end
		elseif not ply.Ritual_Sprinting and not ply.Ritual_SprintRecovered and ply.Ritual_SprintTime then
			local ct = CurTime()
			if ct >= ply.Ritual_SprintTime and not mv:KeyDown(IN_SPEED) then
				if SERVER then ply:SetRunSpeed(self.RunSpeed) end
				ply.Ritual_SprintRecovered = true
			end
		end
	end
end

local META = FindMetaTable("Player")
local demonwalkspeed = 200
local demonrunspeed = 350
local demonstaminaloss = 10
local demonstaminarecover = 10
local demonrecoverdelay = 5

local humanwalkspeed = 150
local humanrunspeed = 400
local humanstaminaloss = 10
local humanstaminarecover = 10
local humanrecoverdelay = 5

function META:GetStamina()
	--self:GetRitualStamina()
	local ct = CurTime()
	if not self.Ritual_SprintTime then self.Ritual_SprintTime = ct end
	local diff = ct - self.Ritual_SprintTime
	if diff > 0 then
		-- Calculate the time difference
		local delta
		if self.Ritual_Sprinting then
			delta = -diff*(self:IsDemon() and demonstaminaloss or humanstaminaloss)
		else
			delta = diff*(self:IsDemon() and demonstaminarecover or humanstaminarecover)
		end
		return math.Clamp((self.Ritual_Stamina or 100) + delta, 0, 100)
	else
		return self.Ritual_Stamina or 100 -- last known one
	end
end

local oldsprint = META.IsSprinting
function META:IsSprinting()
	if self.Ritual_Sprinting ~= nil then return self.Ritual_Sprinting else return oldsprint(self) end
end

if SERVER then
	util.AddNetworkString("ritual_stamina_lock")
	function META:StaminaLock(time, reduction)
		local ct = CurTime()
		self.Ritual_StaminaLock = ct + time
		self.Ritual_Stamina = self:GetStamina() - (reduction or 0)
		self.Ritual_SprintTime = ct + (self:IsDemon() and demonrecoverdelay or humanrecoverdelay) + time
		self.Ritual_Sprinting = false
		self.Ritual_SprintForceEndTime = nil
		self:SetRunSpeed(self:IsDemon() and demonwalkspeed or humanwalkspeed)
		self.Ritual_SprintTime = ct + time
		self.Ritual_SprintRecovered = false

		net.Start("ritual_stamina_lock")
			net.WriteFloat(time)
			net.WriteFloat(self.Ritual_Stamina)
		net.Send(self)
	end
else
	net.Receive("ritual_stamina_lock", function()
		local time = net.ReadFloat()
		local stamina = net.ReadFloat()
		local ply = LocalPlayer()
		local ct = CurTime()

		ply.Ritual_Stamina = stamina
		ply.Ritual_SprintTime = ct + (ply:IsDemon() and demonrecoverdelay or humanrecoverdelay) + time
		ply.Ritual_Sprinting = false
		ply.Ritual_SprintForceEndTime = nil
		ply.Ritual_SprintTime = ct + time

		ply.Ritual_SprintRecovered = false
		ply.Ritual_StaminaLock = ct + time
		ply.Ritual_StaminaLockTime = time
	end)
end


player_manager.RegisterClass( "player_ritual_base", PLAYER, "player_default" )
DEFINE_BASECLASS("player_ritual_base")

local HUMANS = {}
HUMANS.WalkSpeed = humanwalkspeed
HUMANS.RunSpeed = humanrunspeed
HUMANS.StaminaLoss = humanstaminaloss -- every second (max = 100)
HUMANS.StaminaRecover = humanstaminarecover -- every second
HUMANS.StaminaRecoverDelay = humanrecoverdelay -- how long before stamina starts recovering
function HUMANS:SetupDataTables()
	datatables(self)
end

function HUMANS:Loadout()
	self.Player:Give("ritual_human")
end

local humans = { -- the models
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/male_08.mdl",
	"models/player/group01/male_09.mdl"
}
local pcolors = {
	Vector(0.5,0,0),
	Vector(0.3,0.3,0),
	Vector(0.0,0.5,0),
	Vector(0,0.3,0.3),
	Vector(0,0,0.5),
	Vector(0.3,0,0.3),
	Vector(0.1,0.1,0.1),
}
function HUMANS:Init()
	if SERVER then
		self.Player:SetModel(humans[math.random(#humans)])
		self.Player:SetPlayerColor(pcolors[math.random(#pcolors)])
		self.Player:SetupHands()
		self.Player:SetRitualStamina(100)
		self:ApplyMoveSpeeds()
	end
	self.Player.Ritual_Stamina = 100
end

function HUMANS:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

function HUMANS:Move(mv)
	staminamove(self, mv)
end

player_manager.RegisterClass( "player_ritual_human", HUMANS, "player_ritual_base" )

local DEMONS = {}
DEMONS.WalkSpeed = demonwalkspeed
DEMONS.RunSpeed = demonrunspeed
DEMONS.StaminaLoss = demonstaminaloss -- How many seconds of sprint
DEMONS.StaminaRecover = demonstaminarecover -- every second
DEMONS.StaminaRecoverDelay = demonrecoverdelay -- how long before stamina starts recovering

function DEMONS:SetupDataTables()
	datatables(self)
end

function DEMONS:Loadout()
	self.Player:Give("ritual_demon_possess")
end

local demonmodel = "models/player/panicritual/keeper_hooded_red.mdl"
local afktime = 60 -- seconds of not pressing any buttons to AFK
local afkwarn = 30
function DEMONS:Init()
	if SERVER then
		self.Player:SetModel(demonmodel)
		self.Player:SetupHands()
		self.Player:SetRitualStamina(100)
		self:ApplyMoveSpeeds()
	end
	self.Player.Ritual_Stamina = 100
end

function DEMONS:ApplyMoveSpeeds()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
end

if not ConVarExists("ritual_afktime") then CreateConVar("ritual_afktime", 60, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "The amount of time with Demons no moving to slay them. Set to 0 to disable.") end
local time = GetConVar("ritual_afktime")

function DEMONS:StartMove(mv, cmd)
	if SERVER and self.Player:Alive() then
		local ct = CurTime()
		local t = time:GetInt()
		if t > 0 then
			if not self.AFKTime then self.AFKTime = CurTime() + t end
			if not self.AFKWarn then self.AFKWarn = CurTime() + t*0.5 end

			if cmd:GetButtons() > 0 then self.AFKTime = ct + t self.AFKWarn = ct + t*0.5 end
			if ct > self.AFKTime then
				self.AFKTime = nil
				self.Player:SetTeam(TEAM_SPECTATORS)
				self.Player:Kill()
				PrintMessage(HUD_PRINTTALK, self.Player:Nick() .. " was slain for being AFK!")
			end
			if self.AFKWarn and ct > self.AFKWarn then
				self.Player:SendHint("afk")
				self.AFKWarn = nil
			end
		end
	end
end

function DEMONS:Move(mv)
	staminamove(self, mv)
end

player_manager.RegisterClass( "player_ritual_demon", DEMONS, "player_ritual_base" )