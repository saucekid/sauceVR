
local USE_HEAD_LOCKED_WORKAROUND = true
local THIRD_PERSON_ZOOM = 10


local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VRService = game:GetService("VRService")


local ThirdPersonCamera = {}

function ThirdPersonCamera:Enable()
    self.FetchInitialCFrame = true
end

function ThirdPersonCamera:Disable()
    self.FetchInitialCFrame = nil
end

function ThirdPersonCamera:UpdateCamera(HeadsetCFrameWorld)
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

return ThirdPersonCamera