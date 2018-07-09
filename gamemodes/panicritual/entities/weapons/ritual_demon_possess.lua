if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= true
	SWEP.AutoSwitchFrom	= false
end

if CLIENT then

	SWEP.PrintName     	    = "Demon Claws"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end

SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Kill Humans"
SWEP.Instructions	= "Left Click to leap!"

SWEP.HoldType = "knife"

SWEP.ViewModel	= "models/weapons/c_ritual_demon.mdl"
SWEP.WorldModel	= "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.vModel = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"



function SWEP:SetupDataTables()
	
end

function SWEP:Initialize()
	self.NextLeap = 0
	self.NextFade = 0
	self:SetHoldType(self.HoldType)
end

if SERVER then
	function SWEP:PlayActAndWait(act, cycle)
		local vm = self.Owner:GetViewModel()
		local seq = vm:SelectWeightedSequence(act)
		local len = vm:SequenceDuration(seq)

		vm:SetSequence(seq)
		if cycle then
			vm:SetCycle(cycle)
			len = len * (1 - cycle)
		end
		self.NextIdleTime = CurTime() + len

		return len
	end

	function SWEP:PlaySequenceAndWait(seq, cycle)
		local vm = self.Owner:GetViewModel()
		local id, dur = vm:LookupSequence(seq)

		vm:SetSequence(id)
		if cycle then
			vm:SetCycle(cycle)
			len = len * (1 - cycle)
		end
		self.NextIdleTime = CurTime() + dur

		return dur
	end
end

function SWEP:Deploy()
	
end

function SWEP:DrawHUD()

end

function SWEP:OnRemove()
	
end

-- Primary attack: Short-range fade
local fadecooldown = 3
local fadetime = 0.25
local fadespeed = 1000
function SWEP:PrimaryAttack()
	if CLIENT then return end
	--if self.Leaping then return end

	--if self.CirclesToPlace then
	if true then --GAMEMODE.RoundState == ROUND_PREPARE then
		-- Logic for circle placing
		local b = GAMEMODE:PlaceRitualCircle(self.Owner:GetEyeTrace().HitPos, Angle(0,self.Owner:GetAngles().y,0))
		if b then self:PlayActAndWait(ACT_VM_THROW) end
	return end

	local ct = CurTime()
	if ct < self.NextFade then return end

	self.Owner:SetFading(true)
	self.Owner:SetWalkSpeed(fadespeed)
	self.Owner:SetRunSpeed(fadespeed)

	self.FadeTime = ct + fadetime
	self.NextFade = ct + fadecooldown
end

-- Secondary attack: Long-range fade leap
local leapcooldown = 2 -- Cooldown after landing
local minleap = 300
local chargedleap = 300 -- +power for charging fully
local maxchargetime = 1.5 -- Seconds of LMB to reach full charge leap
if SERVER then
	function SWEP:Think()
		local ct = CurTime()
		if self.Leaping then
			if self.Owner:IsOnGround() or self.Owner:WaterLevel() >= 2 then
				self.NextLeap = CurTime() + leapcooldown
				self.Leaping = false
				if not self.FadeTime then
					self.Owner:SetFading(false)
				end
			end
		elseif self.FadeTime and ct > self.FadeTime then
			player_manager.RunClass(self.Owner, "ApplyMoveSpeeds")
			self.Owner:SetFading(false)
			self.FadeTime = nil
		end

		if self.LeapCharging then
			local diff = ct - self.LeapCharging
			if not self.Owner:KeyDown(IN_ATTACK2) or diff >= maxchargetime then
				local power = minleap + (diff/maxchargetime)*chargedleap
				self:Leap(power)
			end
		end

		if self.NextIdleTime and not self.AnimBlocked and ct > self.NextIdleTime then
			self:SendWeaponAnim(self.NextIdleAct or ACT_VM_IDLE)
			self.NextIdleTime = nil
		end
	end
end
function SWEP:SecondaryAttack()
	if SERVER and self.NextLeap and CurTime() > self.NextLeap then
		if self.FadeTime then
			self:Leap(minleap + chargedleap)
		else
			self.LeapCharging = CurTime()
		end
	end
end

function SWEP:Leap(power)
	self.Owner:SetFading(true)
	self.Owner:SetVelocity((self.Owner:GetAimVector() + Vector(0,0,0.4))*power)
	self.Leaping = true
	self.LeapCharging = false
	self.NextLeap = nil
end

function SWEP:OnRemove()
	if IsValid(self.Owner) and self.Owner:GetFading() then self.Owner:SetFading(false) end
end

function SWEP:EnterFade()
	self.AnimBlocked = true
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:ExitFade(kill)
	self.AnimBlocked = false
	self:PlayActAndWait(IsValid(kill) and ACT_VM_HITCENTER or ACT_VM_MISSCENTER)
end





--[[-------------------------------------------------------------------------
	Logic for possessing/torment
---------------------------------------------------------------------------]]


local PLAYER = FindMetaTable("Player")

--[[function PLAYER:GetPossessing()
	return self:GetNW2Entity("Ritual_PossessTarget")
end
function PLAYER:GetPossessed()
	return self:GetNW2Entity("Ritual_PossessInflictor")
end]]

function PLAYER:GetFading()
	return self:GetNW2Bool("Ritual_Fading")
end

function PLAYER:GetTormented()
	return self:GetNW2Bool("Ritual_Torment")
end

if SERVER then
	function PLAYER:SetFading(b)
		self:SetNW2Bool("Ritual_Fading", b)
		if b then
			self:SetNoCollidePlayers(true)
			local wep = self:GetActiveWeapon()
			if wep.EnterFade then wep:EnterFade() end
		else
			local wep = self:GetActiveWeapon()
			local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
			if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
				if tr.Entity:IsDemon() then
					self:CollideWhenPossible()
					if wep.ExitFade then wep:ExitFade() end
				else
					tr.Entity:SoulTorment(self)
					self:SetNoCollidePlayers(false)
					if wep.ExitFade then wep:ExitFade(tr.Entity) end
				end
			else
				self:SetNoCollidePlayers(false)
				if wep.ExitFade then wep:ExitFade() end
			end
		end

		local e = EffectData()
		e:SetOrigin(self:GetPos() + Vector(0,0,40))
		e:SetRadius(60)
		util.Effect(b and "ritual_fadein" or "ritual_fadeout", e, true, true)

		if b then
			local e2 = EffectData()
			e2:SetEntity(self)
			e2:SetScale(10) -- Particle size
			e2:SetRadius(30) -- Max trail distance
			e2:SetMagnitude(5) -- Number of trails
			e:SetOrigin(Vector(0,0,40)) -- offset
			util.Effect("ritual_fadetrail", e, true, true)
		end
	end

	function PLAYER:SoulTorment(inflictor)
		self.TormentInflictor = inflictor
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetNW2Bool("Ritual_Torment", true)

		local e = EffectData()
		e:SetEntity(self)
		e:SetRadius(10)
		util.Effect("ritual_torment", e, true, true)
	end

	function PLAYER:ReleaseSoulTorment()
		self.TormentInflictor = nil
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		self:SetNW2Bool("Ritual_Torment", false)
	end

	hook.Add("PlayerSpawn", "Ritual_FadeSpawn", function(ply)
		if ply:GetFading() then ply:SetFading(false) end
	end)
end

local tormentanim = "death_04"
-- Attempt to redo this using Death-related hooks instead?
-- Need to fix clientside ragdoll flinging away :(

hook.Add("CalcMainActivity", "Ritual_TormentAnim", function(ply)
	if ply:GetTormented() then
		return ACT_DIEVIOLENT, ply:LookupSequence(tormentanim)
	end
end)

hook.Add("UpdateAnimation", "Ritual_TormentAnim", function(ply, vel, groundspeed)
	if ply:GetTormented() ~= ply.TormentAnim then	
		local seq = ply:LookupSequence(tormentanim)
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, seq, ply.TormentAnim and 1 or 0, true)
		ply:SetCycle(0)
		ply.TormentAnim = ply:GetTormented()
		ply.TormentDeathTime = ply.TormentAnim and CurTime() + ply:SequenceDuration(seq) or nil
	end

	if ply.TormentAnim and ply.TormentDeathTime < CurTime() then
		ply:SetCycle(1)
		if SERVER then
			local d = DamageInfo()
			d:SetDamage(ply:Health())
			d:SetAttacker(ply.TormentInflictor)
			d:SetInflictor(ply.TormentInflictor)
			d:SetDamageType(DMG_PARALYZE)
			d:SetDamagePosition(ply:GetPos())
			d:SetDamageForce(Vector(0,0,0))

			ply:TakeDamageInfo(d)
			ply:ReleaseSoulTorment()
		end
	end
end)

if SERVER then
	hook.Add("DoPlayerDeath", "Ritual_TormentDeath", function(ply, att, dmg)
		--[[ply:SoulTorment(att)
		print("Tormenting")
		ply:CreateRagdoll()]]
	end)

	hook.Add("PlayerSpawn", "Ritual_TormentSpawn", function(ply)
		if ply:GetTormented() then ply:ReleaseSoulTorment() end
	end)
end

if CLIENT then
	hook.Add("PrePlayerDraw", "Ritual_FadeDraw", function(ply)
		if ply:GetFading() then return true end
	end)

	hook.Add("CalcView", "Ritual_TormentCam", function(ply, pos, angles, fov)
		if ply:GetTormented() then
			-- Getting siphoned
			local view = {}
			local eyes = ply:GetAttachment(ply:LookupAttachment("eyes"))
			view.origin = eyes.Pos
			view.angles = eyes.Ang

			view.fov = fov
			view.drawviewer = true

			return view
		end
	end)

	-- Doesn't do anything :(
	--[[hook.Add("CreateClientsideRagdoll", "Ritual_TormentRagdoll", function(ent, rag)
		if ent == LocalPlayer() then
			timer.Simple(0.5, function() rag:SetVelocity(Vector(0,0,0)) end)
		end
	end)]]
end