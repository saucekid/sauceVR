local USE_HEAD_LOCKED_WORKAROUND = true

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")


-----====================={Default Camera}
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


-----====================={Third Person Camera}
local ThirdPersonCamera = {}

function ThirdPersonCamera:Enable(self)
    self.FetchInitialCFrame = true
end

function ThirdPersonCamera:Disable(self)
    self.FetchInitialCFrame = nil
end

function ThirdPersonCamera:UpdateCamera(self, HeadsetCFrameWorld)
    if self.FetchInitialCFrame then
        self.BaseFaceAngleY = math.atan2(-HeadsetCFrameWorld.LookVector.X,-HeadsetCFrameWorld.LookVector.Z)
        self.BaseCFrame = CFrame.new(HeadsetCFrameWorld.Position) * CFrame.Angles(0,self.BaseFaceAngleY,0)
        self.FetchInitialCFrame = nil
    end
    local Scale = 1
    local Character = Players.LocalPlayer.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local BodyHeightScale = Humanoid:FindFirstChild("BodyHeightScale")
            if BodyHeightScale then
                Scale = BodyHeightScale.Value
            end
        end
    end
    local HeadsetRelative = self.BaseCFrame:Inverse() * HeadsetCFrameWorld
    local TargetCFrame = self.BaseCFrame * CFrame.new(0,0,-THIRD_PERSON_ZOOM * Scale) * CFrame.Angles(0,math.pi,0) * HeadsetRelative
    Workspace.CurrentCamera.CameraType = "Scriptable"
    Workspace.CurrentCamera.HeadLocked = false
    if USE_HEAD_LOCKED_WORKAROUND then
        local HeadCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
        Workspace.CurrentCamera.HeadLocked = true
        Workspace.CurrentCamera.CFrame = TargetCFrame * (CFrame.new(HeadCFrame.Position * (Workspace.CurrentCamera.HeadScale - 1)) * HeadCFrame):Inverse()
    else
        Workspace.CurrentCamera.HeadLocked = false
        Workspace.CurrentCamera.CFrame = TargetCFrame
    end
end

return DefaultCamera, ThirdPersonCamera