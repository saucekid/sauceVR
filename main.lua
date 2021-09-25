local Players = game:GetService("Players");     
local Lighting = game:GetService("Lighting");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ScriptContext = game:GetService("ScriptContext");
local VRService = game:GetService("VRService");
local VirtualUser = game:GetService("VirtualUser");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local HapticService = game:GetService("HapticService");
local UserInputService = game:GetService("UserInputService");
local CurrentCamera = workspace.CurrentCamera;
local LocalPlayer = game.Players.LocalPlayer;

local Event = setmetatable({}, {
    __call = function(self, ...)
        local args = {...}
        if args[1] == "Clear" then
            for _,con in pairs(self) do
                con:Disconnect()
            end
            return
        end
        table.insert(self, args[1])
    end
})

function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))
    return module
end

local Utils = getModule("Utils")
local DefaultCamera, ThirdPersonCamera = getModule("Camera")

function StartVR()
    local Character, Humanoid, RigType do
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        Humanoid = Utils.WaitForChildOfClass(Character, "Humanoid")
        RigType = Humanoid.RigType.Name
    end

    local FootPlanting = getModule(RigType.. "/FootPlanting")
    if RigType == "R15" then
    
    end
end
