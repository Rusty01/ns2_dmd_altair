// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/WaterValve.lua
//
// The button will emit a specified signal when it is used.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// ======Samusdroid (Orphan Black)'s Jukebox fixer/enchancer 
// ======For more information email me samusdroid@gmail.com or add me on Steam.

Script.Load("lua/PropDynamic.lua")
Script.Load("lua/Mixins/BaseModelMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/Mixins/SignalEmitterMixin.lua")
Script.Load("lua/SoundEffect.lua")
Script.Load("lua/WaterSpout.lua")

class 'WaterValve' (ScriptActor)
WaterValve.kMapName = "water_valve"

local networkVars =
{
	scale = "vector",
	nameOfConnectedSpout = string.format("string (%d)", kMaxEntityStringLength),
	nameOfConnectedWater = string.format("string (%d)", kMaxEntityStringLength),
    waterscale = "vector",
	timeToScale = "float",
    newangles = "vector",
	timeToTurn = "float",
	coolDownTime = "time",
	timeLastUsed = "time",
	defaultWaterOn = "boolean",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

function WaterValve:OnCreate()
	
	ScriptActor.OnCreate(self)
	
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
	InitMixin(self, SignalEmitterMixin)
	
	self.emitChannel = 0
	self.emitMessage = ""
	self.coolDownTime = 0
	self.timeLastUsed = 0
	
end

function WaterValve:SetEmitChannel(setChannel)

	assert(type(setChannel) == "number")
	assert(setChannel >= 0)
	
	self.emitChannel = setChannel
	
end

function WaterValve:SetEmitMessage(setMessage)

	assert(type(setMessage) == "string")
	
	self.emitMessage = setMessage
	
end

--function WaterValve:GetUsablePoints()
--	return { self:GetOrigin() }
--end

function WaterValve:GetCanBeUsed(player, useSuccessTable)
	useSuccessTable.useSuccess = ((Shared.GetTime() - self.timeLastUsed) >= self.coolDownTime)
end
	
if Server then
	
	function WaterValve:OnInitialized()

		ScriptActor.OnInitialized(self)
		
		self.modelName = self.model or "models/props/refinery/refinery_bigpipes_03_str4_valve.model"
		self.propScale = self.scale or Vector(1,1,1)
		self.mappedcoords = self:GetCoords()
		self.mappedangles = self:GetAngles()
		self.turnedangles = Angles(	self.newangles.x*math.pi*2/360,
									self.newangles.y*math.pi*2/360,
									self.newangles.z*math.pi*2/360)
		
		self.scalestart = -self.timeToScale
		self.turnstart = -self.timeToTurn
		
		if self.modelName ~= nil then
		
			Shared.PrecacheModel(self.modelName)
			
			--local graphName = string.gsub(self.modelName, ".model", ".animation_graph")
			--Shared.PrecacheAnimationGraph(graphName)
			
			self:SetModel(self.modelName)--, graphName)
			--self:SetAnimationInput("animation", "")
			
		end
		
		// Don't collide when commanding if not full alpha
		self.commAlpha = GetAndCheckValue(self.commAlpha, 0, 1, "commAlpha", 1, true)
		
		// Test against false so that the default is true
		if self.collidable ~= false then
			self:SetPhysicsType(PhysicsType.None)
		else
			self:SetPhysicsType(PhysicsType.Kinematic)
		
			// Make it not block selection and structure placement (GetCommanderPickTarget)
			if self.commAlpha < 1 then
				self:SetPhysicsGroup(PhysicsGroup.CommanderPropsGroup)
			end
			
		end
	  
		self:SetUpdates(true)
	  
		self:SetIsVisible(true)
		
		self:SetPropagate(Entity.Propagate_Mask)
		self:UpdateRelevancyMask()
		
	end
	
    function WaterValve:UpdateRelevancyMask()
    
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        if self.commAlpha == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        end
        
        self:SetExcludeRelevancyMask( mask )
        self:SetRelevancyDistance( kMaxRelevancyDistance )
        
    end
	
	WaterValve.TurnAnimation = function(self)
		
		self.oldangles = self.oldangles or Angles(0,0,0)
		self.currentangles = self.currentangles or Angles(0,0,0)
		
		local xerror = self.targetangles.pitch - self.currentangles.pitch
		local yerror = self.targetangles.yaw - self.currentangles.yaw
		local zerror = self.targetangles.roll - self.currentangles.roll
		if xerror ~= 0 or yerror ~= 0 or zerror ~= 0 then
			local percent = math.min(Shared.GetTime() - self.turnstart, self.timeToTurn) / self.timeToTurn
			local anglechange = Angles()
			for k,_ in pairs({pitch = 0, yaw = 0, roll = 0}) do
				anglechange[k] = (self.targetangles[k] - self.oldangles[k]) * percent
			end
			xerror = self.targetangles.pitch - self.oldangles.pitch
			yerror = self.targetangles.yaw - self.oldangles.yaw
			zerror = self.targetangles.roll - self.oldangles.roll
			local minormax = {[true] = math.min, [false] = math.max}
			minormax = {x=minormax[xerror > 0],y=minormax[yerror > 0],z=minormax[zerror > 0]}
			self.currentangles.pitch = self.oldangles.pitch + minormax.x(xerror, anglechange.pitch)
			self.currentangles.yaw = self.oldangles.yaw + minormax.y(yerror, anglechange.yaw)
			self.currentangles.roll = self.oldangles.roll + minormax.z(zerror, anglechange.roll)
			self:SetAngles(self.currentangles)
		else
			self.scalingovertime = nil
			
			self:OnTurnAnimationFinished()
			return false
		end
		
		return true
		
	end
	
	function WaterValve:OnTurnAnimationFinished()
	end
	
end

function WaterValve:OnUse(player, elapsedTime, useSuccessTable)
	self.useOn = not self.useOn
	
	if Server then
		if not self.waterents then
			self.waterents = {}
			for k,_ in pairs(WaterTrigger.WaterTriggerEntities) do
				if k.name == self.nameOfConnectedWater then
					self.waterents[k] = k
				end
			end
		end
		
		for k,_ in pairs(self.waterents) do
			if self.useOn == true then
				self.scalestart = Shared.GetTime() - self.timeToScale + math.max(math.min(Shared.GetTime() - self.scalestart, self.timeToScale),0)
				k:SetScaleSmoothed(self.waterscale, Vector(1,1,1), self.timeToScale, self.scalestart, nil, true)
				self.turnstart = Shared.GetTime() - self.timeToTurn + math.max(math.min(Shared.GetTime() - self.turnstart, self.timeToTurn),0)
				self.targetangles = self.turnedangles
				self.oldangles = self.mappedangles
				self:AddTimedCallback(WaterValve.TurnAnimation, 0.01)
			else
				self.scalestart = Shared.GetTime() - self.timeToScale + math.max(math.min(Shared.GetTime() - self.scalestart, self.timeToScale),0)
				k:SetScaleSmoothed(Vector(1,1,1), self.waterscale, self.timeToScale, self.scalestart, self.nameOfConnectedSpout, true)
				self.turnstart = Shared.GetTime() - self.timeToTurn + math.max(math.min(Shared.GetTime() - self.turnstart, self.timeToTurn),0)
				self.targetangles = self.mappedangles
				self.oldangles = self.turnedangles
				self:AddTimedCallback(WaterValve.TurnAnimation, 0.01)
			end
		end
	end
end

function PropDynamic:OnTag(tagName)
    PROFILE("PropDynamic:OnTag")
    self:EmitSignal(self.emitChannel, tagName)
end

Shared.LinkClassToMap("WaterValve", WaterValve.kMapName, networkVars)