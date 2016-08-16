// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
//   	Water for NS2
//		by Feha
//		
// ========= For more information, ask me =====================

// water_InWaterMixin.lua

Script.Load("lua/FunctionContracts.lua")

InWaterMixin = CreateMixin( InWaterMixin )
InWaterMixin.type = "InWater"

InWaterMixin.expectedMixins =
{
}

InWaterMixin.expectedCallbacks =
{
}
InWaterMixin.optionalCallbacks =
{
	OnEnterWater = "Called when entity enters water",
	OnExitWater = "Called when entity exits water",
	OnInsideWater = "Called while entity is inside water",
	OnEnterWaterEntity = "Called when entity enters any water entity (even if already in another)",
	OnExitWaterEntity = "Called when entity exits any water entity (even if already in another)",
	OnInsideWaterEntity = "Called while entity is inside any water entity (even if already in another)",
	OnSubmersionStateChange = "Called when the submersion state changes"
}

InWaterMixin.expectedConstants =
{
}

InWaterMixin.networkVars =
{
}

--globals
InWaterMixin.InWaterMixinEntities = {}


-- helper variables, for performance or static values
Coords_TransformPoint = Coords.TransformPoint

-- Entities enter a state when the percentage is greater or equal to its table-value
local submersionStatePercentages = {
	[0] = 0,
	[1] = 0.00001,
	[2] = 0.25,
	[3] = 0.5,
	[4] = 0.75,
	[5] = 1
}


function InWaterMixin:__initmixin()
	
	InWaterMixin.InWaterMixinEntities[self] = self
	
	if self.inWater == nil then
		self.inWater = {}
	end
	
	self.submersionpercentagehooks = {}
	self.localpointhooks = {}
	self.localpoints = {}
	
	self:AddTimedCallback(self.OnUpdateWater, 0.01)
	
end

function InWaterMixin:OnDestroy()
    InWaterMixin.InWaterMixinEntities[self] = nil
end

function InWaterMixin:OnUpdateWater()
	self.watertable = self.watertable or {}
	self.submersionpercentage = self.submersionpercentage or 0
	
	local waterentity			= nil
	local submersionpercentage	= 0
	local submersionpoint		= self:GetOrigin()
	for k,_ in pairs(WaterMixin.WaterEntities) do
		local point, submerged = k:GetIsEntitySubmerged(self)
		
		if point and submerged > 0 then
			if submerged > submersionpercentage then
				submersionpercentage = submerged
				submersionpoint = point
			end
			
			-- When inside more than one, treat the smallest as the one you are in (inspired by spacebuild)
			-- Used for sounds and such
			if not waterentity or k.size < waterentity.size then
				waterentity = k
			end
			
			if not self.watertable[k] then
				-- entered waterentity
				if self.OnEnterWaterEntity then
					self:OnEnterWaterEntity(k, point, submerged)
				end
				if k.OnEntityEntered then
					k:OnEntityEntered(self, point, submerged)
				end
			else
				-- inside waterentity
				if self.OnInsideWaterEntity then
					self:OnInsideWaterEntity(k, point, submerged)
				end
				if k.OnEntityInside then
					k:OnEntityInside(self, point, submerged)
				end
			end
			
			self.watertable[k] = k
		else
			if self.watertable[k] then
				-- exit waterentity
				if self.OnExitWaterEntity then
					self:OnExitWaterEntity(k, self:GetOrigin(), submerged)
				end
				if k.OnEntityExit then
					k:OnEntityExit(self, self:GetOrigin(), submerged)
				end
			end
			
			self.watertable[k] = nil
		end
	end
	
	if submersionpercentage > 0 and self.submersionpercentage == 0 then
		-- entered water
		if self.OnEnterWater then
			self:OnEnterWater(waterentity, submersionpoint, submersionpercentage)
		end
	elseif submersionpercentage == 0 and self.submersionpercentage > 0 then
		-- exit water
		if self.OnExitWater then
			self:OnExitWater(self.waterentity, submersionpoint, self.submersionpercentage) -- look over arguments
		end
	elseif submersionpercentage > 0 then
		-- inside water
		if self.OnInsideWater then
			self:OnInsideWater(waterentity, submersionpoint, submersionpercentage)
		end
	end
	
	if submersionpercentage < self.submersionpercentage then
		-- surfacing
	elseif submersionpercentage > self.submersionpercentage then
		-- submerging
	end
	
	if submersionpercentage ~= self.submersionpercentage then
		self:HandleSubmergedLocalPointHooks()
		self:HandleSubmersionPercentageHooks(waterentity or self.waterentity, submersionpercentage)
		self:UpdateSubmersionState(waterentity or self.waterentity, submersionpoint, submersionpercentage)
	end
	
	self.waterentity = waterentity
	self.submersionpercentage = submersionpercentage
	--self.submersionpoint = submersionpoint
	
	return true
end


-- functions referenced should take two entites (submerged ent and water ent) and a bool (true if submerged) 
-- Cant accidently add the same reference to the same percentage twice
function InWaterMixin:AddSubmersionPercentageHook(submersionPercentage, function_ref)
	if not self.submersionpercentagehooks[submersionPercentage] then self.submersionpercentagehooks[submersionPercentage] = {} end
	
	if not table.find(self.submersionpercentagehooks[submersionPercentage], function_ref) then
		table.insert(self.submersionpercentagehooks[submersionPercentage], function_ref)
	end
end

function InWaterMixin:RemoveSubmersionPercentageHook(submersionPercentage, function_ref)
	for k,v in pairs(self.submersionpercentagehooks[submersionPercentage] or {}) do
		if (function_ref == v) then
			table.remove(self.submersionpercentagehooks[submersionPercentage], k)
			break
		end
	end
end

function InWaterMixin:HandleSubmersionPercentageHooks(waterentity, newpercent)
	local oldpercent = self:GetSubmersionPercentage()
	if oldpercent < newpercent then -- submerging
		for k,v in pairs(self.submersionpercentagehooks) do
			if oldpercent <= k and k <= newpercent then
				for _,fun_ref in pairs(self.submersionpercentagehooks[k]) do
					fun_ref(self, waterentity, true)
				end
			end
		end
	elseif oldpercent > newpercent then -- surfacing
		for k,v in pairs(self.submersionpercentagehooks) do
			if newpercent <= k and k <= oldpercent then
				for _,fun_ref in pairs(self.submersionpercentagehooks[k]) do
					fun_ref(self, waterentity, false)
				end
			end
		end
	end
end


-- functions referenced should take points parent entity, point, water entity and a bool (true = submerged)
-- Cant accidently add the same reference to the same percentage twice
function InWaterMixin:AddSubmergedLocalPointHook(point, function_ref)
	self.localpointhooks[point] = self.localpointhooks[point] or {}
	
	if not table.find(self.localpointhooks[point], function_ref) then
		table.insert(self.localpointhooks[point], function_ref)
	end
end

function InWaterMixin:RemoveSubmergedLocalPointHook(point, function_ref)
	for k,v in pairs(self.localpointhooks[point] or {}) do
		if (function_ref == v) then
			table.remove(self.localpointhooks[point], k)
			break
		end
	end
end

-- Currently only calls the hooks when point entere/exit water in general, not for every entity.
function InWaterMixin:HandleSubmergedLocalPointHooks()
	for point,v in pairs(self.localpointhooks) do
		local submerged
		local waterentity
		for k,_ in pairs(WaterMixin.WaterEntities) do
			submerged = k:IsPointSubmerged( Coords_TransformPoint(self:GetCoords(), point) )
			if submerged then
				waterentity = k
				break
			end
		end
		
		if submerged then
			if not self.localpoints[point] then
				self.localpoints[point] = true
				for _,fun_ref in pairs(v) do
					fun_ref(self, point, waterentity, true)
				end
			end
		else
			if self.localpoints[point] then
				self.localpoints[point] = nil
				for _,fun_ref in pairs(v) do
					fun_ref(self, point, self.waterentity, false)
				end
			end
		end
	end
	
end


function InWaterMixin:UpdateSubmersionState(waterEnt, point, percent)
	local oldState = self.submersionState or 0
	local newState = (percent >= submersionStatePercentages[5] and 5)
			or (percent >= submersionStatePercentages[4] and 4)
			or (percent >= submersionStatePercentages[3] and 3)
			or (percent >= submersionStatePercentages[2] and 2)
			or (percent >= submersionStatePercentages[1] and 1)
			or (percent >= submersionStatePercentages[0] and 0)
	if oldState ~= newState then
		self.submersionState = newState
		if self.OnSubmersionStateChange then
			self:OnSubmersionStateChange(waterEnt, newState, oldState, point)
		end
	end
end


-- TODO should look over
function InWaterMixin:GetIsInWater()
	-- If GetCanFloat is not implemented, this line equals true and #self.inWater > 0
	-- If it is implemented, this line equals self:GetCanFloat() and #self.inWater > 0
	return ((self.GetCanFloat and self:GetCanFloat()) or not self.GetCanFloat) and self:GetSubmersionPercentage() > 0--#self.inWater > 0
end
AddFunctionContract(InWaterMixin.GetIsInWater, { Arguments = { "Entity" }, Returns = { "boolean" } })


function InWaterMixin:GetSubmersionPercentage()
	return self.submersionpercentage or 0
end
AddFunctionContract(InWaterMixin.GetSubmersionPercentage, { Arguments = { "Entity" }, Returns = { "float" } })

-- Similar to percentage, but will return an integer representing significant percentages for players
-- 0 = 0% - 1 = in-water - 2 = ankle-deep - 3 = waist-deep - 4 = camera-deep - 5 = 100%
function InWaterMixin:GetSubmersionState()
	return self.submersionState or 0
end
AddFunctionContract(InWaterMixin.GetSubmersionState, { Arguments = { "Entity" }, Returns = { "integer" } })
