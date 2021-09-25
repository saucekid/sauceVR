function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local DefaultCamera, ThirdPersonTrackCamera = getModule("Cameras")

local CameraService = {}

function CameraService:RegisterCamera(Name,Camera)
    self.RegisteredCameras[Name] = Camera
end
    
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

CameraService.RegisteredCameras = {}
CameraService:RegisterCamera("Default",DefaultCamera.new())
CameraService:RegisterCamera("ThirdPersonTrack",ThirdPersonTrackCamera.new())

return CameraService
