//________________________________
//
// NS2 water Mod
//	Made by feha, 20??
//
//________________________________

// water_Skulk.lua

// Is this really needed to overwrite functions?!?
Script.Load("lua/Class.lua")


------ Overrides -------
local oldOnCreate
oldOnCreate = Class_ReplaceMethod( "Skulk", "OnCreate",
	function(self)
		
		oldOnCreate(self)
		
		self.kSwimForwardAccel = 50
		self.kSwimStrafeAccel = 50
		self.kSwimUpAccel = 50
		self.kBuoyancyGravityScale = 0.5
		
	end
)

local oldModifyGravityForce
oldModifyGravityForce = Class_ReplaceMethod( "Skulk", "ModifyGravityForce",
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