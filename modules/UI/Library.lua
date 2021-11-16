local library = {}

function library:CreateWindow()
    local window = {}

    if UIpart then UIpart:Destroy() end
    getgenv().UIpart = Instance.new("Part", workspace.Camera)
    UIpart.Anchored = true
    UIpart.Size = Vector3.new(7.972, 8.029, 0.898)
    UIpart.Transparency = 1
    UIpart.CanCollide = false
    
    local SurfaceGui = Instance.new("SurfaceGui")
    SurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SurfaceGui.LightInfluence = 1.000
    SurfaceGui.Parent = UIpart

    local Tabs = Instance.new("Frame")
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BackgroundTransparency = 1.000
    Tabs.Size = UDim2.new(0, 400, 0, 50)
    Tabs.Parent = SurfaceGui

    local UIGridLayout = Instance.new("UIGridLayout")
    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIGridLayout.CellSize = UDim2.new(0, 50, 0, 50)
    UIGridLayout.Parent = Tabs

    local pages = {}
    function window:CreateTab(image)
        local tab = {}

        local PageTemplate = Instance.new("Frame")
        PageTemplate.Name = "Page"
        PageTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PageTemplate.BorderSizePixel = 0
        PageTemplate.Position = UDim2.new(0, 0, 0.150000006, 0)
        PageTemplate.Size = UDim2.new(0, 400, 0, 400)
        PageTemplate.Parent = SurfaceGui

        local UIGradient = Instance.new("UIGradient")
        UIGradient.Rotation = 90
        UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
        UIGradient.Parent = PageTemplate

        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = PageTemplate

        local TabTemplate = Instance.new("ImageButton")
        TabTemplate.Name = "Tab"
        TabTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabTemplate.BackgroundTransparency = 1.000
        TabTemplate.Size = UDim2.new(0, 100, 0, 100)
        TabTemplate.Image = "rbxassetid://6306230437"
        TabTemplate.Parent = Tabs

        function tab:AddButton(text, funk)
            local Button = Instance.new("Frame")
            Button.Name = "Button"
            Button.Parent = PageTemplate
            Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Button.BackgroundTransparency = 1.000
            Button.Size = UDim2.new(0, 400, 0, 75)

            local Button_2 = Instance.new("TextButton")
            Button_2.Name = "Button"
            Button_2.Parent = Button
            Button_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Button_2.Position = UDim2.new(0, 50, 0.200000003, 0)
            Button_2.Size = UDim2.new(0, 300, 0, 50)
            Button_2.Font = Enum.Font.Code
            Button_2.Text = text
            Button_2.TextColor3 = Color3.fromRGB(0, 0, 0)
            Button_2.TextScaled = true
            Button_2.TextSize = 14.000
            Button_2.TextWrapped = true

            local UICorner = Instance.new("UICorner")
            UICorner.Parent = Button_2

            Button_2.MouseButton1Click:Connect(funk)
        end

        function tab:AddChoice(title, choices, default, funk)
            local pos = table.find(choices, default) or 1
            
            local MultipleChoice = Instance.new("Frame")
            MultipleChoice.Name = "MultipleChoice"
            MultipleChoice.Parent = PageTemplate
            MultipleChoice.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            MultipleChoice.BackgroundTransparency = 1.000
            MultipleChoice.Size = UDim2.new(0, 400, 0, 75)

            local Title = Instance.new("TextLabel")
            Title.Name = "Title"
            Title.Parent = MultipleChoice
            Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Title.BackgroundTransparency = 1.000
            Title.Position = UDim2.new(0, 0, 0.200000003, 0)
            Title.Size = UDim2.new(0, 190, 0, 50)
            Title.Font = Enum.Font.Code
            Title.Text = title
            Title.TextColor3 = Color3.fromRGB(0, 0, 0)
            Title.TextScaled = true
            Title.TextSize = 14.000
            Title.TextWrapped = true
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Left = Instance.new("ImageButton")
            Left.Name = "Left"
            Left.Parent = MultipleChoice
            Left.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Left.BackgroundTransparency = 1.000
            Left.Position = UDim2.new(0, 200, 0.200000003, 0)
            Left.Rotation = -90.000
            Left.Size = UDim2.new(0, 50, 0, 50)
            Left.Image = "rbxassetid://5618148630"

            local Right = Instance.new("ImageButton")
            Right.Name = "Right"
            Right.Parent = MultipleChoice
            Right.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Right.BackgroundTransparency = 1.000
            Right.Position = UDim2.new(0, 330, 0.200000003, 0)
            Right.Rotation = 90.000
            Right.Size = UDim2.new(0, 50, 0, 50)
            Right.Image = "rbxassetid://5618148630"

            local Selected = Instance.new("TextLabel")
            Selected.Name = "Selected"
            Selected.Parent = MultipleChoice
            Selected.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Selected.BackgroundTransparency = 1.000
            Selected.Position = UDim2.new(0, 240, 0.200000003, 0)
            Selected.Size = UDim2.new(0, 100, 0, 50)
            Selected.Font = Enum.Font.Arcade
            Selected.Text = choices[pos]
            Selected.TextColor3 = Color3.fromRGB(255, 255, 255)
            Selected.TextScaled = true
            Selected.TextSize = 14.000
            Selected.TextWrapped = true
            
            Left.MouseButton1Click:Connect(function()
                pos = math.clamp(pos - 1, 1, #choices)
                Selected.Text = choices[pos]
                funk(choices[pos])
            end)
            
            Right.MouseButton1Click:Connect(function()
                pos = math.clamp(pos + 1, 1, #choices)
                Selected.Text = choices[pos]
                funk(choices[pos])
            end)
        end

        return tab
    end
    return window
end
return library

--example
--[[
window = library:CreateWindow()
settingstab = window:CreateTab()
button = settingstab:AddButton("Bruh", function() print("gi") end)
choice = settingstab:AddChoice("choice", {"cool", "hi", "friends"}, "hi", function(thing) print(thing) end)

UIpart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
]]