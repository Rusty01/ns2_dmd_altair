// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
//   	Floating for NS2
//		by Feha
//		
// ========= For more information, ask me =====================

// water_BuoyancyMixin.lua

Script.Load("lua/FunctionContracts.lua")

SuffocationMixin = CreateMixin( SuffocationMixin )
SuffocationMixin.type = "Suffocation"

SuffocationMixin.expectedMixins =
{
	 InWater = "Needed to know when if in water or not"
}

SuffocationMixin.expectedCallbacks =
{
	GetCanBreath = "Entity suffocates while this returns false",
	GetInitialSuffocationDelay = "The time between each damage",
	GetSuffocationDelay = "The time between each damage"
}
SuffocationMixin.optionalCallbacks =
{
	OnSuffocationDamage = "When an entity takes damage from suffocation, this is also called",
	AdjustSuffocationDamage = "If the entity has exceptions where the damage has to be adjusted"
}

SuffocationMixin.expectedConstants =
{
}

SuffocationMixin.networkVars =
{
}

function SuffocationMixin:__initmixin()
	
end

function SuffocationMixin:OnInsideWater(waterentity)
	if waterentity.suffocation then
		if self:GetIsInWater() and not self:GetCanBreath() and self:GetIsAlive() then
			if not self.suffocate then
				self.suffocate = Shared.GetTime() + self:GetInitialSuffocationDelay()
			end
			
			if self.suffocate < Shared.GetTime() then
				if self.OnSuffocationDamage then
					self:OnSuffocationDamage(waterentity)
				end
				
				if HasMixin(self, "Live") and not (self.GetDarwinMode and self:GetDarwinMode()) then
					local damageTable = {
						damageHealth = 0,
						damageArmor = 0,
						damageType = kDamageType.Normal
					}
					if self.AdjustSuffocationDamage then
						self:AdjustSuffocationDamage(damageTable)
					end
					
					local engagePoint = HasMixin(self, "Target") and self:GetEngagementPoint() or self:GetOrigin()
					self:TakeDamage(damageTable.damageHealth + damageTable.damageArmor, nil, nil, engagePoint, nil, damageTable.damageArmor, damageTable.damageHealth, damageTable.damageType)
				end
				
				self.suffocate = self.suffocate + self:GetSuffocationDelay()
			end
		elseif self:GetCanBreath() then
			self.suffocate = nil
		end
	end
end
