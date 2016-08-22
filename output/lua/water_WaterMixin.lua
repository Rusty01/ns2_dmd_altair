// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
//   	Water for NS2
//		by Feha
//		
// ========= For more information, ask me =====================

// water_InWaterMixin.lua

WaterMixin = CreateMixin( WaterMixin )
WaterMixin.type = "Water"

WaterMixin.expectedMixins =
{
}

WaterMixin.expectedCallbacks =
{
	GetIsEntitySubmerged = "Returns point of submersion and percentage submerged of given entity. Returning nil means not submerged",
	IsPointSubmerged = "Returns true if given vector is submerged"
}
WaterMixin.optionalCallbacks =
{
	OnEntityEntered = "Called when entity enters water",
	OnEntityExit = "Called when entity exits water",
	OnEntityInside = "Called while entity is inside water"
}

WaterMixin.expectedConstants =
{
}

WaterMixin.networkVars =
{
}

--globals
WaterMixin.WaterEntities = {}

function WaterMixin:__initmixin()
	WaterMixin.WaterEntities[self] = self
end

function WaterMixin:OnDestroy()
    WaterMixin.WaterEntities[self] = nil
end
