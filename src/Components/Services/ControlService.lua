local sauceVR = script:FindFirstAncestor("sauceVR")
local BaseController = require(sauceVR.Components.Controllers.BaseController)
local SmoothLocomotionController = require(sauceVR.Components.Controllers.SmoothLocomotion)
local TeleportController = require(sauceVR.Components.Controllers.TeleportController)
local GorillaLocomotionController = require(sauceVR.Components.Controllers.GorillaLocomotion)

local ControlService = {}
ControlService.RegisteredControllers = {}

function ControlService:RegisterController(Name,Controller)
    self.RegisteredControllers[Name] = Controller
end

ControlService:RegisterController("TeleportController", TeleportController)
ControlService:RegisterController("SmoothLocomotion", SmoothLocomotionController)
ControlService:RegisterController("GorillaLocomotion", GorillaLocomotionController)
ControlService:RegisterController("None", BaseController)

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

    
--ControlServiceModule:RegisterController("Teleport",TeleportController.new())



return ControlService