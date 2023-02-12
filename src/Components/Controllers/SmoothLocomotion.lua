
local THUMBSTICK_INPUT_START_RADIUS = 0.4
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.2
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(5)
local THUMBSTICK_DEADZONE_RADIUS = 0.1

local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local sauceVR = script:FindFirstAncestor("sauceVR")
local BaseController = require(sauceVR.Components.Controllers.BaseController)

local SmoothLocomotionController = {}
SmoothLocomotionController.super = BaseController

function SmoothLocomotionController:Enable()
    if not self.Connections then self.Connections = {} end
    self.super.Character = self.Character
    self.super:Enable()
    self.JoystickState = { Thumbstick = Enum.KeyCode.Thumbstick2 }
    self.ButtonADown = false
    
    --Connect requesting jumping.
    --ButtonA does not work with IsButtonDown.
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
    self.JoystickState = nil
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
--]]
function SmoothLocomotionController:UpdateCharacter()
    --Update the base character.
    self.super:UpdateCharacter()
    if not self.Character then
        return
    end

    --Determine the direction to move the player.
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
    --Update and fetch the right joystick's state.
    local DirectionState, RadiusState, StateChange = self.super:GetJoystickState(self.JoystickState)
    
    --Snap rotate the character.
    local TurnGyro = self.Character.Parts.HumanoidRootPart:FindFirstChild("TurnGyro")
    local HumanoidRootPart =  self.Character.Parts.HumanoidRootPart
    if StateChange == "Extended" then
        if DirectionState == "Forward" then
            self.Character.Humanoid.Jump = true
        end
        if not self.Character.Humanoid.Sit then
            if DirectionState == "Left" then
                --Turn the player to the left
                TurnGyro.MaxTorque = Vector3.new(0,0,0)

                local goalCF = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame) do
                    local goalTween = TweenService:Create(HumanoidRootPart,TweenInfo.new(0.2),{["CFrame"]=goalCF})
                    goalTween:Play()
                    goalTween.Completed:Wait()
                end
            elseif DirectionState == "Right" then
                --Turn the player to the right.
                TurnGyro.MaxTorque = Vector3.new(0,0,0)

                local goalCF = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame) do
                    local goalTween = TweenService:Create(HumanoidRootPart,TweenInfo.new(0.2),{["CFrame"]=goalCF})
                    goalTween:Play()
                    goalTween.Completed:Wait()
                end
            end

            TurnGyro.MaxTorque = Vector3.new(9e9,2000,9e9)
        else
            TurnGyro.MaxTorque = Vector3.new(0,0,0)
        end
    end

    --Update the vehicle seat.
    self:UpdateVehicleSeat()

    --Jump the player.
    if (not UserInputService:GetFocusedTextBox() and UserInputService:IsKeyDown(Enum.KeyCode.Space)) or self.ButtonADown then
        self.Character.Humanoid.Jump = true
    end
end




return SmoothLocomotionController