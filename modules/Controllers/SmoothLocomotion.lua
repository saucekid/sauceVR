
local THUMBSTICK_INPUT_START_RADIUS = 0.4
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.2
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(22.5)
local THUMBSTICK_DEADZONE_RADIUS = 0.2

local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")

function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local BaseController = getModule("Controllers/BaseController")

local SmoothLocomotionController = {}
SmoothLocomotionController.super = BaseController

function SmoothLocomotionController:Enable()
    if not self.Connections then self.Connections = {} end
    self.super.Character = self.Character
    self.super:Enable()
    VRService:SetTouchpadMode(Enum.VRTouchpad.Right,Enum.VRTouchpadMode.ABXY)
    self.ButtonADown = false
    table.insert(self.Connections,UserInputService.InputBegan:Connect(function(Input,Processsed)
        if Processsed then return end
        if Input.KeyCode == options.JumpButton then
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


    Players.LocalPlayer:Move(Vector3.new(SideDirection,0,-ForwardDirection),true)



    if not self.Character.Humanoid.Sit then
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

return SmoothLocomotionController