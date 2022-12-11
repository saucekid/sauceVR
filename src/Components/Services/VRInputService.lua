local THUMBSTICK_SAMPLES_TO_RESET = 5
--local Event = game.Players.LocalPlayer:FindFirstChild("EyeEvent") or Instance.new("BindableEvent", game.Players.LocalPlayer); Event.Name = "EyeEvent"

local VRInputService = {}

VRInputService.RecenterOffset = CFrame.new()

VRInputService.VRService = VRService or game:GetService("VRService")
VRInputService.UserInputService = UserInputService or game:GetService("UserInputService")

VRInputService.ThumbstickValues = {
    [Enum.KeyCode.Thumbstick1] = Vector3.new(),
    [Enum.KeyCode.Thumbstick2] = Vector3.new(),
}
VRInputService.PreviousThumbstickValues = {
    [Enum.KeyCode.Thumbstick1] = {},
    [Enum.KeyCode.Thumbstick2] = {},
}
VRInputService.CurrentThumbstickPointers = {
    [Enum.KeyCode.Thumbstick1] = 1,
    [Enum.KeyCode.Thumbstick2] = 1,
}
VRInputService.InputsDown = {
    [Enum.KeyCode.Thumbstick1] = false,
    [Enum.KeyCode.Thumbstick2] = false,
}
VRInputService.UserInputService.InputBegan:Connect(function(Input)
    if VRInputService.InputsDown[Input.KeyCode] ~= nil then
        VRInputService.InputsDown[Input.KeyCode] = true
    end
end)
VRInputService.UserInputService.InputEnded:Connect(function(Input)
    if VRInputService.InputsDown[Input.KeyCode] then
        VRInputService.InputsDown[Input.KeyCode] = false
    end
end)
VRInputService.UserInputService.InputChanged:Connect(function(Input)
    if VRInputService.ThumbstickValues[Input.KeyCode] then
        VRInputService.ThumbstickValues[Input.KeyCode] = Input.Position
    end
end)



function VRInputService:GetVRInputs()
    --Get the head input.
    local VRInputs = {
        [Enum.UserCFrame.Head] = self.VRService:GetUserCFrame(Enum.UserCFrame.Head),
    }

    --Get the hand inputs.
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.LeftHand) then
        VRInputs[Enum.UserCFrame.LeftHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
    else
        VRInputs[Enum.UserCFrame.LeftHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(-1,-2.5,0.5)
    end
    if self.VRService:GetUserCFrameEnabled(Enum.UserCFrame.RightHand) then
        VRInputs[Enum.UserCFrame.RightHand] = self.VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
    else
        VRInputs[Enum.UserCFrame.RightHand] = VRInputs[Enum.UserCFrame.Head] * CFrame.new(1,-2.5,0.5)
    end

    --Determine the height offset.
    local HeightOffset = 0
    if self.ManualNormalHeadLevel then
        --Adjust to normalize the height around the set value.
        HeightOffset = -self.ManualNormalHeadLevel
    else
        --Adjust to normalize the height around the highest value.
        --The head CFrame is moved back 0.5 studs for when the headset suddenly goes up (like putting on and taking off).
        local CurrentVRHeadHeight = (VRInputs[Enum.UserCFrame.Head] * CFrame.new(0,0,0.5)).Y
        if not self.HighestHeadHeight or CurrentVRHeadHeight > self.HighestHeadHeight then
            self.HighestHeadHeight = CurrentVRHeadHeight
        end
        HeightOffset = -self.HighestHeadHeight
    end

    --Normalize the CFrame heights.
    --A list of enums is used instead of VRInputs because modifying a table stops pairs().
    for _,InputEnum in pairs({Enum.UserCFrame.Head,Enum.UserCFrame.LeftHand,Enum.UserCFrame.RightHand}) do
        VRInputs[InputEnum] = CFrame.new(0,HeightOffset,0) * self.RecenterOffset * VRInputs[InputEnum]
    end

    --Return the CFrames.
    return VRInputs
end

function VRInputService:Recenter()
    local HeadCFrame = self.VRService:GetUserCFrame(Enum.UserCFrame.Head)
    self.RecenterOffset = CFrame.Angles(0,-math.atan2(-HeadCFrame.LookVector.X,-HeadCFrame.LookVector.Z),0) * CFrame.new(-HeadCFrame.X,0,-HeadCFrame.Z)
    sauceVREvent:Fire("Recenter")
end


function VRInputService:SetEyeLevel()
    self.ManualNormalHeadLevel = self.VRService:GetUserCFrame(Enum.UserCFrame.Head).Y
    sauceVREvent:Fire("EyeLevel")
end


function VRInputService:GetThumbstickPosition(Thumbsick)
    --Return if the value isn't supported.
    if not self.ThumbstickValues[Thumbsick] then
        return
    end

    --Store the polled value.
    self.PreviousThumbstickValues[Thumbsick][self.CurrentThumbstickPointers[Thumbsick]] = self.ThumbstickValues[Thumbsick]
    self.CurrentThumbstickPointers[Thumbsick] = (self.CurrentThumbstickPointers[Thumbsick] % THUMBSTICK_SAMPLES_TO_RESET) + 1

    --Determine if the polled values are exactly the same.
    --Closeness is not used as the thumbstick being held in place will register as slightly different values.
    --This happens if the trigger is released (such as a touchpad, which may not automatically reset).
    local ValuesSame = true
    local InitialValue = self.PreviousThumbstickValues[Thumbsick][1]
    for i = 2,THUMBSTICK_SAMPLES_TO_RESET do
        if self.PreviousThumbstickValues[Thumbsick][i] ~= InitialValue then
            ValuesSame = false
            break
        end
    end

    --Return either the stored value or the empty vector if the last polled samples are the same.
    if ValuesSame and not self.InputsDown[Thumbsick] then
        return Vector3.new(0,0,0)
    else
        return self.ThumbstickValues[Thumbsick]
    end
end

return VRInputService
