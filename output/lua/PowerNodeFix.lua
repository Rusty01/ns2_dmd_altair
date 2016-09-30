Script.Load("lua/Class.lua")

local function HasConsumerRequiringPower_Internal( self, onlyBuilt )

    for index, chair in ientitylist( Shared.GetEntitiesWithClassname("CommandStructure") ) do
        if chair:GetLocationId() == self:GetLocationId() 
            and ( not onlyBuilt or chair:GetIsBuilt() ) 
        then
            return true
        end
    end
    
    local consumers = GetEntitiesWithMixin("PowerConsumer")
    --Shared.SortEntitiesByDistance(self:GetOrigin(), consumers)
    for index, consumer in ipairs(consumers) do
        if self:GetCanPower( consumer ) and consumer:GetRequiresPower() 
        and consumer.GetIsBuilt and ( not onlyBuilt or consumer:GetIsBuilt() ) 
        then
            return true
        end
    end
    return false
    
end

Class_ReplaceMethod( "PowerPoint", "HasUnbuiltConsumerRequiringPower",
function(self)

PROFILE("PowerPoint:HasUnbuiltConsumerRequiringPower")
return HasConsumerRequiringPower_Internal( self, false )

end
)