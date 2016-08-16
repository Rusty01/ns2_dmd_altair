// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// NS2 water Mod
//	Made by feha, 20??
//
// ========= For more information, ask me =====================

// water_CorrodeMixin.lua

-- Anyone ever considered the fact that use and sue only moves one letter one space? And that You can get sued when you used stuff?

Script.Load("lua/Class.lua")
Script.Load("lua/water_inWaterMixin.lua")
Script.Load("lua/water_SuffocationMixin.lua")


------ Overrides -------
local old__initmixin = CorrodeMixin.__initmixin
function CorrodeMixin:__initmixin()

    old__initmixin(self)
	
	// Init mixins
	if not HasMixin(self, InWaterMixin.type) then InitMixin(self, InWaterMixin) end
	if not HasMixin(self, SuffocationMixin.type) then InitMixin(self, SuffocationMixin) end
    
end


-- WaterSuffocationMixin callbacks
function CorrodeMixin:GetCanBreath()
	return self:GetSubmersionState() == 0
end

function CorrodeMixin:GetInitialSuffocationDelay()
	return 1
end

function CorrodeMixin:GetSuffocationDelay()
	return 1
end

function CorrodeMixin:AdjustSuffocationDamage(damageTable)
	if not self:isa("Player") then
		local damage = kInfestationCorrodeDamagePerSecond-- * math.max(10 * self:GetSubmersionPercentage(), 1) -- should depth matter for corrosion?
		damage, armorUsed, healthUsed = GetDamageByType(self, nil, nil, damage, kDamageType.Corrode)
		damageTable.damageHealth = damageTable.damageHealth + healthUsed
		damageTable.damageArmor = damageTable.damageArmor + armorUsed
	end
	damageTable.damageType = kDamageType.Corrode
end

function CorrodeMixin:GetSuffocationDamageType()
	return kDamageType.Corrode
end
