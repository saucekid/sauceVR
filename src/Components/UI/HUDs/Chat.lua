--[[
Chat HUD
by Abacaxl
--]]

return function()
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
 
    local VRService = game:GetService("VRService")
    
    local VRReady = UserInputService.VREnabled

    local Players = game:GetService("Players")
     local Client = Players.LocalPlayer
 
    local ChatHUD = game:GetObjects("rbxassetid://4476067885")[1]
     local GlobalFrame = ChatHUD.GlobalFrame
      local Template = GlobalFrame.Template
     local LocalFrame = ChatHUD.LocalFrame
     local Global = ChatHUD.Global
     local Local = ChatHUD.Local
 
    local Camera = workspace.CurrentCamera
 
    Template.Parent = nil
    ChatHUD.Parent = game:GetService("CoreGui")

    local Highlight = Global.Frame.BackgroundColor3
    local Deselected = Local.Frame.BackgroundColor3
 
    local OpenGlobalTab = function()
        Global.Frame.BackgroundColor3 = Highlight
        Local.Frame.BackgroundColor3 = Deselected
 
        Global.Font = Enum.Font.SourceSansBold
        Local.Font = Enum.Font.SourceSans
 
        GlobalFrame.Visible = true
        LocalFrame.Visible = false
    end
 
    local OpenLocalTab = function()
        Global.Frame.BackgroundColor3 = Deselected
        Local.Frame.BackgroundColor3 = Highlight
 
        Global.Font = Enum.Font.SourceSans
        Local.Font = Enum.Font.SourceSansBold
 
        GlobalFrame.Visible = false
        LocalFrame.Visible = true
    end
 
    Global.MouseButton1Down:Connect(OpenGlobalTab)
    Local.MouseButton1Down:Connect(OpenLocalTab)
    Global.MouseButton1Click:Connect(OpenGlobalTab)
    Local.MouseButton1Click:Connect(OpenLocalTab)
 
    OpenLocalTab()
 
    local function GetPlayerDistance(Sender)
        if Sender.Character and Sender.Character:FindFirstChild("Head") then
            return math.floor((Sender.Character.Head.Position - Camera:GetRenderCFrame().p).Magnitude + 0.5)
        end
    end
 
    local function NewGlobal(Message, Sender, Color)
        local Frame = Template:Clone()
 
        Frame.Text = ("[%s]: %s"):format(Sender.Name, Message)
        Frame.User.Text = ("[%s]:"):format(Sender.Name)
        Frame.User.TextColor3 = Color
        Frame.BackgroundColor3 = Color
        Frame.Parent = GlobalFrame
 
        delay(60, function()
            Frame:Destroy()
        end)
    end
 
    local function NewLocal(Message, Sender, Color, Dist)
        local Frame = Template:Clone()
 
        Frame.Text = ("(%s) [%s]: %s"):format(tostring(Dist), Sender.Name, Message)
        Frame.User.Text = ("(%s) [%s]:"):format(tostring(Dist), Sender.Name)
        Frame.User.TextColor3 = Color
        Frame.BackgroundColor3 = Color
        Frame.Parent = LocalFrame
 
        delay(60, function()
            Frame:Destroy()
        end)
    end
 
    local function OnNewChat(Message, Sender, Color)
        if not ChatHUD or not ChatHUD.Parent then return end
 
        NewGlobal(Message, Sender, Color)
 
        local Distance = GetPlayerDistance(Sender)
 
        if Distance and Distance <= 70 then
            NewLocal(Message, Sender, Color, Distance)
        end
    end
 
    local function OnPlayerAdded(Player)
        if not ChatHUD or not ChatHUD.Parent then return end
 
        local Color = BrickColor.Random().Color
 
        Player.Chatted:Connect(function(Message)
            OnNewChat(Message, Player, Color)
        end)
    end
 
    Players.PlayerAdded:Connect(OnPlayerAdded)
 
    for _, Player in pairs(Players:GetPlayers()) do
        OnPlayerAdded(Player)
    end
 
    --
 
    local ChatPart = ChatHUD.Part
 
    ChatHUD.Adornee = ChatPart
 
    if VRReady then
        ChatHUD.Parent = game:GetService("CoreGui")
        ChatHUD.Enabled = true
        ChatHUD.AlwaysOnTop = true
 
        local OnInput = UserInputService.InputBegan:Connect(function(Input, Processed)
            if not Processed then
                if Input.KeyCode == Enum.KeyCode.ButtonL3 then
                    ChatHUD.Enabled = not ChatHUD.Enabled
                end
            end
        end)
 
        local RenderStepped = RunService.RenderStepped:Connect(function()
            local LeftHand = VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
            ChatPart.CFrame = (Camera.CFrame * LeftHand) * CFrame.Angles(math.rad(0),math.rad(0), math.rad(180))
            --[[
            local VRInputs =  VRInputService:GetVRInputs()
            local CameraCenter = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
            ChatPart.CFrame = CameraCenter * VRInputs[Enum.UserCFrame.LeftHand] --* CFrame.Angles(math.rad(-90),math.rad(0), math.rad(180))
            ]]
        end)
 
    end
 
    wait(9e9)
end;