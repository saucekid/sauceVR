--[[
Viewport HUD
by Abacaxl
--]]

return function()
    local ViewportRange = ViewportRange or 32
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local VRService = game:GetService("VRService")
    local Players = game:GetService("Players")
    local Client = Players.LocalPlayer
    local Mouse = Client:GetMouse()
    local Camera = workspace.CurrentCamera
    local CameraPort = Camera.CFrame
    local ViewHUD = script:FindFirstChild("ViewHUD") or game:GetObjects("rbxassetid://4480405425")[1]
    local Viewport = ViewHUD.Viewport
    local Viewcam = Instance.new("Camera")
    local ViewPart = ViewHUD.Part
    ViewHUD.Parent = game:GetService("CoreGui")
    Viewcam.Parent = Viewport
    Viewcam.CameraType = Enum.CameraType.Scriptable
    Viewport.CurrentCamera = Viewcam
    Viewport.BackgroundTransparency = 1
    
    local VRReady = UserInputService.VREnabled
    --[[Code]]--
    
    local function Clone(Character)
        local Arc = Character.Archivable
        local Clone;
        
        Character.Archivable = true
        Clone = Character:Clone()
        Character.Archivable = Arc
        
        return Clone
    end
    
    local function GetPart(Name, Parent, Descendants)
        for i = 1, #Descendants do
            local Part = Descendants[i]
            
            if Part.Name == Name and Part.Parent.Name == Parent then
                return Part
            end
        end
    end
    
    local function OnPlayerAdded(Player)
        if not ViewHUD or not ViewHUD.Parent then return end
        
        local function CharacterAdded(Character)
            if not ViewHUD or not ViewHUD.Parent then return end

            task.wait()
            
            Character:WaitForChild("Head")
            Character:WaitForChild("Humanoid")
            
            local FakeChar = Clone(Character)
            local TrueRoot = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Head")
            local Root = FakeChar:FindFirstChild("HumanoidRootPart") or FakeChar:FindFirstChild("Head")
            local RenderConnection;
            
            local Descendants = FakeChar:GetDescendants()
            local RealDescendants = Character:GetDescendants()
            local Correspondents = {};
            
            FakeChar.Humanoid.DisplayDistanceType = "None"
            
            for i = 1, #Descendants do
                local Part = Descendants[i]
                local Real = Part:IsA("BasePart") and GetPart(Part.Name, Part.Parent.Name, RealDescendants)
                if Part:IsA("BasePart") and Real then
                    Part.Anchored = true
                    Part:BreakJoints()
                    if Part.Parent:IsA("Accessory") or Part.Name:find("Arm") or Part.Name:find("Torso") or Part.Name:find("Leg") or Part.Name:find("Foot") then
                        Part.Transparency = 0
                    end
                    table.insert(Correspondents, {Part, Real})
                end
            end
            
            RenderConnection = RunService.RenderStepped:Connect(function()
                if not Character or not Character.Parent then
                    RenderConnection:Disconnect()
                    FakeChar:Destroy()
                    return
                end
                if (TrueRoot and (TrueRoot.Position - Camera.CFrame.p).Magnitude <= ViewportRange) or Player == Client or not TrueRoot then
                    for i = 1, #Correspondents do
                        local Part, Real = unpack(Correspondents[i])
                        
                        if Part and Real and Part.Parent and Real.Parent then
                            Part.CFrame = Real.CFrame
                        elseif Part.Parent and not Real.Parent then
                            Part:Destroy()
                        end
                    end
                end
            end)
            FakeChar.Parent = Viewcam
        end
        Player.CharacterAdded:Connect(CharacterAdded)
        if Player.Character then
            spawn(function()
                CharacterAdded(Player.Character)
            end)
        end
    end
    
    local PlayerAdded = Players.PlayerAdded:Connect(OnPlayerAdded)
    
    for _, Player in pairs(Players:GetPlayers()) do
        OnPlayerAdded(Player)
    end
    
    ViewPart.Size = Vector3.new()
    
    if VRReady then
        Viewport.Position = UDim2.new(.62, 0, .89, 0)
        Viewport.Size = UDim2.new(.3, 0, .3, 0)
        Viewport.AnchorPoint = Vector2.new(.5, 1)
    else
        Viewport.Size = UDim2.new(0.3, 0, 0.3, 0)
    end
    
    local RenderStepped = RunService.RenderStepped:Connect(function()
        local Render = Camera.CFrame
        local Scale = Camera.ViewportSize
        if VRReady then
            Render = Render * VRService:GetUserCFrame(Enum.UserCFrame.Head)
        end
        CameraPort = CFrame.new(Render.p + Vector3.new(5, 2, 0), Render.p)
        Viewport.Camera.CFrame = CameraPort
        ViewPart.CFrame = Render * CFrame.new(0, 0, -16)
        ViewHUD.Size = UDim2.new(0, Scale.X - 6, 0, Scale.Y - 6)
    end)
        
    --
    
    local CharacterAdded
    CharacterAdded = Client.CharacterAdded:Connect(function()
        RenderStepped:Disconnect()
        CharacterAdded:Disconnect()
        PlayerAdded:Disconnect()
        
        ViewHUD:Destroy()
        ViewHUD = nil
    end)
    
    wait(9e9)
end;
