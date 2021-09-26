function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local DefaultCamera  = getModule("Cameras/Default")
local ThirdPersonTrackCamera = getModule("Cameras/ThirdPerson")

local CameraService = {}
CameraService.RegisteredCameras = {}

function CameraService:RegisterCamera(Name,Camera)
    self.RegisteredCameras[Name] = Camera
end

CameraService:RegisterCamera("Default",DefaultCamera)
CameraService:RegisterCamera("ThirdPersonTrack",ThirdPersonTrackCamera)

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
