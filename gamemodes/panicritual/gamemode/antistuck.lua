local PLAYER = FindMetaTable("Player")

function PLAYER:GetNoCollidePlayers()
	return self:GetNW2Bool("Ritual_NoCollidePlayers")
end

if SERVER then
	function PLAYER:SetNoCollidePlayers(b)
		self:SetNW2Bool("Ritual_NoCollidePlayers", b)
		self:CollisionRulesChanged()
	end

	local checkfreq = 0.2
	-- Checks if a player is inside a player, if so, nocollides the player until free
	function PLAYER:CollideWhenPossible()
		if IsValid(self) then
			local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
			if IsValid(tr.Entity) and tr.Entity:IsPlayer() then -- We're inside another entity
				self:SetNoCollidePlayers(true)
				local nextcheck = 0
				local id = self:EntIndex()
				hook.Add("Think", "Ritual_CollideWhenPossible_"..id, function()
					if nextcheck < CurTime() then
						if IsValid(self) then
							local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
							if IsValid(tr.Entity) then
								nextcheck = CurTime() + checkfreq
								return
							end
							self:SetNoCollidePlayers(false)
							print("No longer colliding")
							self:CollisionRulesChanged()
						end
						hook.Remove("Think", "Ritual_CollideWhenPossible_"..id)
					end
				end)
			end
		end
	end
end

hook.Add("ShouldCollide", "Ritual_PlayerCollision", function(e1, e2)
	if e1:IsPlayer() and e2:IsPlayer() and (e1:GetNoCollidePlayers() or e2:GetNoCollidePlayers()) then return false end
end)