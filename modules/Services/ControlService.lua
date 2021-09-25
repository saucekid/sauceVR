--[[
TheNexusAvenger

Manages controlling the local characters.
--]]

local NexusVRCharacterModel = require(script.Parent.Parent)
local NexusObject = NexusVRCharacterModel:GetResource("NexusInstance.NexusObject")
local BaseController = NexusVRCharacterModel:GetResource("Character.Controller.BaseController")
local TeleportController = NexusVRCharacterModel:GetResource("Character.Controller.TeleportController")
local SmoothLocomotionController = NexusVRCharacterModel:GetResource("Character.Controller.SmoothLocomotionController")

local ControlServiceModule = {}




function ControlServiceModule.new()
    local ControlService = {}

    function ControlService:RegisterController(Name,Controller)
        self.RegisteredControllers[Name] = Controller
    end
    
    function ControlService:SetActiveController(Name)
        if self.ActiveController == Name then return end
        self.ActiveController = Name
        if self.CurrentController then
            self.CurrentController:Disable()
        end
        self.CurrentController = self.RegisteredControllers[Name]
        if self.CurrentController then
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

    
    ControlServiceModule.RegisteredControllers = {}
    ControlServiceModule:RegisterController("None",BaseController.new())
    --ControlServiceModule:RegisterController("Teleport",TeleportController.new())
    --ControlServiceModule:RegisterController("SmoothLocomotion",SmoothLocomotionController.new())
    return ControlService
end



return ControlServiceModule