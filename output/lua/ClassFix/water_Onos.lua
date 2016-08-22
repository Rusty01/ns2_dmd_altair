//________________________________
//
// NS2 water Mod
//	Made by feha, 20??
//
//________________________________

// water_Onos.lua

// Is this really needed to overwrite functions?!?
Script.Load("lua/Class.lua")


------ Overrides -------
local oldOnCreate
oldOnCreate = Class_ReplaceMethod( "Onos", "OnCreate",
	function(self)
		
		oldOnCreate(self)
		
		self.kSwimForwardAccel = 40
		self.kSwimStrafeAccel = 40
		self.kSwimUpAccel = 40
		self.kBuoyancyGravityScale = 0.5
		
	end
)