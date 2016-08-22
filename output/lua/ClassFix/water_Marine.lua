
-- Mixin callbacks

-- WaterBuoyancyMixin
function Player:OnHealed()
	self.suffocate = nil -- reset suffocation timer when healed
end