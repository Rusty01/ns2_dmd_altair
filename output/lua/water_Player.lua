// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// NS2 water Mod
//	Made by feha, 20??
//
// ========= For more information, ask me =====================

// water_Player.lua

Script.Load("lua/Class.lua")
Script.Load("lua/water_inWaterMixin.lua")
Script.Load("lua/water_SuffocationMixin.lua")
Script.Load("lua/water_BuoyancyMixin.lua")
Script.Load("lua/water_SwimMixin.lua")

-- TODO
-- IOF compability?
-- Attempt to give mappers more control over materials (scale and such)
-- Weapon effects when hitting water?
-- Make cyst placement in water enable placement way down compared to other cysts
-- Is floating infesation goo possible for infested water? maybe use decals?
-- seaweed structure infestation cinematics from the infestation blobs?
-- check if underwatersound only works for tunnel, if so, fix?

-- Helper functions and such
local nearDeathId = -1

function Player:GetSwimForwardAccel()
	return self.kSwimForwardAccel or (self.kAcceleration or 50)
end

function Player:GetSwimStrafeAccel()
	return self.kSwimStrafeAccel or (self.kAcceleration or 50)
end

function Player:GetSwimUpAccel()
	return self.kSwimUpAccel or (self.kAcceleration or 50)
end


function Player:OnCameraSubmerged(point, waterentity, submerged) -- make suffocation bound to same events as this or stuff may look odd
	if Client and Client.GetLocalPlayer() == self then
		if submerged then
			if not nearDeathId or nearDeathId == -1 then
				nearDeathId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)
			else
				Client.SetDSPFloatParameter(nearDeathId, 0, 2738)
				Client.SetDSPActive(nearDeathId, true)
			end
			
			if not self.waterCinematic then
				self.waterCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)//RenderScene.Zone_ViewModel)
				self.waterCinematic:SetCinematic(waterentity.underwaterfiltercinematics)
				self.waterCinematic:SetIsVisible(true)
				self.waterCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
			end
			
			
			if waterentity.underwatersound then
				Shared.PlaySound(self, waterentity.underwatersound, waterentity.underwatervolume or 1)
			end
		else
			if nearDeathId and nearDeathId ~= -1 then
				Client.SetDSPActive(nearDeathId, false)
			end
			
			if self.waterCinematic then
				Client.DestroyCinematic(self.waterCinematic)
				self.waterCinematic = nil
			end
			
			if waterentity.underwatersound then
				Shared.StopSound(self, waterentity.underwatersound)
			end
		end
	end
end

-- Mixin callbacks

-- InWaterMixin
function Player:OnInsideWater(waterEnt, point, submersionPercentage)
	-- stuff that happens while in water
	
	if self:GetIsAlive() then
		
		if self:GetSubmersionState() > 0 and self:GetVelocity():GetLength() > 3 then
			
			if Client and waterEnt.footstepcinematics and self:GetCanBreath()
				and (not self.watertrodcinematics or self.watertrodcinematics < Shared.GetTime() - 0.25) then
				
				self.watertrodcinematics = Shared.GetTime()
				
				local cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
				cinematic:SetCinematic(waterEnt.footstepcinematics)
				cinematic:SetRepeatStyle(Cinematic.Repeat_None)
				cinematic:SetIsVisible(true)
				local cinematicCoords = self:GetCoords()
				cinematicCoords.origin = point + Vector(math.random()*1 - 0.5, 0, math.random()*1 - 0.5)
				cinematicCoords.xAxis = cinematicCoords.xAxis * waterEnt.footstepscale.x
				cinematicCoords.yAxis = cinematicCoords.yAxis * waterEnt.footstepscale.y
				cinematicCoords.zAxis = cinematicCoords.zAxis * waterEnt.footstepscale.z
				cinematic:SetCoords(cinematicCoords)
			end
		
			if Server and waterEnt.footstepsound
				and ( (self.GetIsOnGround and self:GetIsOnGround()) or self:GetCanBreath() )
				and (not self.watertrodsound or self.watertrodsound < Shared.GetTime() - 0.95) then
				
				self.watertrodsound = Shared.GetTime()
				
				Shared.PlayWorldSound(nil, waterEnt.footstepsound, nil, self:GetOrigin(), waterEnt.footstepvolume or 1)
			end
			
		end
	end
	
end

local function SplashEffects(self, waterentity, point, submersionPercentage)
	if self:GetIsAlive() then
		if Server and waterentity.splashsound then
			Shared.PlayWorldSound(nil, waterentity.splashsound, nil, point, waterentity.splashvolume or 1)
		end
		
		if Client and waterentity.splashcinematics then
			local cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
			cinematic:SetCinematic(waterentity.splashcinematics)
			cinematic:SetRepeatStyle(Cinematic.Repeat_None)
			cinematic:SetIsVisible(true)
			local cinematicCoords = self:GetCoords()
			cinematicCoords.origin = point + Vector(math.random()*1 - 0.5, 0, math.random()*1 - 0.5)
			cinematicCoords.xAxis = cinematicCoords.xAxis * waterentity.splashscale.x
			cinematicCoords.yAxis = cinematicCoords.yAxis * waterentity.splashscale.y
			cinematicCoords.zAxis = cinematicCoords.zAxis * waterentity.splashscale.z
			cinematic:SetCoords(cinematicCoords)
		end
	end
end
Player.OnEnterWater = SplashEffects
Player.OnExitWater = SplashEffects

function Player:OnSubmersionStateChange(waterEnt, newState, oldState, point)
	submerging = oldState < newState
	if (newState >= 4 or oldState >= 4) and not (newState >= 4 and oldState >= 4) then
		self:OnCameraSubmerged(self:GetEyePos(), waterEnt, submerging)
	end
	
	if self:GetIsAlive() and self.GetIsOnSurface then
		if newState >= 3 and oldState < 3 then	
			self.jumping = true
		elseif newState < 3 and oldState >= 3 then
			self.swimming = nil
			if self:GetIsOnSurface() then
				self.jumping = false
			end
		end
	end
end


-- WaterSuffocationMixin
function Player:GetCanBreath()
	return self:GetSubmersionState() < 4
end

function Player:GetInitialSuffocationDelay()
	return 10
end

function Player:GetSuffocationDelay()
	return 1
end

function Player:AdjustSuffocationDamage(damageTable)
	damageTable.damageHealth = damageTable.damageHealth + 5
	damageTable.damageType = kDamageType.Gas
end

function Player:OnSuffocationDamage(waterEnt)
	if Server and not (self.GetDarwinMode and self:GetDarwinMode()) then
		Shared.PlayWorldSound(nil, waterEnt.suffocationsound, nil, self:GetOrigin(), waterEnt.suffocationvolume or 3)
	end
end


-- WaterBuoyancyMixin
function Player:GetWaterFriction()
	return 3
end

function Player:GetBuoyancyGravityScale()
	return self.kBuoyancyGravityScale
end

function Player:AdjustBuoyancyForce(buoyancyTable, input, velocity)
	if self.swimming then
		buoyancyTable.buoyancy = 0
	end
end

-- WaterSwimMixin
function Player:GetIsSwimming()
	return self:GetSubmersionState() >= 3
end

function Player:AdjustSwimVelocity(velocity, input, deltatime)
	
	local angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
	local viewCoords = angles:GetCoords()
	local moveDirection = viewCoords:TransformVector(input.move)
	
	if bit.band(input.commands, Move.Jump) ~= 0 then
		moveDirection = moveDirection + Vector(0,1,0)
	end
	
	local newVelocity = GetNormalizedVector(moveDirection)
	newVelocity.x  = newVelocity.x * self:GetSwimForwardAccel()
	newVelocity.y  = newVelocity.y * self:GetSwimUpAccel()
	newVelocity.z  = newVelocity.z * self:GetSwimForwardAccel()
	
	self.swimming = nil
	if newVelocity:GetLength() > 0 then
		self.swimming = true
		newVelocity = newVelocity - (self:GetVelocity() * 1/4)/deltatime
		
		-- help player out of water over ledges if they push towards it and hold jump
		if self:GetCanBreath() and bit.band(input.commands, Move.Jump) ~= 0
				and newVelocity:GetLengthXZ() > 0 then
			local exitdir = GetNormalizedVectorXZ(newVelocity)
			local extents = self:GetExtents()
			extents.y = extents.y
			local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
			local coords = self:GetCoords()
			local origin = coords.origin
			local start1 = origin + coords.yAxis * extents.y*2
			local start2 = origin + coords.yAxis * extents.y*4
			local traceabove = Shared.TraceCapsule(start1, start2, capsuleRadius, capsuleHeight/2, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
			if traceabove.fraction == 1 then -- avoid issues when player has roof
				local tracelower = Shared.TraceCapsule(start1, start1 + exitdir * extents.z*2, capsuleRadius, capsuleHeight/2, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
				local traceupper = Shared.TraceCapsule(start2, start2 + exitdir * extents.z*2, capsuleRadius, capsuleHeight/2, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
				if tracelower.fraction ~= 1 and traceupper.fraction == 1
					and tracelower.normal:DotProduct(newVelocity) < -0.5 then
					self.exitwaterhelp = Shared.GetTime() + 0.42
				end
			end
		end
	end
	
	local pushVelocity = Vector( self.pushImpulse * ( 1 - Clamp( (Shared.GetTime() - self.pushTime) / Player.kPushDuration, 0, 1) ) )
	newVelocity = newVelocity + pushVelocity
	
	-- There has to be a better way to copy the values from one vector into another...
	velocity.x = newVelocity.x
	velocity.y = newVelocity.y
	velocity.z = newVelocity.z
	
end


function Player:ModifyVelocity(input, velocity, deltatime)
	if self.exitwaterhelp then
		if self.exitwaterhelp < Shared.GetTime() then
			self.exitwaterhelp = nil
		end
		local gravityTable = { gravity = self:GetGravityForce(input) }
		if self.ModifyGravityForce then
			self:ModifyGravityForce(gravityTable)
		end
		velocity.y = velocity.y + (3 - gravityTable.gravity) * deltatime
	end
end

------ Overrides -------
local oldOnCreate
oldOnCreate = Class_ReplaceMethod( "Player", "OnCreate",
	function(self)
		
		oldOnCreate(self)
		
		// Init mixins
		InitMixin(self, InWaterMixin)
		InitMixin(self, SuffocationMixin)
		if HasMixin(self, GroundMoveMixin.type) then
			InitMixin(self, BuoyancyMixin)
			InitMixin(self, SwimMixin)
		end
		
		self.kSwimForwardAccel = 35
		self.kSwimStrafeAccel = 35
		self.kSwimUpAccel = 35
		self.kBuoyancyGravityScale = 0.5
		
	end
)

local oldOnInitialized
oldOnInitialized = Class_ReplaceMethod( "Player", "OnInitialized",
	function(self)
		
		oldOnInitialized(self)
		
		-- local coords = self:GetCoords()
		-- local point = coords:GetInverse():TransformPoint( self:GetEyePos() - coords.yAxis * 0.05 )
		-- self:AddSubmergedLocalPointHook(point, self.OnCameraSubmerged)
		
	end
)

local oldOnDestroy
oldOnDestroy = Class_ReplaceMethod( "Player", "OnDestroy",
	function(self)
		if Client and self.waterCinematic then
			Client.DestroyCinematic(self.waterCinematic)
			self.waterCinematic = nil
		end
		
		oldOnDestroy(self)
	end
)


local oldOnUpdateAnimationInput
oldOnUpdateAnimationInput = Class_ReplaceMethod( "Player", "OnUpdateAnimationInput",
	function(self, modelMixin)
		
		oldOnUpdateAnimationInput(self, modelMixin)
		
		if self:GetIsSwimming() then
			if modelMixin.animationInputValues["move"] ~= "jump" then
				-- swimming uses jump anim
				modelMixin:SetAnimationInput("move", "jump")
			end
		end
		
	end
)


local oldModifyGravityForce
oldModifyGravityForce = Class_ReplaceMethod( "Player", "ModifyGravityForce",
	function(self, gravityTable)
		if self:GetIsInWater() then
			if self:GetCrouching() then
				gravityTable.gravity = gravityTable.gravity * 2
			elseif self.swimming then
				gravityTable.gravity = 0
			end
		end
		
		oldModifyGravityForce(self, gravityTable)
	end
)


if Client then
	local oldOnKillClient
	oldOnKillClient = Class_ReplaceMethod( "Player", "OnKillClient",
		function(self)
			if nearDeathId and nearDeathId ~= -1 then
				Client.SetDSPActive(nearDeathId, false)
			end

			
			if self.waterCinematic then
				Client.DestroyCinematic(self.waterCinematic)
				self.waterCinematic = nil
			end
			
			oldOnKillClient(self, gravityTable)
		end
	)
end
