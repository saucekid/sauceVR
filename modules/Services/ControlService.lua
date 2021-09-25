
function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local BaseController = getModule("Controllers")

local ControlService = {}

function ControlService:RegisterController(Name,Controller)
    self.RegisteredControllers[Name] = Controller
end
    
    
function ControlService:UpdateCharacterReference(character)
    local LastCharacter = self.Character or nil
    self.Character = character
    if not self.Character then
        return
    end
    return LastCharacter ~= self.Character
end

    
function ControlService:SetActiveController(Name)
    if self.ActiveController == Name then return end
    self.ActiveController = Name
    if self.CurrentController then
        self.CurrentController:Disable()
    end
    self.CurrentController = self.RegisteredControllers[Name]
    if self.CurrentController then
        self.CurrentController.Character = self.Character
        self.CurrentController:Enable()
    elseif Name ~= nil then
        warn("Character Model controller \""..tostring(Name).."\" is not registered.")
    end
end

function ControlService:UpdateCharacter()
    if self.CurrentController then
        self.CurrentController:UpdateCharacter()
    end
end

    
ControlService.RegisteredControllers = {}
ControlService:RegisterController("None",BaseController)
    --ControlServiceModule:RegisterController("Teleport",TeleportController.new())
    --ControlServiceModule:RegisterController("SmoothLocomotion",SmoothLocomotionController.new())



return ControlService