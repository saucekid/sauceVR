local sauceVR = script:FindFirstAncestor("sauceVR")

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local buttonTemplatePart = sauceVR.Assets.Button
local menuTemplate = sauceVR.Assets.Menu
local promptTemplatePart = sauceVR.Assets.Prompt
local tipTemplatePart = sauceVR.Assets.Tooltip

local Terpy = require(sauceVR.Util.Terpy)


local MENU_OPEN_TIME_REQUIREMENT = 1
local MENU_OPEN_TIME = 0.25


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
	local partCache = Instance.new("Model"); partCache.Name = "ButtonGroup";
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

    function Group:SetUpOpening()
        --Create the animation parts.
        local LeftAdornPart = Instance.new("Part")
        LeftAdornPart.Transparency = 1
        LeftAdornPart.Size = Vector3.new()
        LeftAdornPart.Anchored = true
        LeftAdornPart.CanCollide = false
        LeftAdornPart.Parent = Workspace.CurrentCamera
    
        local LeftAdorn = Instance.new("BoxHandleAdornment")
        LeftAdorn.Color3 = Color3.new(1,1,1)
        LeftAdorn.AlwaysOnTop = true
        LeftAdorn.ZIndex = 0
        LeftAdorn.Adornee = LeftAdornPart
        LeftAdorn.Parent = LeftAdornPart
    
        local RightAdornPart = Instance.new("Part")
        RightAdornPart.Transparency = 1
        RightAdornPart.Size = Vector3.new()
        RightAdornPart.Anchored = true
        RightAdornPart.CanCollide = false
        RightAdornPart.Parent = Workspace.CurrentCamera
    
        local RightAdorn = Instance.new("BoxHandleAdornment")
        RightAdorn.Color3 = Color3.new(1,1,1)
        RightAdorn.AlwaysOnTop = true
        RightAdorn.ZIndex = 0
        RightAdorn.Adornee = RightAdornPart
        RightAdorn.Parent = RightAdornPart
    
        local LeftMenuToggleHintAdornPart = Instance.new("Part")
        LeftMenuToggleHintAdornPart.Transparency = 1
        LeftMenuToggleHintAdornPart.Size = Vector3.new(1,1,0)
        LeftMenuToggleHintAdornPart.Anchored = true
        LeftMenuToggleHintAdornPart.CanCollide = false
        LeftMenuToggleHintAdornPart.Parent = Workspace.CurrentCamera
    
        local RightMenuToggleHintAdornPart = Instance.new("Part")
        RightMenuToggleHintAdornPart.Transparency = 1
        RightMenuToggleHintAdornPart.Size = Vector3.new(1,1,0)
        RightMenuToggleHintAdornPart.Anchored = true
        RightMenuToggleHintAdornPart.CanCollide = false
        RightMenuToggleHintAdornPart.Parent = Workspace.CurrentCamera
    
        local LeftMenuToggleHintGuiFront = Instance.new("SurfaceGui")
        LeftMenuToggleHintGuiFront.Face = Enum.NormalId.Front
        LeftMenuToggleHintGuiFront.CanvasSize = Vector2.new(500,500)
        LeftMenuToggleHintGuiFront.LightInfluence = 0
        LeftMenuToggleHintGuiFront.AlwaysOnTop = true
        LeftMenuToggleHintGuiFront.Adornee = LeftMenuToggleHintAdornPart
        LeftMenuToggleHintGuiFront.Parent = LeftMenuToggleHintAdornPart
    
        local LeftMenuToggleHintFrontArrow = Instance.new("ImageLabel")
        LeftMenuToggleHintFrontArrow.ImageTransparency = 1
        LeftMenuToggleHintFrontArrow.BackgroundTransparency = 1
        LeftMenuToggleHintFrontArrow.Rotation = 180
        LeftMenuToggleHintFrontArrow.Size = UDim2.new(1,0,1,0)
        LeftMenuToggleHintFrontArrow.Image = "rbxassetid://11791071909"
        LeftMenuToggleHintFrontArrow.ImageRectSize = Vector2.new(512,512)
        LeftMenuToggleHintFrontArrow.ImageRectOffset = Vector2.new(0,0)
        LeftMenuToggleHintFrontArrow.Parent = LeftMenuToggleHintGuiFront
    
        local LeftMenuToggleHintFrontText = Instance.new("ImageLabel")
        LeftMenuToggleHintFrontText.ImageTransparency = 1
        LeftMenuToggleHintFrontText.BackgroundTransparency = 1
        LeftMenuToggleHintFrontText.Size = UDim2.new(1,0,1,0)
        LeftMenuToggleHintFrontText.ZIndex = 2
        LeftMenuToggleHintFrontText.Image = "rbxassetid://11791071909"
        LeftMenuToggleHintFrontText.ImageRectSize = Vector2.new(512,512)
        LeftMenuToggleHintFrontText.ImageRectOffset = Vector2.new(0,512)
        LeftMenuToggleHintFrontText.Parent = LeftMenuToggleHintGuiFront
    
        local LeftMenuToggleHintGuiBack = Instance.new("SurfaceGui")
        LeftMenuToggleHintGuiBack.Face = Enum.NormalId.Back
        LeftMenuToggleHintGuiBack.CanvasSize = Vector2.new(500,500)
        LeftMenuToggleHintGuiBack.LightInfluence = 0
        LeftMenuToggleHintGuiBack.AlwaysOnTop = true
        LeftMenuToggleHintGuiBack.Adornee = LeftMenuToggleHintAdornPart
        LeftMenuToggleHintGuiBack.Parent = LeftMenuToggleHintAdornPart
    
        local LeftMenuToggleHintBackArrow = Instance.new("ImageLabel")
        LeftMenuToggleHintBackArrow.ImageTransparency = 1
        LeftMenuToggleHintBackArrow.BackgroundTransparency = 1
        LeftMenuToggleHintBackArrow.Size = UDim2.new(1,0,1,0)
        LeftMenuToggleHintBackArrow.Image = "rbxassetid://11791071909"
        LeftMenuToggleHintBackArrow.ImageRectSize = Vector2.new(512,512)
        LeftMenuToggleHintBackArrow.ImageRectOffset = Vector2.new(512,0)
        LeftMenuToggleHintBackArrow.Parent = LeftMenuToggleHintGuiBack
    
        local LeftMenuToggleHintBackText = Instance.new("ImageLabel")
        LeftMenuToggleHintBackText.ImageTransparency = 1
        LeftMenuToggleHintBackText.BackgroundTransparency = 1
        LeftMenuToggleHintBackText.Size = UDim2.new(1,0,1,0)
        LeftMenuToggleHintBackText.ZIndex = 2
        LeftMenuToggleHintBackText.Image = "rbxassetid://11791071909"
        LeftMenuToggleHintBackText.ImageRectSize = Vector2.new(512,512)
        LeftMenuToggleHintBackText.ImageRectOffset = Vector2.new(0,512)
        LeftMenuToggleHintBackText.Parent = LeftMenuToggleHintGuiBack
    
        local RightMenuToggleHintGuiFront = Instance.new("SurfaceGui")
        RightMenuToggleHintGuiFront.Face = Enum.NormalId.Front
        RightMenuToggleHintGuiFront.CanvasSize = Vector2.new(500,500)
        RightMenuToggleHintGuiFront.LightInfluence = 0
        RightMenuToggleHintGuiFront.AlwaysOnTop = true
        RightMenuToggleHintGuiFront.Adornee = RightMenuToggleHintAdornPart
        RightMenuToggleHintGuiFront.Parent = RightMenuToggleHintAdornPart
    
        local RightMenuToggleHintFrontArrow = Instance.new("ImageLabel")
        RightMenuToggleHintFrontArrow.ImageTransparency = 1
        RightMenuToggleHintFrontArrow.BackgroundTransparency = 1
        RightMenuToggleHintFrontArrow.Size = UDim2.new(1,0,1,0)
        RightMenuToggleHintFrontArrow.Image = "rbxassetid://11791071909"
        RightMenuToggleHintFrontArrow.ImageRectSize = Vector2.new(512,512)
        RightMenuToggleHintFrontArrow.ImageRectOffset = Vector2.new(512,0)
        RightMenuToggleHintFrontArrow.Parent = RightMenuToggleHintGuiFront
    
        local RightMenuToggleHintFrontText = Instance.new("ImageLabel")
        RightMenuToggleHintFrontText.ImageTransparency = 1
        RightMenuToggleHintFrontText.BackgroundTransparency = 1
        RightMenuToggleHintFrontText.Size = UDim2.new(1,0,1,0)
        RightMenuToggleHintFrontText.ZIndex = 2
        RightMenuToggleHintFrontText.Image = "rbxassetid://11791071909"
        RightMenuToggleHintFrontText.ImageRectSize = Vector2.new(512,512)
        RightMenuToggleHintFrontText.ImageRectOffset = Vector2.new(0,512)
        RightMenuToggleHintFrontText.Parent = RightMenuToggleHintGuiFront
    
        local RightMenuToggleHintGuiBack = Instance.new("SurfaceGui")
        RightMenuToggleHintGuiBack.Face = Enum.NormalId.Back
        RightMenuToggleHintGuiBack.CanvasSize = Vector2.new(500,500)
        RightMenuToggleHintGuiBack.LightInfluence = 0
        RightMenuToggleHintGuiBack.AlwaysOnTop = true
        RightMenuToggleHintGuiBack.Adornee = RightMenuToggleHintAdornPart
        RightMenuToggleHintGuiBack.Parent = RightMenuToggleHintAdornPart
    
        local RightMenuToggleHintBackArrow = Instance.new("ImageLabel")
        RightMenuToggleHintBackArrow.ImageTransparency = 1
        RightMenuToggleHintBackArrow.BackgroundTransparency = 1
        RightMenuToggleHintBackArrow.Size = UDim2.new(1,0,1,0)
        RightMenuToggleHintBackArrow.Image = "rbxassetid://11791071909"
        RightMenuToggleHintBackArrow.ImageRectSize = Vector2.new(512,512)
        RightMenuToggleHintBackArrow.ImageRectOffset = Vector2.new(0,0)
        RightMenuToggleHintBackArrow.Parent = RightMenuToggleHintGuiBack
    
        local RightMenuToggleHintBackText = Instance.new("ImageLabel")
        RightMenuToggleHintBackText.BackgroundTransparency = 1
        RightMenuToggleHintBackText.Rotation = 180
        RightMenuToggleHintBackText.ImageTransparency = 1
        RightMenuToggleHintBackText.Size = UDim2.new(1,0,1,0)
        RightMenuToggleHintBackText.ZIndex = 2
        RightMenuToggleHintBackText.Image = "rbxassetid://11791071909"
        RightMenuToggleHintBackText.ImageRectSize = Vector2.new(512,512)
        RightMenuToggleHintBackText.ImageRectOffset = Vector2.new(0,512)
        RightMenuToggleHintBackText.Parent = RightMenuToggleHintGuiBack
    
    
        --Start checking for the controllers to be upside down.
        --Done in a coroutine since this function is non-yielding.
        local BothControllersUpStartTime
        local MenuToggleReached = false
        coroutine.wrap(function()
            while true do
    
                --Get the inputs and determine if the hands are both upside down and pointing forward.
                local VRInputs = VRInputService:GetVRInputs()
                local LeftHandCFrameRelative,RightHandCFrameRelative = VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.LeftHand],VRInputs[Enum.UserCFrame.Head]:Inverse() * VRInputs[Enum.UserCFrame.RightHand]
                local LeftHandFacingUp,RightHandFacingUp = LeftHandCFrameRelative.UpVector.Y < 0,RightHandCFrameRelative.UpVector.Y < 0
                local LeftHandFacingForward,RightHandFacingForward = LeftHandCFrameRelative.LookVector.Z < 0,RightHandCFrameRelative.LookVector.Z < 0
                local LeftHandUp,RightHandUp = LeftHandFacingUp and LeftHandFacingForward,RightHandFacingUp and RightHandFacingForward
                local BothHandsUp = LeftHandUp and RightHandUp
                if BothHandsUp then
                    BothControllersUpStartTime = BothControllersUpStartTime or tick()
                else
                    BothControllersUpStartTime = nil
                    MenuToggleReached = false
                end
    
                --Update the adorn part CFrames.
                local CameraCenterCFrame = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
                LeftAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.LeftHand] * CFrame.new(0,-0.25,0.25)
                RightAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand] * CFrame.new(0,-0.25,0.25)
                LeftMenuToggleHintAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.LeftHand]
                RightMenuToggleHintAdornPart.CFrame = CameraCenterCFrame * VRInputs[Enum.UserCFrame.RightHand]
    
                --Update the progress bars.
                if BothControllersUpStartTime and not MenuToggleReached then
                    local DeltaTimePercent = (tick() - BothControllersUpStartTime)/MENU_OPEN_TIME_REQUIREMENT
                    LeftAdorn.Size = Vector3.new(0.1,0,0.25 * DeltaTimePercent)
                    RightAdorn.Size = Vector3.new(0.1,0,0.25 * DeltaTimePercent)
                    LeftAdorn.Visible = true
                    RightAdorn.Visible = true
    
                    --Toggle the menu if the time threshold was reached.
                    if DeltaTimePercent >= 1 then
                        MenuToggleReached = true
                        coroutine.wrap(function()
                            self:SetEnabled(not self.Enabled)
                        end)()
                    end
                else
                    LeftAdorn.Visible = false
                    RightAdorn.Visible = false
                end
    
                --[[
                Updates the given hint parts.
                --]]
                local function UpdateHintParts(Visible,Part,FrontArrow,BackArrow,FrontText,BackText)
                    local TweenData = TweenInfo.new(0.25)
                    TweenService:Create(Part,TweenData,{
                        Size = Visible and Vector3.new(1,1,0) or Vector3.new(1.5,1.5,0)
                    }):Play()
                    TweenService:Create(FrontArrow,TweenData,{
                        ImageTransparency = Visible and 0 or 1
                    }):Play()
                    TweenService:Create(BackArrow,TweenData,{
                        ImageTransparency = Visible and 0 or 1
                    }):Play()
                    TweenService:Create(FrontText,TweenData,{
                        ImageTransparency = Visible and 0 or 1
                    }):Play()
                    TweenService:Create(BackText,TweenData,{
                        ImageTransparency = Visible and 0 or 1
                    }):Play()
                end
    
                --Update the hints.
                local LeftHandHintVisible,RightHandHintVisible = self.Enabled and not LeftHandUp,self.Enabled and not RightHandUp
                if self.LeftHandHintVisible ~= LeftHandHintVisible then
                    self.LeftHandHintVisible = LeftHandHintVisible
                    UpdateHintParts(LeftHandHintVisible,LeftMenuToggleHintAdornPart,LeftMenuToggleHintFrontArrow,LeftMenuToggleHintBackArrow,LeftMenuToggleHintFrontText,LeftMenuToggleHintBackText)
                end
                if self.RightHandHintVisible ~= RightHandHintVisible then
                    self.RightHandHintVisible = RightHandHintVisible
                    UpdateHintParts(RightHandHintVisible,RightMenuToggleHintAdornPart,RightMenuToggleHintFrontArrow,RightMenuToggleHintBackArrow,RightMenuToggleHintFrontText,RightMenuToggleHintBackText)
                end
                local Rotation = (tick() * 10) % 360
                LeftMenuToggleHintFrontArrow.Rotation = Rotation
                LeftMenuToggleHintBackArrow.Rotation = -Rotation
                RightMenuToggleHintFrontArrow.Rotation = -Rotation
                RightMenuToggleHintBackArrow.Rotation = Rotation
    
                --Wait to poll again.
                RunService.RenderStepped:Wait()
            end
        end)()
    end
    
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
    Menu.InTab = false
    Menu.Enabled = false

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
            if menuGui.Enabled then
                menuModel:PivotTo((CFrame.new(Camera.CFrame.Position) * firstCFAngles) * CFrame.new(0,0,9))
            else
                menuModel:PivotTo((CFrame.new(Camera.CFrame.Position) * CFrame.new(0,100,0)))
            end
        end
    end)
    
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
        
        
        function Tab:AddSelectButton(text, def, options, callback, offset, cancel)
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
                buttonFrame.BackgroundTransparency = 1

                local pos = table.find(options, buttonFrame.Text) + 1
                
                if pos > #options then
                    pos = 1
                end

                local cancelled = callback(options[pos])

                if not cancelled then
                    buttonFrame.Text = options[pos]
                end
            end)
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
        if not Menu.InTab then
            mouseEnter = false
            backButton.ImageTransparency = 1 
        end

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

    if #options < 2 then
        promptOptions["2"]:Destroy()
    end

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
            promptPart.CFrame = (CFrame.new(Camera.CFrame.Position) * firstCFAngles)  * CFrame.new(0,0,6)
        end
    end)

    promptPart.Parent = Camera

    repeat task.wait() until buttonClicked
end

function Library:ToolTip(text, duration)
    local tipPart =  tipTemplatePart:Clone()
    local tipGui = tipPart.SurfaceGui
    local tipText = tipGui.Main.Text
    
    tipText.Text = text

    local VRInputs =  VRInputService:GetVRInputs()
    local CameraCenterCFrame = Camera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
    tipPart.CFrame = (CameraCenterCFrame * CFrame.Angles(0,math.rad(180),0)) * CFrame.new(0,0,6)

    task.spawn(function()
        while task.wait() and tipPart do
            local VRInputs =  VRInputService:GetVRInputs()
            local CameraCenterCFrame = Camera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()

            tipPart.CFrame = tipPart.CFrame:lerp((CameraCenterCFrame * CFrame.Angles(0,math.rad(180),0)) * CFrame.new(0,0,6),0.1)
        end
    end)

    task.delay(duration, function()
        local TweenData = TweenInfo.new(0.25)
        TweenService:Create(tipText,TweenData,{
            TextTransparency = 1
        }):Play()
        TweenService:Create(tipGui.Main,TweenData,{
            ImageTransparency = 1
        }):Play()

        task.wait(0.25)
        
        tipPart:Destroy()
    end)

    tipPart.Parent = Camera
end


return Library