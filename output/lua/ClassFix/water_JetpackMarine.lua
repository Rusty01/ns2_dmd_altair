//________________________________
//
// NS2 water Mod
//	Made by feha, 20??
//
//________________________________

// water_Player.lua

// Is this really needed to overwrite functions?!?
Script.Load("lua/Class.lua")


------ Overrides -------
--[[
local oldAdjustGravityForce
oldAdjustGravityForce = Class_ReplaceMethod( "JetpackMarine", "AdjustGravityForce",
	function(self, input, gravity)
		local gravity = oldAdjustGravityForce(self, input, gravity)
	
		if (self:GetIsInWater()) then
			gravity = gravity * self:GetSwimGravityScale()
			
			--Shared.Message("in water = " .. tostring(gravity))
		end
		
		return gravity
	end
)
--]]
local oldModifyGravityForce
oldModifyGravityForce = Class_ReplaceMethod( "JetpackMarine", "ModifyGravityForce",
	function(self, gravityTable)
		if self:GetIsInWater() then
			if self:GetCrouching() then
				gravityTable.gravity = gravityTable.gravity * 2
			elseif self.swimming then
				gravityTable.gravity = 0
			end
		end
		
		oldModifyGravityForce(self, gravityTable)
	end
)