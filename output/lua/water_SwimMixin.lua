// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
//   	Swimming for NS2
//		by Feha
//		
// ========= For more information, ask me =====================

// water_SwimMixin.lua

Script.Load("lua/FunctionContracts.lua")

SwimMixin = CreateMixin( SwimMixin )
SwimMixin.type = "Swim"

SwimMixin.expectedMixins =
{
	 GroundMove = "Needed for adjusting velocity when floating",
	 InWater = "Needed to know when if in water or not"
}

SwimMixin.expectedCallbacks =
{
	GetIsSwimming = "Returns true if swimming"
}
SwimMixin.optionalCallbacks =
{
	AdjustSwimVelocity,
	GetCanSim = "returns false if the entity cant swim"
}

SwimMixin.expectedConstants =
{
}

SwimMixin.networkVars =
{
}

function SwimMixin:__initmixin()

end

function SwimMixin:GetSwimVelocity(input, deltatime)
	local velocity = Vector(0, 0, 0)
	if self:GetIsSwimming() and (self.GetCanSim and self:GetCanSwim() or not self.GetCanSwim) then
		
		-- Let entities using this mixin be able to define how they float in water
		if self.AdjustSwimVelocity then
			self:AdjustSwimVelocity(velocity, input, deltatime)
		end
	
	end
	
	return velocity
end
AddFunctionContract(SwimMixin.GetSwimVelocity, { Arguments = { "Entity", "Move" }, Returns = { "Vector" } })


-- GroundMoveMixin calls this callback, which I then use to apply the entities floating to the physics.
function SwimMixin:ModifyVelocity(input, velocity, deltatime)
	local newVelocity = velocity + self:GetSwimVelocity(input, deltatime) * deltatime
	
	-- There has to be a better way to copy the values from one vector into another...
	velocity.x = newVelocity.x
	velocity.y = newVelocity.y
	velocity.z = newVelocity.z
end
