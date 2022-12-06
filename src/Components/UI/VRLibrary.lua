local sauceVR = script:FindFirstAncestor("sauceVR")

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local buttonTemplatePart = sauceVR.Assets.Button
local menuTemplate = sauceVR.Assets.Menu
local promptTemplatePart = sauceVR.Assets.Prompt

local Terpy = require(sauceVR.Util.Terpy)


local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function playSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	SoundService:PlayLocalSound(sound)
end

local function removePitch(cf)
	cf = cf - cf.p
	local pitch, yaw, roll = cf:toEulerAnglesYXZ()
	return CFrame.fromEulerAnglesYXZ(0, yaw, roll) + cf.p
end

local function reverseTable(t)
	for i = 1, math.floor(#t/2) do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function shallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

local function bump()
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0.1)
    task.wait()
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
end

local function roundTenth(n)
    return math.floor(n * 10) / 10
end

local Library = {}
local Menus = {}

function Library:CreateButtonGroup()
	local partCache = Instance.new("Folder"); partCache.Name = "ButtonParts";
	local partTerpy = Terpy.new(partCache)
	local parts = {}
	
    local firstCF = Camera.CFrame

	local function addPart(name)
		local Clone = buttonTemplatePart:Clone()
		Clone.Name = name
		Clone.Parent = partCache
		Clone:SetAttribute("Offset", 0)
		table.insert(parts, Clone)
		return Clone
	end
	
	local function getPartPos(part, ang)
		return math.cos(ang) * (#parts)*3, math.sin(ang) * (#parts)*3
	end
	
	
	local Group = {}
	
    Group.Enabled = false
	function Group:SetEnabled(bool)
        Group.Enabled = bool
		if bool then
			firstCF = Camera.CFrame
			
			for _,menu in pairs(Menus) do
				menu:SetEnabled(false)
			end
			
            for _,button in pairs(parts) do
                button.SurfaceGui.Enabled = true
                button:SetAttribute("Offset", 0)
            end
			--partTerpy:TweenTransparency(TweenInfo.new(.1), 0)
			
			task.delay(.1, function()
				partCache.Parent = Camera
			end)
		else
            for _,button in pairs(parts) do
                button.SurfaceGui.Enabled = false
            end
			--partTerpy:TweenTransparency(TweenInfo.new(.1), 1)
			
			task.delay(.1, function()
				partCache.Parent = workspace.Terrain
			end)
		end
	end
	
	
	function Group:AddButton(name, image, callback)
		local part = addPart(name)
		local gui = part.SurfaceGui
		
		gui.Title.Text = name
		gui.ImageButton.Image = image
		
		local mouseEnter = false
		local mouseDB = false
		gui.ImageButton.MouseEnter:Connect(function()
			mouseEnter = true
			
			playSound("rbxassetid://10066936758")
			
            task.spawn(bump)

			local offset = part:GetAttribute("Offset")
			repeat task.wait()
				gui.ImageButton.ImageColor3 = gui.ImageButton.ImageColor3:Lerp(Color3.new(0.6, 0.6, 0.6), 0.1)
				gui.Title.TextColor3 = gui.ImageButton.ImageColor3:Lerp(Color3.new(0.6, 0.6, 0.6), 0.1)
				offset = Lerp(offset, 2, 0.1)
				part:SetAttribute("Offset", offset)
			until offset == 2 or mouseEnter == false
		end)
		
		gui.ImageButton.MouseLeave:Connect(function()
			mouseEnter = false
			
			local offset = part:GetAttribute("Offset")
			repeat task.wait()
				gui.ImageButton.ImageColor3 = gui.ImageButton.ImageColor3:Lerp(Color3.new(1,1,1), 0.1)
				gui.Title.TextColor3 = gui.ImageButton.ImageColor3:Lerp(Color3.new(1,1,1), 0.1)
				offset = Lerp(offset, 0, 0.1)
				part:SetAttribute("Offset", offset)
			until offset == 0 or mouseEnter == true
		end)
		
		gui.ImageButton.MouseButton1Click:Connect(function()
            self:SetEnabled(false)

            mouseEnter = false
            gui.ImageButton.ImageColor3 = Color3.new(1,1,1)
			gui.Title.TextColor3 = Color3.new(1,1,1)
			part:SetAttribute("Offset", 0)

			task.delay(.1, callback)
		end)
	end
	
	task.spawn(function()
		while task.wait() do
			local partsReversed = shallowCopy(parts)
			partsReversed = reverseTable(partsReversed)

            for i,v in pairs(partsReversed) do 
                local x,z = getPartPos(v,i*(2*math.pi/(#parts*4)))	
                v.Size = Vector3.new(v.Size.X,v.Size.Y,0.9+v:GetAttribute("Offset"))
                v.CFrame = CFrame.new(((CFrame.new(Camera.CFrame.p) * removePitch(firstCF)) * CFrame.new(x,1,-z)).Position,Camera.CFrame.p)
            end
		end
	end)
	
	Group:SetEnabled(false)
	
	return Group
end

function Library:CreateMenu(name)
    local Menu = {}
    
    local menuModel = menuTemplate:Clone()

    local menuPart = menuModel.MenuPart
    local menuElements, tabCache, menuGui, elementFrame, backButton = menuPart.Elements, menuPart.TabCache, menuPart.SurfaceGui, menuPart.SurfaceGui.Main.ElementFrame, menuPart.SurfaceGui.Main.BackButton
    local menuTerpy = Terpy.new(menuGui)
    
    local backGroundPart = menuModel.Background
    local backGroundGui = backGroundPart.SurfaceGui

    menuModel.Parent = Camera
    
    local firstCFAngles = (Camera.CFrame - Camera.CFrame.Position)
    task.spawn(function()
        while task.wait() do
            menuModel:PivotTo((CFrame.new(Camera.CFrame.Position) * firstCFAngles) * CFrame.new(0,0,9))
        end
    end)
    
    Menu.InTab = false
    Menu.Enabled = false
    
    function Menu:SetEnabled(bool, keepCFrame)
        local currentTab = elementFrame:FindFirstChild("CurrentTab")
        if currentTab then
            self.InTab = false 
            currentTab.Parent = tabCache
        end

        for _,element in pairs(elementFrame:GetChildren()) do
            element.Visible = true
            element.Position = UDim2.new(0,0,0,0)
        end

        if bool then
            if not keepCFrame then
                firstCFAngles = (Camera.CFrame - Camera.CFrame.Position)  * CFrame.Angles(0,math.rad(180),0)
            end

            for _,element in pairs(elementFrame:GetChildren()) do
                element:TweenPosition(UDim2.new(0,0,element:GetAttribute("Y"),0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
            end
            menuGui.Enabled = true
            backGroundGui.Enabled = true
        else
            menuGui.Enabled = false
            backGroundGui.Enabled = false
        end
    end
    
    function Menu:AddTab(name, image)
        local tabFolder = Instance.new("Folder")
        tabFolder.Name = "CurrentTab"
        
        local tabMain = menuElements.Tab:Clone()
        local buttonFrame, iconFrame = tabMain.ButtonFrame, tabMain.Icon

        tabMain.Parent = elementFrame
        tabMain.Position = UDim2.new(0,0,0,0)
        tabMain:SetAttribute("Y", 0 + ((#elementFrame:GetChildren()-1) * 0.15))

        buttonFrame.Text = name
        iconFrame.Image = image
        
        
        local Tab = {}
        
        function Tab:Show()
            Menu.InTab = true

            for _,element in pairs(elementFrame:GetChildren()) do
                element.Visible = false
            end

            tabFolder.Parent = elementFrame

            for _,element in pairs(tabFolder:GetChildren()) do
                element.Position = UDim2.new(0,0,0,0)
                element:TweenPosition(UDim2.new(0,0,element:GetAttribute("Y"),0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
            end
        end

        function Tab:AddButton(text, callback, offset)
            local offset = offset or 0.15
    
            local buttonMain = menuElements.Button:Clone()
            local buttonFrame = buttonMain.ButtonFrame
    
            buttonMain.Parent = tabFolder
            buttonMain.Position = UDim2.new(0,0,0,0)
            buttonMain:SetAttribute("Y", 0 + ((#tabFolder:GetChildren()-1) * offset))
            
            buttonFrame.Text = text
            
            local mouseEnter = false
            buttonFrame.MouseEnter:Connect(function()
                mouseEnter = true
                
                playSound("rbxassetid://6972108033")
                
                task.spawn(bump)
    
                repeat task.wait()
                    buttonFrame.BackgroundTransparency = Lerp(buttonFrame.BackgroundTransparency, .7, 0.1)
                until buttonFrame.BackgroundTransparency == .5 or mouseEnter == false
            end)
            
            buttonFrame.MouseLeave:Connect(function()
                mouseEnter = false
    
                repeat task.wait()
                    buttonFrame.BackgroundTransparency = Lerp(buttonFrame.BackgroundTransparency, 1, 0.1)
                until buttonFrame.BackgroundTransparency == 1 or mouseEnter == true
            end)
            
            
            buttonFrame.MouseButton1Click:Connect(callback)
        end
        
        
        function Tab:AddSelectButton(text, def, options, callback, offset)
            local offset = offset or 0.15

            if not table.find(options, def) then 
                return warn("Option not found")
            end
            
            local buttonMain = menuElements.ButtonSelect:Clone()
            local buttonFrame = buttonMain.ButtonFrame
            local buttonText = buttonMain.Text
            
            buttonMain.Parent = tabFolder
            buttonMain.Position = UDim2.new(0,0,0,0)
            buttonMain:SetAttribute("Y", 0 + ((#tabFolder:GetChildren() - 1) * offset))
    
            buttonText.Text = text
            buttonFrame.Text = def
            
            local mouseEnter = false
    
            buttonFrame.MouseEnter:Connect(function()
                mouseEnter = true
    
                playSound("rbxassetid://6972108033")
    
                task.spawn(bump)
    
                repeat task.wait()
                    buttonFrame.BackgroundTransparency = Lerp(buttonFrame.BackgroundTransparency, .5, 0.1)
                until buttonFrame.BackgroundTransparency == .5 or mouseEnter == false
            end)
    
            buttonFrame.MouseLeave:Connect(function()
                mouseEnter = false
    
                repeat task.wait()
                    buttonFrame.BackgroundTransparency = Lerp(buttonFrame.BackgroundTransparency, 1, 0.1)
                until buttonFrame.BackgroundTransparency == 1 or mouseEnter == true
            end)
    
            buttonFrame.MouseButton1Click:Connect(function()
                local pos = table.find(options, buttonFrame.Text) + 1
                
                if pos > #options then
                    pos = 1
                end
                
                buttonFrame.Text = options[pos]
                callback(options[pos])
            end)
            callback(def)
        end
        
        
        function Tab:AddSlider(text, def, min, max, interval, callback, offset)
            local offset = offset or 0.15

            local sliderMain = menuElements.Slider:Clone()
            local leftButton, rightButton = sliderMain.Left, sliderMain.Right
            local sliderText, sliderValue = sliderMain.Text, sliderMain.Value
            
            sliderMain.Parent = tabFolder
            sliderMain.Position = UDim2.new(0,0,0,0)
            sliderMain:SetAttribute("Y", 0 + ((#tabFolder:GetChildren() - 1) * offset))
            
            sliderText.Text = text
            sliderValue.Text = tostring(def)
            
            local mouseEnterL, mouseEnterR = false, false
            leftButton.MouseEnter:Connect(function()
                mouseEnterL = true
    
                playSound("rbxassetid://6972108033")
    
                task.spawn(bump)
    
                repeat task.wait()
                    leftButton.BackgroundTransparency = Lerp(leftButton.BackgroundTransparency, .5, 0.1)
                until leftButton.BackgroundTransparency == .5 or mouseEnterL == false
            end)
    
            leftButton.MouseLeave:Connect(function()
                mouseEnterL = false
    
                repeat task.wait()
                    leftButton.BackgroundTransparency = Lerp(leftButton.BackgroundTransparency, 1, 0.1)
                until leftButton.BackgroundTransparency == 1 or mouseEnterL == true
            end)
            
            rightButton.MouseEnter:Connect(function()
                mouseEnterR = true
                
                playSound("rbxassetid://6972108033")
    
                task.spawn(bump)
    
                repeat task.wait()
                    rightButton.BackgroundTransparency = Lerp(rightButton.BackgroundTransparency, .5, 0.1)
                until rightButton.BackgroundTransparency == .5 or mouseEnterR == false
            end)
    
            rightButton.MouseLeave:Connect(function()
                mouseEnterR = false
    
                repeat task.wait()
                    rightButton.BackgroundTransparency = Lerp(rightButton.BackgroundTransparency, 1, 0.1)
                until rightButton.BackgroundTransparency == 1 or mouseEnterR == true
            end)
            
            
            local val = def
            leftButton.MouseButton1Click:Connect(function()
                val = interval < 1 and roundTenth(math.clamp(val - interval, min, max)) or math.clamp(val - interval, min, max)
                sliderValue.Text = tostring(val)
                callback(val)
            end)
            
            rightButton.MouseButton1Click:Connect(function()
                val = interval < 1 and roundTenth(math.clamp(val + interval, min, max)) or math.clamp(val + interval, min, max)
                sliderValue.Text = tostring(val)
                callback(val)
            end)
        end 

        local mouseEnter = false
        buttonFrame.MouseEnter:Connect(function()
            mouseEnter = true

            playSound("rbxassetid://6972108033")

            task.spawn(bump)

            repeat task.wait()
                buttonFrame.UIStroke.Transparency = Lerp(buttonFrame.UIStroke.Transparency, .5, 0.1)
            until buttonFrame.UIStroke.Transparency == .5 or mouseEnter == false
        end)

        buttonFrame.MouseLeave:Connect(function()
            mouseEnter = false

            repeat task.wait()
                buttonFrame.UIStroke.Transparency = Lerp(buttonFrame.UIStroke.Transparency, 1, 0.1)
            until buttonFrame.UIStroke.Transparency == 1 or mouseEnter == true
        end)

        buttonFrame.MouseButton1Click:Connect(Tab.Show)

        return Tab
    end

    
    local mouseEnter = false
    backButton.MouseEnter:Connect(function()
        mouseEnter = true

        task.spawn(bump)

        repeat task.wait()
            backButton.ImageTransparency = Lerp(backButton.ImageTransparency, .7, 0.1)
        until backButton.ImageTransparency == .1 or mouseEnter == false
    end)

    backButton.MouseLeave:Connect(function()
        mouseEnter = false

        repeat task.wait()
            backButton.ImageTransparency = Lerp(backButton.ImageTransparency, 1, 0.1)
        until backButton.ImageTransparency == 1 or mouseEnter == true
    end)

    backButton.MouseButton1Click:Connect(function()
        Menu:SetEnabled(Menu.InTab, true)
    end)
    
    table.insert(Menus, Menu)
    return Menu
end

function Library:CreatePrompt(title, text, options, callback)
    local buttonClicked = false

    local promptPart =  promptTemplatePart:Clone()
    local promptGui = promptPart.SurfaceGui
    local promptTitle, promptText, promptOptions = promptGui.Main.Title, promptGui.Main.Desc, promptGui.Main.OptionsFrame

    promptTitle.Text = title
    promptText.Text = text

    
    for _,text in pairs(options) do
        local optionButton =  promptOptions[_]

        optionButton.Text = text

        local mouseEnter
        optionButton.MouseEnter:Connect(function()
            mouseEnter = true

            playSound("rbxassetid://6972108033")

            task.spawn(bump)

            repeat task.wait()
                optionButton.BackgroundTransparency = Lerp(optionButton.BackgroundTransparency, .5, 0.1)
            until optionButton.BackgroundTransparency == .5 or mouseEnter == false
        end)

        optionButton.MouseLeave:Connect(function()
            mouseEnter = false

            repeat task.wait()
                optionButton.BackgroundTransparency = Lerp(optionButton.BackgroundTransparency, 1, 0.1)
            until optionButton.BackgroundTransparency == 1 or mouseEnter == true
        end)

        optionButton.MouseButton1Click:Connect(function()
            callback(text)
            buttonClicked = true
            promptPart:Destroy()
        end)
    end

    local firstCFAngles = (Camera.CFrame - Camera.CFrame.Position) * CFrame.Angles(0,math.rad(180),0)
    
    task.spawn(function()
        while task.wait() do
            promptPart.CFrame = (CFrame.new(Camera.CFrame.Position) * firstCFAngles)  * CFrame.new(0,0,9)
        end
    end)

    promptPart.Parent = Camera

    repeat task.wait() until buttonClicked
end



return Library