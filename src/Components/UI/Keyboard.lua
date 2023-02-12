local sauceVR = script:FindFirstAncestor("sauceVR")

local Utils = require(sauceVR.Util.Utils)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local HapticService = game:GetService("HapticService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Keyboard = {}
Keyboard.SelectedKey = nil
Keyboard.Active = false
Keyboard.Caps = false


local function playSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	SoundService:PlayLocalSound(sound)
end

local function bump()
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0.4)
    task.wait()
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
end


function Keyboard:Init()
    self.Model = sauceVR.Assets.Keyboard:Clone()
    self.Model.Parent = ReplicatedStorage

    local SelectionBox = Instance.new("Highlight", workspace.Terrain)
    SelectionBox.FillColor = Color3.fromRGB(182, 182, 182)
    local Preview = self.Model.Preview.Display.Input

    local function typeKey(key)
        local display = key:FindFirstChild("Display");

        if self.Active then
            if key.Name:find("Key") then
                if Caps then
                    if display:FindFirstChild("Cap") then
                        Preview.Text = Preview.Text.. display.Cap.Text
                    else
                        Preview.Text = Preview.Text.. display.Key.Text:upper()
                    end
                else
                    Preview.Text = Preview.Text.. display.Key.Text:lower()
                end
            elseif key.Name == "Space" then
                Preview.Text = Preview.Text.. " "
            elseif key.Name == "Enter" then
                if Preview.Text ~= "" then
                    Players:Chat(Preview.Text)
                    ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(Preview.Text,"All")
                    Preview.Text = ""
                end
            elseif key.Name == "Backspace" then
                Preview.Text = Preview.Text:sub(1, #Preview.Text-1)
            elseif key.Name == "Clear" then
                Preview.Text = ""
            elseif key.Name == "Caps" then
                Caps = not Caps
                key.Material = Caps and "Neon" or "SmoothPlastic"
                for i,v in pairs(self.Model:GetChildren()) do
                    if v.Name:find("Key") then
                        v.Display.Key.Text = Caps and v.Display.Key.Text:upper() or v.Display.Key.Text:lower()
                    end
                end
            elseif key.Name == "Exit" then
                self.Active = false
            end
        end
    end

    for _,key in pairs(self.Model:GetChildren()) do
        if key.Name == "Board" then continue end
        local display = key:FindFirstChild("Display");
        if display and display:FindFirstChild("Key") then
            display.Key.TextScaled = true
        end
        key.Touched:Connect(function(part)
            if part:IsDescendantOf(LocalPlayer.Character) and part.Name:find("Fake") then
                typeKey(key)
            end
        end)
    end

    function handleKeyboard()
        local VRInputs =  VRInputService:GetVRInputs()
        local CameraCenterCFrame = Camera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()

        if (CameraCenterCFrame.Position - self.Model.PrimaryPart.Position).Magnitude > 20 then
            self.Active = false
        end

        if self.Active then
            self.Model.Parent = Camera
            self.Model:SetPrimaryPartCFrame(self.Model.PrimaryPart.CFrame:lerp(CFrame.lookAt(self.Model.PrimaryPart.Position, CameraCenterCFrame.Position + Vector3.new(0,2,0)) * CFrame.Angles(0,math.rad(180),0), .01))
        else
            self.Model.Parent = ReplicatedStorage
        end

        local Key = Utils:getPointPart(CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand], 100, "lookVector", {LocalPlayer.Character, CurrentCamera, workspace.Terrain:FindFirstChild("VRCharacter")})
        if Key and Key:IsDescendantOf(self.Model) and Key.Name ~= "Board" and Key.Name ~= "Preview" then
            if Key ~= self.SelectedKey then
                SelectionBox.Adornee = Key
                self.SelectedKey = Key
                playSound("rbxassetid://10066936758")
                bump()
            end
        else
            SelectionBox.Adornee = nil
            self.SelectedKey = nil
        end
    end
    self.Connection = RunService.RenderStepped:Connect(handleKeyboard)

    local cooldown = false
    UserInputService.InputBegan:connect(function(key)
        if key.KeyCode == Enum.KeyCode.ButtonR2 or key.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.SelectedKey and not cooldown then
                cooldown = true
                typeKey(self.SelectedKey)
                task.delay(.1, function() 
                    cooldown  = false
                end)
            end
        end
    end)
end

return Keyboard