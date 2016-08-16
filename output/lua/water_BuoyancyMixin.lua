// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
//   	Floating for NS2
//		by Feha
//		
// ========= For more information, ask me =====================

// water_BuoyancyMixin.lua

Script.Load("lua/FunctionContracts.lua")

BuoyancyMixin = CreateMixin( BuoyancyMixin )
BuoyancyMixin.type = "Buoyancy"

BuoyancyMixin.expectedMixins =
{
	 GroundMove = "Needed for adjusting velocity when floating",
	 InWater = "Needed to know when if in water or not"
}

BuoyancyMixin.expectedCallbacks =
{
	GetWaterFriction = "The friction force used when in water"
}
BuoyancyMixin.optionalCallbacks =
{
	AdjustBuoyancyForce = "Should return the current float force for the entity using this Mixin.",
	GetIsBuoyant = "Implemented when you want to be able to disable floating"
}

BuoyancyMixin.expectedConstants =
{
}

BuoyancyMixin.networkVars =
{
}

function BuoyancyMixin:__initmixin()
	
	self.oldGetFriction = self.GetFriction
	self.GetFriction = function(self, input, velocity)
		if self:GetIsInWater() and not self:GetIsOnGround() and (self.GetIsBuoyant and self:GetIsBuoyant() or not self.GetIsBuoyant) then
			return self:GetBuoyancyFriction(input, velocity)
		else
			return self:oldGetFriction(input, velocity)
		end
	end
	
end


function BuoyancyMixin:GetBuoyancyFriction(input, velocity)

	local friction = GetNormalizedVector(-velocity)
    local velocityLength = velocity:GetLength()
    local frictionScalar = 1

    local waterFriction = self:GetWaterFriction() or 0
    local airFriction = self:GetAirFriction()
    
	local inWaterFraction = self:GetSubmersionPercentage()
    frictionScalar = velocityLength * (inWaterFraction * waterFriction + math.max(1 - inWaterFraction,0) * airFriction)
    
    // use minimum friction when on ground
    if input.move:GetLength() == 0 and self.onGround and velocity:GetLength() < 4 then
        frictionScalar = math.max(5, frictionScalar)
    end
	
    return friction * frictionScalar
	
end
AddFunctionContract(BuoyancyMixin.GetBuoyancyFriction, { Arguments = { "Entity", "Move", "Vector" }, Returns = { "Vector" } })


function BuoyancyMixin:GetBuoyancyForce(input)
	local gravityTable = { gravity = self:GetGravityForce(input) }
	if self.ModifyGravityForce then
        self:ModifyGravityForce(gravityTable)
    end
	
	return self:GetSubmersionPercentage() * gravityTable.gravity * -1 * (self:GetBuoyancyGravityScale() or 0.5)
end
AddFunctionContract(BuoyancyMixin.GetBuoyancyForce, { Arguments = {"Entity", "Move"}, Returns = { "Vector" } })

function BuoyancyMixin:ApplyBuoyancy(input, velocity, deltatime)
	local buoyancyTable = { buoyancy = self:GetBuoyancyForce(input) }
    if self.AdjustBuoyancyForce then
        self:AdjustBuoyancyForce(buoyancyTable, input, velocity, deltatime)
    end
	
	velocity.y = velocity.y + buoyancyTable.buoyancy * deltatime
end
AddFunctionContract(BuoyancyMixin.ApplyBuoyancy, { Arguments = {"Entity", "Move", "Vector", "float"}, Returns = { "Vector" } })


-- GroundMoveMixin calls this callback, which I then use to apply the entities floating to the physics.
function BuoyancyMixin:ModifyVelocity(input, velocity, deltatime)
	if self:GetIsInWater() and (self.GetIsBuoyant and self:GetIsBuoyant() or not self.GetIsBuoyant) then
		self:ApplyBuoyancy(input, velocity, deltatime)
	end
end
