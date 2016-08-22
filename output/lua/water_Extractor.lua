// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// NS2 water Mod
//	Made by feha, 20??
//
// ========= For more information, ask me =====================

// water_Extractor.lua

Script.Load("lua/Class.lua")
Script.Load("lua/water_inWaterMixin.lua")
Script.Load("lua/water_SuffocationMixin.lua")


-- Mixin callbacks

-- InWaterMixin
function Extractor:OnSetIsInWater(entered, waterEntity)
	-- stuff that happens while in water
end


-- WaterSuffocationMixin
function Extractor:GetCanBreath()
	return not (self:GetSubmersionState() >= 2)
end

function Extractor:GetInitialSuffocationDelay()
	return 2
end

function Extractor:GetSuffocationDelay()
	return 1
end

function Extractor:GetSuffocationDamage()
	return 25
end

function Extractor:GetSuffocationDamageType()
	return kDamageType.Corrode
end

function Extractor:OnSuffocationDamage(waterEntity)
end


------ Overrides -------
local oldOnCreate
oldOnCreate = Class_ReplaceMethod( "Extractor", "OnCreate",
	function(self)
		
		oldOnCreate(self)
		
		// Init mixins
		InitMixin(self, InWaterMixin)
		InitMixin(self, SuffocationMixin)
		
	end
)
