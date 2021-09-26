local USE_HEAD_LOCKED_WORKAROUND = true

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")


local DefaultCamera = {}

function DefaultCamera:Enable()
    self.TransparencyEvents = {}
    if Players.LocalPlayer.Character then
        local Transparency = options.LocalCharacterTransparency or .5
        table.insert(self.TransparencyEvents,Players.LocalPlayer.Character.DescendantAdded:Connect(function(Part)
            if Part:IsA("BasePart") then
                if Part.Parent:IsA("Accoutrement") then
                    Part.LocalTransparencyModifier = 1
                elseif not Part.Parent:IsA("Tool") then
                    Part.LocalTransparencyModifier = Transparency
                    table.insert(self.TransparencyEvents,Part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                        Part.LocalTransparencyModifier = Transparency
                    end))
                end
            end
        end))
        for _,Part in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                if Part.Parent:IsA("Accoutrement") then
                    Part.LocalTransparencyModifier = 1
                elseif not Part.Parent:IsA("Tool") then
                    Part.LocalTransparencyModifier = Transparency
                    table.insert(self.TransparencyEvents,Part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                        Part.LocalTransparencyModifier = Transparency
                    end))
                end
            end
        end
    end
    table.insert(self.TransparencyEvents,Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
        self:Disable()
        self:Enable()
    end))
end

function DefaultCamera:Disable()
    if self.TransparencyEvents then
        for _,Event in pairs(self.TransparencyEvents) do
            Event:Disconnect()
        end
        self.TransparencyEvents = {}
    end
    if Players.LocalPlayer.Character then
        for _,Part in pairs(Players.LocalPlayer.Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                Part.LocalTransparencyModifier = 0
            end
        end
    end
end

function DefaultCamera:UpdateCamera(HeadsetCFrameWorld)
    Workspace.CurrentCamera.CameraType = "Scriptable"
    if USE_HEAD_LOCKED_WORKAROUND then
        local HeadCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
        Workspace.CurrentCamera.HeadLocked = true
        Workspace.CurrentCamera.CFrame = HeadsetCFrameWorld * (CFrame.new(HeadCFrame.Position * (Workspace.CurrentCamera.HeadScale - 1)) * HeadCFrame):Inverse()
    else
        Workspace.CurrentCamera.HeadLocked = false
        Workspace.CurrentCamera.CFrame = HeadsetCFrameWorld
    end
end


return DefaultCamera