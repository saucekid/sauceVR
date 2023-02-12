local sauceVR = script:FindFirstAncestor("sauceVR")
local DefaultCamera = require(sauceVR.Components.Cameras.Default)
local ThirdPersonTrackCamera = require(sauceVR.Components.Cameras.ThirdPerson)
local MirrorCamera = require(sauceVR.Components.Cameras.Mirror)

local CameraService = {}
CameraService.RegisteredCameras = {}

function CameraService:RegisterCamera(Name,Camera)
    self.RegisteredCameras[Name] = Camera
end
CameraService:RegisterCamera("Mirror",MirrorCamera)
CameraService:RegisterCamera("ThirdPersonTrack",ThirdPersonTrackCamera)
CameraService:RegisterCamera("Default",DefaultCamera)

function CameraService:SetActiveCamera(Name)
    if self.ActiveCamera == Name then return end
    self.ActiveCamera = Name
    
    if self.CurrentCamera then
        self.CurrentCamera:Disable()
    end
    
    self.CurrentCamera = self.RegisteredCameras[Name]
    if self.CurrentCamera then
        self.CurrentCamera:Enable()
    elseif Name ~= nil then
        warn("Camera \""..tostring(Name).."\" is not registered.")
    end
end
    
function CameraService:UpdateCamera(HeadsetCFrameWorld)
    if self.CurrentCamera then
        self.CurrentCamera:UpdateCamera(HeadsetCFrameWorld)
    end
end

return CameraService
