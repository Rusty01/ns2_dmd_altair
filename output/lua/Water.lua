// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// lua\Water.lua
//
//    Created by: Feha
//
// It is supposed to sort of mimic how water brushes in source works
//
// ========= For more information, ask me =====================

Script.Load("lua/Class.lua")

class 'Water' (WaterTrigger)

Water.kMapName = "water"

local networkVars =
{
	model = string.format("string (%d)", kMaxEntityStringLength * 4),
	modelsize = "vector",
    material = string.format("string (%d)", kMaxEntityStringLength * 4),
    material2 = string.format("string (%d)", kMaxEntityStringLength * 4),
    suffocationvolume = "float",
	map_suffocationsound = string.format("string (%d)", kMaxEntityStringLength * 4),
    splashscale = "vector",
	map_splashcinematics = string.format("string (%d)", kMaxEntityStringLength * 4),
    splashvolume = "float",
	map_splashsound = string.format("string (%d)", kMaxEntityStringLength * 4),
	footstepscale = "vector",
	map_footstepcinematics = string.format("string (%d)", kMaxEntityStringLength * 4),
    footstepvolume = "float",
	map_footstepsound = string.format("string (%d)", kMaxEntityStringLength * 4),
    map_underwaterfiltercinematics = string.format("string (%d)", kMaxEntityStringLength * 4),
    underwatervolume = "float",
    map_underwatersound = string.format("string (%d)", kMaxEntityStringLength * 4)
}

Water.kDefaultModelName = "models/water/blank_water.model"
Water.kDefaultPrecacheAssetModel = PrecacheAsset(Water.kDefaultModelName)

function Water:OnInitialized()
	
	WaterTrigger.OnInitialized(self)
	
	self.modelscale = Vector(self.worldscale.x,self.worldscale.y,self.worldscale.z)
	self.worldscale.x = self.worldscale.x * self.modelsize.x
	self.worldscale.y = self.worldscale.y * self.modelsize.y
	self.worldscale.z = self.worldscale.z * self.modelsize.z
	self.size = self.worldscale:GetLength()
	
	if Server then
		if self.map_suffocationsound and self.map_suffocationsound ~= "" then
			PrecacheAsset(self.map_suffocationsound)--default="sound/NS2.fev/alien/gorge/spit_hit_marine")
			self.suffocationsound = self.map_suffocationsound
		end
		if self.map_splashsound and self.map_splashsound ~= "" then
			if self.suffocationsound and self.suffocationsound == self.map_splashsound then
				self.splashsound = self.suffocationsound
			else
				PrecacheAsset(self.map_splashsound)
				self.splashsound = self.map_splashsound
			end
		end
		if self.map_footstepsound and self.map_footstepsound ~= "" then
			if self.splashsound and self.splashsound == self.map_footstepsound then
				self.footstepsound = self.splashsound
			else
				PrecacheAsset(self.map_footstepsound)
				self.footstepsound = self.map_footstepsound
			end
		end
	end
	
	if Client then
		
		local coords = self:GetCoords()
		coords.xAxis = coords.xAxis * self.modelscale.x - coords.xAxis * 0.003 --subtract to avoid textures overlapping
		coords.yAxis = coords.yAxis * self.modelscale.y - coords.yAxis * 0.003
		coords.zAxis = coords.zAxis * self.modelscale.z - coords.zAxis * 0.003
		
		if self.model and self.model ~= "" then
			self.model = PrecacheAsset(self.model)
		else
			self.model = Water.kDefaultPrecacheAssetModel
		end
		
		self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
		if Shared.GetModelIndex(self.model) == 0 then
			self.renderModel:SetModel(self.model)
		else
			self.renderModel:SetModel(Shared.GetModelIndex(self.model))
		end
		-- Shared.Message(tostring(self.renderModel:GetCoords()))
		self.renderModel:SetCoords(coords)
		self.renderModel:SetIsStatic(true)
		self.renderModel:SetIsVisible(true)
		if self.material and self.material ~= "" then
			AddMaterial(self.renderModel, self.material)
		end
		if self.material2 and self.material2 ~= "" then
			AddMaterial(self.renderModel, self.material2)
		end
		
		
		if self.map_splashcinematics and self.map_splashcinematics ~= "" then
			self.splashcinematics = PrecacheAsset(self.map_splashcinematics)
		end
		if self.map_footstepcinematics and self.map_footstepcinematics ~= "" then
			if self.map_splashcinematics and self.map_splashcinematics == self.map_footstepcinematics then
				self.footstepcinematics = self.splashcinematics
			else
				self.footstepcinematics = PrecacheAsset(self.map_footstepcinematics)
			end
		end
		
		if self.map_underwaterfiltercinematics and self.map_underwaterfiltercinematics ~= "" then
			self.underwaterfiltercinematics = PrecacheAsset(self.map_underwaterfiltercinematics)
		end
		
		if self.map_underwatersound and self.map_underwatersound ~= "" then
			PrecacheAsset(self.map_underwatersound)
			self.underwatersound = self.map_underwatersound
		end
	end
	
end


function Water:SetScale(scaleVector, serverOnly)
	
	WaterTrigger.SetScale(self, scaleVector, serverOnly)
	
	self.modelscale = Vector(self.worldscale.x,self.worldscale.y,self.worldscale.z)
	self.worldscale.x = self.worldscale.x * self.modelsize.x
	self.worldscale.y = self.worldscale.y * self.modelsize.y
	self.worldscale.z = self.worldscale.z * self.modelsize.z
	self.size = self.worldscale:GetLength()
	
	if Client then
		local coords = self:GetCoords()
		coords.xAxis = coords.xAxis * self.modelscale.x - coords.xAxis * 0.003 --subtract to avoid textures overlapping
		coords.yAxis = coords.yAxis * self.modelscale.y - coords.yAxis * 0.003
		coords.zAxis = coords.zAxis * self.modelscale.z - coords.zAxis * 0.003
		
		if self.renderModel then
			self.renderModel:SetCoords(coords)
		end
	end
end

function Water:MoveOrigin(moveVector)
	
	WaterTrigger.MoveOrigin(self, moveVector)
	
	if Client then
		local coords = self:GetCoords()
		coords.xAxis = coords.xAxis * self.modelscale.x - coords.xAxis * 0.003 --subtract to avoid textures overlapping
		coords.yAxis = coords.yAxis * self.modelscale.y - coords.yAxis * 0.003
		coords.zAxis = coords.zAxis * self.modelscale.z - coords.zAxis * 0.003
		
		if self.renderModel then
			self.renderModel:SetCoords(coords)
		end
	end
end

Shared.LinkClassToMap("Water", Water.kMapName, networkVars)
