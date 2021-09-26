local THUMBSTICK_DEADZONE_RADIUS = 0.2

local THUMBSTICK_INPUT_START_RADIUS = 0.6
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.4
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(22.5)
local THUMBSTICK_DEADZONE_RADIUS = 0.2

local Event = game.Players.LocalPlayer:FindFirstChild("EyeEvent") or Instance.new("BindableEvent", game.Players.LocalPlayer); Event.Name = "EyeEvent"

function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local function GetAngleToGlobalY(CF)
    return math.atan2(-CF.LookVector.X,-CF.LookVector.Z)
end

local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")



local BaseController = {}

function BaseController:Enable()
    if not self.Connections then self.Connections = {} end

    if not self.Character then
        return
    end

    table.insert(self.Connections,Event.Event:Connect(function(type)
        if type == "EyeLevel" then
            if self.LastHeadCFrame.Y > 0 then
                self.LastHeadCFrame = CFrame.new(0,-self.LastHeadCFrame.Y,0) * self.LastHeadCFrame
            end
        end
    end))

    table.insert(self.Connections,self.Character.Humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local SeatPart = self.Character:GetHumanoidSeatPart()
        if SeatPart then
            VRInputService:Recenter()
        end
    end))

    self.Character.Humanoid.AutoRotate = false

    coroutine.wrap(function()
        local ControlModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
        local Character = self.Character
        while self.Character == Character and Character.Humanoid.Health > 0 do
            if ControlModule.activeController and ControlModule.activeController.enabled then
                ControlModule:Disable()
                ContextActionService:BindActivate(Enum.UserInputType.Gamepad1,Enum.KeyCode.ButtonR2)
            end
            wait()
        end
    end)()
end

function BaseController:Disable()
    self.Character = nil
    self.LastHeadCFrame = nil
    for _,Connection in pairs(self.Connections) do
        Connection:Disconnect()
    end
    self.Connections = nil
end


function BaseController:ScaleInput(InputCFrame)
    if not self.Character then
        return InputCFrame
    end
    return CFrame.new(InputCFrame.Position * (self.Character.ScaleValues.BodyHeightScale.Value - 1)) * InputCFrame
end

function BaseController:UpdateCharacter()
    self.Character.TweenComponents = false
    local VRInputs = VRInputService:GetVRInputs()
    local VRHeadCFrame = self:ScaleInput(VRInputs[Enum.UserCFrame.Head])
    local VRLeftHandCFrame,VRRightHandCFrame = self:ScaleInput(VRInputs[Enum.UserCFrame.LeftHand]),self:ScaleInput(VRInputs[Enum.UserCFrame.RightHand])
    local HeadToLeftHandCFrame = VRHeadCFrame:Inverse() * VRLeftHandCFrame
    local HeadToRightHandCFrame = VRHeadCFrame:Inverse() * VRRightHandCFrame

    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart then
        if self.LastHeadCFrame then
            local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
            local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * CFrame.new(0,-self.Character.Motors.Root.Transform.Position.Y,0) * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
            local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
            local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
            local EyesOffset = self.Character.Head:GetEyesOffset()
            local CharacterEyeCFrame = HeadCFrame * EyesOffset

            local InputDelta = self.LastHeadCFrame:Inverse() * VRHeadCFrame
            if VRHeadCFrame.UpVector.Y < 0 then
                InputDelta = CFrame.Angles(0,math.pi,0) * InputDelta
            end
            local HeadRotationXZ = (CFrame.new(VRHeadCFrame.Position) * CFrame.Angles(0,math.atan2(-VRHeadCFrame.LookVector.X,-VRHeadCFrame.LookVector.Z),0)):Inverse() * VRHeadCFrame
            local LastHeadAngleY = GetAngleToGlobalY(self.LastHeadCFrame)
            local HeadAngleY = GetAngleToGlobalY(VRHeadCFrame)
            local HeightOffset = CFrame.new(0,(CFrame.new(0,EyesOffset.Y,0) * (VRHeadCFrame * EyesOffset:Inverse())).Y,0)

            local CurrentCharacterAngleY = GetAngleToGlobalY(CharacterEyeCFrame)
            local RotationY = CFrame.Angles(0,CurrentCharacterAngleY + (HeadAngleY - LastHeadAngleY),0)
            local NewCharacterEyePosition = (HeightOffset *  CFrame.new((RotationY * CFrame.new(InputDelta.X,0,InputDelta.Z)).Position) * CharacterEyeCFrame).Position
            local NewCharacterEyeCFrame = CFrame.new(NewCharacterEyePosition) * RotationY * HeadRotationXZ

            self.Character:UpdateFromInputs(NewCharacterEyeCFrame,NewCharacterEyeCFrame * HeadToLeftHandCFrame,NewCharacterEyeCFrame * HeadToRightHandCFrame)
        end
    else
        self.Character:UpdateFromInputsSeated(VRHeadCFrame,VRHeadCFrame * HeadToLeftHandCFrame,VRHeadCFrame * HeadToRightHandCFrame)
    end
    self.LastHeadCFrame = VRHeadCFrame

    if self.Character.Parts.HumanoidRootPart:IsDescendantOf(Workspace) and self.Character.Humanoid.Health > 0 then
        local HumanoidRootPartCFrame = self.Character.Parts.HumanoidRootPart.CFrame
        local LowerTorsoCFrame = HumanoidRootPartCFrame * self.Character.Attachments.HumanoidRootPart.RootRigAttachment.CFrame * self.Character.Motors.Root.Transform * self.Character.Attachments.LowerTorso.RootRigAttachment.CFrame:Inverse()
        local UpperTorsoCFrame = LowerTorsoCFrame * self.Character.Attachments.LowerTorso.WaistRigAttachment.CFrame * self.Character.Motors.Waist.Transform * self.Character.Attachments.UpperTorso.WaistRigAttachment.CFrame:Inverse()
        local HeadCFrame = UpperTorsoCFrame * self.Character.Attachments.UpperTorso.NeckRigAttachment.CFrame * self.Character.Motors.Neck.Transform * self.Character.Attachments.Head.NeckRigAttachment.CFrame:Inverse()
        CameraService:UpdateCamera(HeadCFrame * self.Character.Head:GetEyesOffset())
    else
        --Update the camera based on the last CFrame if the motors can't update (not in Workspace).
        local CurrentCameraCFrame = Workspace.CurrentCamera.CFrame
        local LastHeadCFrame = self.LastHeadCFrame or CFrame.new()
        local HeadCFrame = self:ScaleInput(VRInputService:GetVRInputs()[Enum.UserCFrame.Head])
        Workspace.CurrentCamera.CFrame = CurrentCameraCFrame * LastHeadCFrame:Inverse() * HeadCFrame
        self.LastHeadCFrame = HeadCFrame
    end
end

--[[
Updates the values of the vehicle seat.
--]]
function BaseController:UpdateVehicleSeat()
    --Get the vehicle seat.
    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart or not SeatPart:IsA("VehicleSeat") then
        return
    end

    --Get the direction.
    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local ForwardDirection = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + ThumbstickPosition.X

    --Update the throttle and steering.
    SeatPart.ThrottleFloat = ForwardDirection
    SeatPart.SteerFloat = SideDirection
end


local SmoothLocomotionController = {}
SmoothLocomotionController.super = BaseController

function SmoothLocomotionController:Enable()
    self.super:Enable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.ABXY)
    self.ButtonADown = false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = true
        end
    end))
    table.insert(self.Connections,UserInputService.InputEnded:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.ButtonA then
            self.ButtonADown = false
        end
    end))
end

function SmoothLocomotionController:Disable()
    self.super:Disable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.VirtualThumbstick)
end

function SmoothLocomotionController:UpdateVehicleSeat()
    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart or not SeatPart:IsA("VehicleSeat") then
        return
    end

    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local ForwardDirection = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + ThumbstickPosition.X

    SeatPart.ThrottleFloat = ForwardDirection
    SeatPart.SteerFloat = SideDirection
end

function SmoothLocomotionController:UpdateCharacter()
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local WDown,SDown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.W),not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.S)
    local DDown,ADown = not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.D),not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.A)
    local ForwardDirection = (WDown and 1 or 0) + (SDown and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (DDown and 1 or 0) + (ADown and -1 or 0) + ThumbstickPosition.X

    --Move the player in that direction.
    Players.LocalPlayer:Move(Vector3.new(SideDirection,0,-ForwardDirection),true)

    --Snap rotate the character.
    if not self.Character.Humanoid.Sit then
        --Fetch the input and calculate the radius and angle of the right thumbstick.
        local InputPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick2)
        local InputRadius = ((InputPosition.X ^ 2) + (InputPosition.Y ^ 2)) ^ 0.5
        local InputAngle = math.atan2(InputPosition.X,InputPosition.Y)

        --Determine the state.
        local DirectionState,RadiusState
        if InputAngle >= math.rad(-135) and InputAngle <= math.rad(-45) then
            DirectionState = "Left"
        elseif InputAngle >= math.rad(-45) and InputAngle <= math.rad(45) then
            DirectionState = "Forward"
        elseif InputAngle >= math.rad(45) and InputAngle <= math.rad(135) then
            DirectionState = "Right"
        end
        if InputRadius >= THUMBSTICK_INPUT_START_RADIUS then
            RadiusState = "Extended"
        elseif InputRadius <= THUMBSTICK_INPUT_RELEASE_RADIUS then
            RadiusState = "Released"
        else
            RadiusState = "InBetween"
        end

        --Update the stored state.
        local StateChange
        if self.RightDirectionState == nil then
            if RadiusState == "Released" then
                self.RightDirectionState = DirectionState
                self.RightRadiusState = RadiusState
            end
        else
            if self.RightDirectionState ~= DirectionState then
                self.RightDirectionState = nil
                self.RightRadiusState = nil
                StateChange = "Cancel"
            elseif (self.RightRadiusState == nil or self.RightRadiusState == "Released") and RadiusState == "Extended" then
                self.RightRadiusState = RadiusState
                StateChange = "Extended"
            elseif (RadiusState == nil or RadiusState == "Released") and self.RightRadiusState == "Extended" then
                self.RightRadiusState = RadiusState
                StateChange = "Released"
            end
        end

        --Snap rotate the character.
        local HumanoidRootPart = self.Character.Parts.HumanoidRootPart
        if StateChange == "Extended" then
            if self.RightDirectionState == "Left" then
                --Turn the player to the left.
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0,THUMBSTICK_MANUAL_ROTATION_ANGLE,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            elseif self.RightDirectionState == "Right" then
                --Turn the player to the right.
                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0,-THUMBSTICK_MANUAL_ROTATION_ANGLE,0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame)
            end
        end
    end

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if (not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end


return BaseController, SmoothLocomotionController