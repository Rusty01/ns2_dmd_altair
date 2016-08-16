// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// lua\WaterTrigger.lua
//
//    Created by: Feha
//
// Trigger object for a water brush. Will notify when another entity enters or leaves a volume.
//
// ========= For more information, ask me =====================

Script.Load("lua/water_WaterMixin.lua")

class 'WaterTrigger' (Entity)

WaterTrigger.kMapName = "watertrigger"

local networkVars =
{
    scale = "vector",
    name = string.format("string (%d)", kMaxEntityStringLength)
}

-- This is likely to change, but since stuff might want to set the scale we provide an easy way to find the water
WaterTrigger.WaterTriggerEntities = {}

function WaterTrigger:OnCreate()
	
    Entity.OnCreate(self)
	
	InitMixin(self, WaterMixin)
	
	-- Used by WaterValve to do mapped connections
	WaterTrigger.WaterTriggerEntities[self] = self
	
    self:SetUpdates(true)

end

function WaterTrigger:OnDestroy()
	
    Entity.OnDestroy(self)
	
	WaterTrigger.WaterTriggerEntities[self] = nil

end

function WaterTrigger:OnInitialized()
	
	self.worldscale = Vector(self.scale.x,self.scale.y,self.scale.z)
	-- multiplied by the extents of the model at scale 1,1,1. I have to find a way to find it in code
	-- self.worldscale = self.dynamicScale-- * self.modelsize
	self.size = self.worldscale:GetLength()
	
end

function WaterTrigger:ScaleOverTime()
	
	local xerror = self.targetscale.x - self.currentscale.x
	local yerror = self.targetscale.y - self.currentscale.y
	local zerror = self.targetscale.z - self.currentscale.z
	if xerror ~= 0 or yerror ~= 0 or zerror ~= 0 then
		local percent = math.min(Shared.GetTime() - self.scalestart, self.timeToScale) / self.timeToScale
		local scalechange = (self.targetscale - self.oldscale) * percent
		xerror = self.targetscale.x - self.oldscale.x
		yerror = self.targetscale.y - self.oldscale.y
		zerror = self.targetscale.z - self.oldscale.z
		local minormax = {[true] = math.min, [false] = math.max}
		minormax = {x=minormax[xerror > 0],y=minormax[yerror > 0],z=minormax[zerror > 0]}
		self.currentscale.x = self.oldscale.x + minormax.x(xerror, scalechange.x)
		self.currentscale.y = self.oldscale.y + minormax.y(yerror, scalechange.y)
		self.currentscale.z = self.oldscale.z + minormax.z(zerror, scalechange.z)
		self:SetScale(self.currentscale, false)
	else
		self.scalingovertime = nil
		
		for k,_ in pairs(self.spoutents) do
			self.spoutents[k]:StopPlaying()
		end
		self.spoutents = {}
		
		return false
	end
	
	return true
	
end


-- set the scale smoothed linearly over time
Shared.RegisterNetworkMessage ( "WaterTriggerScaleSmoothed", { self = "entityid",
	targetscalex = "float", targetscaley = "float", targetscalez = "float",
	oldscalex = "float", oldscaley = "float", oldscalez = "float",
	timetoscale = "float",
	scalestart = "float",
	spoutname = string.format("string (%d)", kMaxEntityStringLength)
} )
function WaterTrigger:SetScaleSmoothed(targetscale, oldscale, timetoscale, scalestart, spoutname, serverOnly)
	self.currentscale = self.currentscale or Vector(1,1,1)
	self.targetscale = targetscale
	self.oldscale = oldscale or self.currentscale
	self.timeToScale = timetoscale or 5
	self.scalestart = scalestart or Shared.GetTime()
	
	
	if Server and serverOnly then
		Server.SendNetworkMessage ( "WaterTriggerScaleSmoothed", {
			self = self:GetId(),
			targetscalex = targetscale.x, targetscaley = targetscale.y,	targetscalez = targetscale.z,
			oldscalex = oldscale.x, oldscaley = oldscale.y, oldscalez = oldscale.z,
			timetoscale = timetoscale,
			scalestart = scalestart,
			spoutname = spoutname or ""
		}, true )
	end
	
	for k,_ in pairs(self.spoutents or {}) do
		self.spoutents[k]:StopPlaying()
	end
	self.spoutents = {}
	
	self.spoutents = {}
	if spoutname and spoutname ~= "" then
		for k,_ in pairs(WaterSpout.Entities) do
			if k.name == spoutname then
				self.spoutents[k] = k
			end
		end
	end
	
	for k,_ in pairs(self.spoutents) do
		self.spoutents[k]:StartPlaying()
	end
	
	if not self.scalingovertime then
		self:AddTimedCallback(self.ScaleOverTime, 0.01)
	end
end
if Client then
	Client.HookNetworkMessage( "WaterTriggerScaleSmoothed",
		function(messageTable)
			local targetscale = Vector(messageTable.targetscalex,messageTable.targetscaley,messageTable.targetscalez)
			local oldscale = Vector(messageTable.oldscalex,messageTable.oldscaley,messageTable.oldscalez)
			local timetoscale = messageTable.timetoscale
			local scalestart = messageTable.scalestart
			local spoutname = messageTable.spoutname
			Shared.GetEntity(messageTable.self):SetScaleSmoothed(targetscale, oldscale, timetoscale, scalestart, spoutname)
		end
	)
end

Shared.RegisterNetworkMessage ( "WaterTriggerScale", {self = "entityid", x = "float", y = "float", z = "float"} )
function WaterTrigger:SetScale(scaleVector, serverOnly)
	self.worldscale.x = self.scale.x * scaleVector.x
	self.worldscale.y = self.scale.y * scaleVector.y
	self.worldscale.z = self.scale.z * scaleVector.z
	self.size = self.worldscale:GetLength()
	
	if Server and serverOnly then
		Server.SendNetworkMessage ( "WaterTriggerScale", {
			self = self:GetId(),
			x = scaleVector.x,
			y = scaleVector.y,
			z = scaleVector.z
		}, true )
	end
end
if Client then
	Client.HookNetworkMessage( "WaterTriggerScale",
		function(messageTable)
			Shared.GetEntity(messageTable.self):SetScale(Vector(messageTable.x,messageTable.y,messageTable.z))
		end
	)
end

function WaterTrigger:MoveOrigin(moveVector)
	local coords = self:GetCoords()
	coords.origin = coords.origin + moveVector
	self:SetCoords(coords)
end


function WaterTrigger:GetIsEntitySubmerged(ent)
	if not ent then return end
	
	local entcoords = ent:GetCoords()
	local pos = ent:GetOrigin()
	local top = (ent.GetEyePos and ent:GetEyePos() + entcoords.yAxis/5) or (pos + entcoords.yAxis * 1.89) -- only fits players atm
	
	local OBB = self:GetCoords()
	OBB.origin = OBB.origin + OBB.yAxis * self.worldscale.y / 2
	local point, submerged = Intersection.LinesegmentOBBIntersection(top, pos, OBB, self.worldscale)
	
	-- if point then
		-- point = OBB:TransformPoint( point )
	-- end
	
	return point, submerged
end


function WaterTrigger:IsPointSubmerged(worldpoint)
	if not worldpoint then return false end
	
	local OBB = self:GetCoords()
	OBB.origin = OBB.origin + OBB.yAxis * self.worldscale.y / 2
	return Intersection.IsPointInsideOBB(worldpoint, OBB, self.worldscale)
end


Shared.LinkClassToMap("WaterTrigger", WaterTrigger.kMapName, networkVars)