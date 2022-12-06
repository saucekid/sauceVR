-- Main
-- saucekid
-- December 4, 2022

if (not isfolder("sauceVR")) then
    makefolder("sauceVR")
end


getgenv().CameraService = require(script.Components.Services.CameraService)
getgenv().ControlService = require(script.Components.Services.ControlService)
getgenv().VRInputService = require(script.Components.Services.VRInputService)
getgenv().DefaultCursorService = require(script.Components.Services.DefaultCursorService)

getgenv().sauceVREvent = Instance.new("BindableEvent")


local Init = require(script.Main)
Init()