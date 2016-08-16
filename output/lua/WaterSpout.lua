// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// lua\WaterSpout.lua
//
//    Created by: Feha
//
// Trigger object for a water brush. Will notify when another entity enters or leaves a volume.
//
// ========= For more information, ask me =====================

class 'WaterSpout' (Entity)

WaterSpout.kMapName = "water_spout"

local networkVars =
{
    name = string.format("string (%d)", kMaxEntityStringLength),
	cinematicsscale = "vector",
	map_cinematics = string.format("string (%d)", kMaxEntityStringLength * 4),
	map_sound = string.format("string (%d)", kMaxEntityStringLength * 4),
	volume = "float"
}

WaterSpout.Entities = {}

function WaterSpout:OnCreate()
	WaterSpout.Entities[self] = self
end

function WaterSpout:OnDestroy()
	WaterSpout.Entities[self] = nil
end

function WaterSpout:OnInitialized()

	Entity.OnInitialized(self)

	if Client then
		if self.map_cinematics and self.map_cinematics ~= "" then
			self.cinematics_name = PrecacheAsset(self.map_cinematics)
        end
	end
	
	if self.map_sound and self.map_sound ~= "" then
		PrecacheAsset(self.map_sound)--"sound/NS2.fev/alien/gorge/spit_hit_marine")
		self.sound = self.map_sound
	end
	
end

function WaterSpout:StartPlaying()
	if Server and self.sound then
		Shared.PlayWorldSound(nil, self.sound, self, Vector(0,0,0), self.volume or 1)
	end
	
	if Client then
		if not self.cinematics and self.cinematics_name and self.cinematics_name ~= "" then
			self.cinematics = Client.CreateCinematic(RenderScene.Zone_Default)
			self.cinematics:SetCinematic(self.cinematics_name)
			self.cinematics:SetRepeatStyle(Cinematic.Repeat_Endless)
			self.cinematics:SetIsVisible(true)
			
			local cinematicCoords = self:GetCoords()
			cinematicCoords.xAxis = cinematicCoords.xAxis * self.cinematicsscale.x
			cinematicCoords.yAxis = cinematicCoords.yAxis * self.cinematicsscale.y
			cinematicCoords.zAxis = cinematicCoords.zAxis * self.cinematicsscale.z
			self.cinematics:SetCoords(cinematicCoords)
		end
	end
end

function WaterSpout:StopPlaying()
	if Server and self.sound then
		Shared.StopSound( self, self.sound ) 
	end
	
	if Client and self.cinematics then
		Client.DestroyCinematic(self.cinematics)
		self.cinematics = nil
	end
end


Shared.LinkClassToMap("WaterSpout", WaterSpout.kMapName, networkVars)