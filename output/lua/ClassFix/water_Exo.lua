//________________________________
//
// NS2 water Mod
//	Made by feha, 2012
//
//________________________________

// water_Exo.lua

-- Exo should not swim
function Exo:GetCanSwim()
	return false
end

function Exo:GetIsBuoyant()
	return true
end

function Exo:AdjustBuoyancyForce(buoyancyTable, input, velocity, deltatime)
	local gravityTable = { gravity = self:GetGravityForce(input) }
	if self.ModifyGravityForce then
        self:ModifyGravityForce(gravityTable)
    end
	
	local upvelocity = self:GetSubmersionPercentage() * gravityTable.gravity * -1 * self:GetBuoyancyGravityScale()
	buoyancyTable.buoyancy = upvelocity-- - (velocity.y*1/64)/deltatime
end

-- Exos arent good with water
function Exo:GetCanBreath()
	return self:GetSubmersionState() == 0
end

function Player:GetInitialSuffocationDelay()
	return 1
end

-- Exo takes corrosion damage in water, with the amount depending on how much its submerged
function Exo:AdjustSuffocationDamage(damageTable)
	local damage = kInfestationCorrodeDamagePerSecond * math.max(3 * self:GetSubmersionPercentage(), 1) -- should depth matter for corrosion?
	damage, armorUsed, healthUsed = GetDamageByType(self, nil, nil, damage, kDamageType.Corrode)
	damageTable.damageHealth = damageTable.damageHealth + healthUsed
	damageTable.damageArmor = damageTable.damageArmor + armorUsed
	damageTable.damageType = kDamageType.Corrode
end

------ Overrides -------
local kSmashEggRange = 1.5

local function SmashNearbyEggs(self)

    if not GetIsVortexed(self) then

        local nearbyEggs = GetEntitiesWithinRange("Egg", self:GetOrigin(), kSmashEggRange)
        for _, egg in ipairs(nearbyEggs) do
            egg:Kill(self, self, self:GetOrigin(), Vector(0, -1, 0))
        end
    
    end
    
    // Keep on killing those nasty eggs forever.
    return true
    
end

local kIdle2D = PrecacheAsset("sound/NS2.fev/marine/heavy/idle_2D")
local oldOnCreate
oldOnCreate = Class_ReplaceMethod( "Exo", "OnCreate",
	function(self)
		InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
		InitMixin(self, GroundMoveMixin)
		
		-- Override just to move this line after InitMixin(self, GroundMoveMixin), since my mixins require it.
		Player.OnCreate(self)
		
		InitMixin(self, VortexAbleMixin)
		InitMixin(self, LOSMixin)
		InitMixin(self, CameraHolderMixin, { kFov = kExoFov })
		InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
		InitMixin(self, WeldableMixin)
		InitMixin(self, CombatMixin)
		InitMixin(self, SelectableMixin)
		InitMixin(self, CorrodeMixin)
		InitMixin(self, TunnelUserMixin)
		InitMixin(self, ParasiteMixin)
		
		self:SetIgnoreHealth(true)
		
		self:AddTimedCallback(SmashNearbyEggs, 0.1)
		
		self.deployed = false
		
		self.flashlightOn = false
		self.flashlightLastFrame = false
		self.idleSound2DId = Entity.invalidId
		self.timeThrustersEnded = 0
		self.timeThrustersStarted = 0
		self.inventoryWeight = 0
		self.thrusterMode = kExoThrusterMode.Vertical
		
		if Server then
		
			self.idleSound2D = Server.CreateEntity(SoundEffect.kMapName)
			self.idleSound2D:SetAsset(kIdle2D)
			self.idleSound2D:SetParent(self)
			self.idleSound2D:Start()
			
			// Only sync 2D sound with this Exo player.
			self.idleSound2D:SetPropagate(Entity.Propagate_Callback)
			function self.idleSound2D.OnGetIsRelevant(_, player)
				return player == self
			end
			
			self.idleSound2DId = self.idleSound2D:GetId()
			
		elseif Client then
		
			self.flashlight = Client.CreateRenderLight()
			
			self.flashlight:SetType(RenderLight.Type_Spot)
			self.flashlight:SetColor(Color(.8, .8, 1))
			self.flashlight:SetInnerCone(math.rad(30))
			self.flashlight:SetOuterCone(math.rad(45))
			self.flashlight:SetIntensity(10)
			self.flashlight:SetRadius(25)
			//self.flashlight:SetGoboTexture("models/marine/male/flashlight.dds")
			
			self.flashlight:SetIsVisible(false)
			
		end
		
		self.kBuoyancyGravityScale = 2.75
		
	end
)
