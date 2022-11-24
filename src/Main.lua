local sauceVR = script:FindFirstAncestor("sauceVR")


if not options then
    getgenv().options = {
        --Head Movement(Permanent Death)
        HeadMovement = true,
        
        --Bodyslots or Default (Bodyslots is buggy and)
        Inventory = "Bodyslots" ,
        
        --None, SmoothLocomotion, or teleport (These can be changed in settings)
        DefaultMovementMethod = "None",
        
        --None, SmoothLocomotion, or teleport (These can be changed in settings)
        DefaultCameraOption = "Default",
        
    -- < [Advanced Options]
        --Character Transparency in First Person
        LocalCharacterTransparency = 0.5,
    
        --Maximum angle the neck can turn before the torso turns.
        MaxNeckRotation = math.rad(45),
        MaxNeckSeatedRotation = math.rad(60),
        
        --Maximum angle the neck can tilt before the torso tilts.
        MaxNeckTilt = math.rad(60),
        
        --Maximum angle the center of the torso can bend.
        MaxTorsoBend = math.rad(10),
        
        --Inventory Slot Positions (Relative to HumanoidRootPart)
        InventorySlots = {
            [1] = CFrame.new(-1,-.25,0) * CFrame.Angles(0,math.rad(0),0),
            [2] = CFrame.new(1,-.25,0) * CFrame.Angles(0,math.rad(90),0),
            [3] = CFrame.new(0,0,.5) * CFrame.Angles(0,math.rad(90),0),
        },
            
        --Velocity of part (more = more jitter, but more stable)
        NetlessVelocity = Vector3.new(0,-45,0)
    }
end

-- > [Vars]
local Players = game:GetService("Players");     
local Lighting = game:GetService("Lighting");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ScriptContext = game:GetService("ScriptContext");
local VRService = game:GetService("VRService");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local HapticService = game:GetService("HapticService");
local UserInputService = game:GetService("UserInputService");
local ContextActionService = game:GetService("ContextActionService");
local StarterGui = game:GetService("StarterGui");

local CurrentCamera = workspace.CurrentCamera;
local LocalPlayer = game.Players.LocalPlayer;

local VRReady = UserInputService.VREnabled;

getgenv().BindableEvent = Instance.new("BindableEvent");

-- [Disable Default VR Controls]
--StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
ContextActionService:BindActionAtPriority("DisableInventoryKeys", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2)

StarterGui:SetCore("VRLaserPointerMode",0)
StarterGui:SetCore("VREnableControllerModels",false)

-- [Bubble Chat]
if not game.Chat.BubbleChatEnabled then
    Players.PlayerAdded:connect(function(User)
        User.Chatted:connect(function(Chat)
            game:GetService("Chat"):Chat(User.Character.Head,Chat,Enum.ChatColor.White)
        end)
    end)
    for i,v in pairs(Players:GetPlayers()) do
        v.Chatted:connect(function(Chat)
            game:GetService("Chat"):Chat(v.Character.Head,Chat,Enum.ChatColor.White)
        end)
    end
end

-- [Bypass BodyMover Check]
for i, connection in pairs(getconnections(game.ChildAdded)) do
   connection:Disable()
end

for i, connection in pairs(getconnections(game.ItemChanged)) do
    connection:Disable()
end


local Blacklisted = {
    "BodyForce",
    "BodyPosition",
    "BodyVelocity",
    "BodyThrust",
    "BodyGyro",
    "BodyAngularVelocity",
    "RocketPropulsion",
    "BodyMover"
}

local OrgFunc
OrgFunc = hookfunction(game.IsA, newcclosure(function(Obj, Type)
    if table.find(Blacklisted, Type) then
        return false
    else
        return OrgFunc(Obj, Type)
    end
end))

local OldIndex
OldIndex = hookmetamethod(game, "__index", function(Self, i)
    if not checkcaller() and i == "ClassName" then
        if OrgFunc(Self, "BodyMover") then
            return "Instance"
        elseif tostring(i) == 'BodyVelocity' then
            return 'BodyVelocity'
        end
    end
    return OldIndex(Self, i)
end)

-- [Rejoin When Death]
local Event = require(sauceVR.Util.Event)
local Utils = require(sauceVR.Util.Utils)
local Netless = require(sauceVR.Util.Netless)

local PhysicsHands = require(sauceVR.Components.Character.PhysicsHands)

-- [Services]
getgenv().CameraService = require(sauceVR.Components.Services.CameraService);
getgenv().ControlService = require(sauceVR.Components.Services.ControlService);
getgenv().VRInputService = require(sauceVR.Components.Services.VRInputService);

-- > [Other Functions]
local last = 10
local oldpos = CFrame.new(0,0,0)
local function cframeAlign(a, b, pos)
    local Motor = Utils:GetMotorForLimb(a); if Motor then Motor:Destroy() end
    local function doAlign()
        pcall(function()
            if b:IsA("Attachment") then
                a.CFrame = pos and b.WorldCFrame * pos or b.WorldCFrame
            else
                --[[
                if tick() - last > 9.9 then
                    last = tick()
                    oldpos = CFrame.new(0,200,0)
                elseif tick() - last > 0.025 then
                    oldpos = CFrame.new(0,0,0)
                end
                ]]
                a.CFrame = pos and b.CFrame * pos or b.CFrame * oldpos
            end
        end)
    end
    Event(RunService.Heartbeat:Connect(doAlign))
end

local function Netlesse(part)
    if not part:IsA("BasePart") then return end
    part.Velocity = options.NetlessVelocity
end

-- [Script]
function StartVR()
    local Character, Humanoid, RigType, VRCharacter do
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        Humanoid = Utils.WaitForChildOfClass(Character, "Humanoid")
        RigType = Humanoid.RigType.Name
        Character.Animate:Destroy()

        for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then 
                task.spawn(function() 
                    tool.Parent = Character 
                    task.wait(.1) 
                    tool.Parent = LocalPlayer.Backpack 
                end) 
            end
        end

        Utils:permaDeath(Character)

        for i, v in pairs(Humanoid:GetPlayingAnimationTracks()) do
            v:Stop()
        end

        if RigType == "R15" then
            VRCharacter = Utils:VRCharacter(Character, 1)
        else
            VRCharacter = game:GetObjects("rbxassetid://7307187904")[1]
            for i,v in pairs(VRCharacter:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Decal") then
                    v.Transparency = 1
                end
            end
            VRCharacter.Parent = workspace.Terrain
            VRCharacter:SetPrimaryPartCFrame(Humanoid.RootPart.CFrame)
        end
        
        
        cframeAlign(VRCharacter.Humanoid.RootPart, Humanoid.RootPart)
        
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Parent = VRCharacter.Humanoid.RootPart

        local bg = Instance.new("BodyGyro", Humanoid.RootPart)
        bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.P = 9e9
        
        Character.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(50, 100, 0, 100,100)
        VRCharacter.Humanoid.AutoRotate = false
        VRCharacter.Humanoid.PlatformStand = true
        Humanoid.RootPart.Anchored = true
    end
    

    --[Hand Collision]
    local VirtualRightArm, VirtualLeftArm, RHA, LHA, RgrabWeld, LgrabWeld, RgrabAtt, LgrabAtt do
        VirtualLeftArm, lAO, lAO, lAtt, LHA, lGrabWeld, lGrabAtt = PhysicsHands:createHand(Character, "Fake Left", VRCharacter["LeftHand"].CFrame, VRCharacter["LeftHand"].Size)
        VirtualRightArm, rAO, rAO, rAtt, RHA, rGrabWeld, rGrabAtt = PhysicsHands:createHand(Character, "Fake Right", VRCharacter["RightHand"].CFrame, VRCharacter["RightHand"].Size)
        
        Event(VirtualRightArm.Touched:Connect(function(part)
            if VirtualRightArm:CanCollideWith(part) and not part:IsDescendantOf(Character) and not part:IsDescendantOf(VRCharacter) then
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, (VirtualRightArm.Velocity - part.Velocity).Magnitude / 10)
    		    task.wait()
    		    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
            end
        end))
        
        Event(VirtualLeftArm.Touched:Connect(function(part)
            if VirtualLeftArm:CanCollideWith(part) and not part:IsDescendantOf(Character) and not part:IsDescendantOf(VRCharacter) then
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, (VirtualLeftArm.Velocity - part.Velocity).Magnitude / 10)
    		    task.wait()
    		    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
            end
        end))
    end
    
    --[Updating VR Character]
    local VirtualCharacter do
        VirtualCharacter = require(sauceVR.Components.Character.Character).new(VRCharacter)
        VirtualCharacter.Humanoid = Humanoid
        VirtualCharacter.Parts.HumanoidRootPart = Humanoid.RootPart

        ControlService:UpdateCharacterReference(VirtualCharacter)
        ControlService:SetActiveController(options.DefaultMovementMethod)
        CameraService:SetActiveCamera(VRReady and options.DefaultCameraOption)
        
        local MainMenu = require(sauceVR.Components.UI.MainMenu)
        MainMenu:SetUpOpening()
        RunService:BindToRenderStep("sauceVRCharacterModelUpdate",Enum.RenderPriority.Camera.Value - 1,function()
            ControlService:UpdateCharacter()
            RHA.WorldCFrame = VRCharacter["RightHand"].CFrame 
            LHA.WorldCFrame = VRCharacter["LeftHand"].CFrame
        end)
    end

    --[Replicating]
    local DisabledParts = {}
    DisabledParts["HumanoidRootPart"] = true
    DisabledParts["Fake Right"] = true
    DisabledParts["Fake Left"] = true
    --DisabledParts["Head"] = options.HeadMovement and false or true

    function VRCollision(part)
        if part:IsA("BasePart") then
            for _, part2 in pairs(VRCharacter:GetDescendants()) do
                if part2:IsA("BasePart") then
                    Utils:NoCollide(part, part2)
                end
            end
            for _, part2 in pairs(Character:GetDescendants()) do
                if part2:IsA("BasePart") then
                    Utils:NoCollide(part, part2)
                end
            end
        end
    end

    for _, part in pairs(VRCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            VRCollision(part)
        end
    end

    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") and not part.Parent:IsA("Tool") then
            VRCollision(part)
            if not DisabledParts[part.Name] and not part.Parent:IsA("Accessory") and RigType == "R15" then 
                if part.Name == "Head" then
                    cframeAlign(part, VRCharacter:FindFirstChild(part.Name))

                    Event(RunService.Heartbeat:connect(function()
                        local closestPlayer, distance = Utils:getClosestPlayer()
                        if closestPlayer and distance < 7 then  
                            Netlesse(part)
                        end
                    end))

                    continue
                end
                print(part.Name)
                Netless:align(part, VRCharacter:FindFirstChild(part.Name))
            end
        end
    end
    
    if RigType == "R6" then
        --Utils:Align(Character["Torso"], VRCharacter["UpperTorso"], Vector3.new(0,-.4,0))
        Netless:align(Character["Torso"], VRCharacter["UpperTorso"], Vector3.new(0,-.4,0))
        
        --Utils:Align(Character["Left Leg"], VRCharacter["LeftLowerLeg"], Vector3.new(0,0,0))
        Netless:align(Character["Left Leg"], VRCharacter["LeftLowerLeg"], Vector3.new(0,0,0))
        
        --Utils:Align(Character["Right Leg"], VRCharacter["RightLowerLeg"], Vector3.new(0,0,0))
        Netless:align(Character["Right Leg"], VRCharacter["RightLowerLeg"], Vector3.new(0,0,0))
        
        --Utils:Align(Character["Left Arm"], VirtualLeftArm, Vector3.new(0,.6,0))
        Netless:align(Character["Left Arm"], VirtualLeftArm, Vector3.new(0,.6,0))
        
       -- Utils:Align(Character["Right Arm"], VirtualRightArm, Vector3.new(0,.6,0))
        Netless:align(Character["Right Arm"], VirtualRightArm, Vector3.new(0,.6,0))

        if options.HeadMovement then
            Netless:align(Character["Head"], VRCharacter["Head"], Vector3.new(0,-.2,0))
        end
    end
    
    Humanoid.RootPart.Anchored = false
    
    --[Tools]
    local tools = {}
    function getClosestTool(hand)
        local tool = nil
        local maxDist = 1
        for _,v in pairs(tools) do
            if not v.Handle or v.Hand then continue end
            local dist = (hand.Position - v.Handle.Position).Magnitude
            if dist < maxDist then
                maxDist = dist
                tool = v
            end
        end
        return tool
    end
    
    local ToolTrackR, ToolTrackL do
        if RigType == "R6" then
            ToolTrackR = Instance.new("Part")
            ToolTrackR.Transparency = 1
            ToolTrackR.Size = VirtualRightArm.Size
            ToolTrackR.Anchored = true
            ToolTrackR.CanCollide = false
            ToolTrackR.Parent = Character
        
            ToolTrackL = Instance.new("Part")
            ToolTrackL.Transparency = 1
            ToolTrackL.Size = VirtualLeftArm.Size
            ToolTrackL.Anchored = true
            ToolTrackL.CanCollide = false
            ToolTrackL.Parent = Character
        
            Event(RunService.RenderStepped:Connect(function()
                ToolTrackR.CFrame = VirtualRightArm.CFrame  * CFrame.Angles(math.rad(-90),0,0) * CFrame.new(0,1,0)
                ToolTrackL.CFrame = VirtualLeftArm.CFrame * CFrame.Angles(math.rad(-90),0,0) * CFrame.new(0,1,0) 
            end))
        end
    end
    
    function doTool(tool)
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") and not tool:FindFirstChild("Done") then
            tool.ManualActivationOnly = true
            local tag = Instance.new("StringValue", tool); tag.Name = "Done"

            local realhandle = tool:FindFirstChild("Handle")
            realhandle.Massless = true
            realhandle.CFrame = Character.Humanoid.RootPart.CFrame
            
            local toolnum = #tools + 1
            local slot = options.InventorySlots[toolnum]
            tools[toolnum] = {Handle = realhandle, Hand = false}
            
            if not slot then return end
                
            if RigType == "R15" then
                realhandle.Name = "RealHandle"
                
                local lFakeHandle = realhandle:Clone(); lFakeHandle.Massless = false lFakeHandle.Name = "LeftHandle"; lFakeHandle.Parent = tool
                lFakeHandle.Transparency = 1
                
                local rFakeHandle = realhandle:Clone(); rFakeHandle.Massless = false; rFakeHandle.Name = "Handle"; rFakeHandle.Parent = tool
                rFakeHandle.Transparency = 1
        
                
                local rGrip = Character.RightHand:WaitForChild("RightGrip")
                local lGrip = rGrip:Clone(); lGrip.Part0 = Character.LeftHand; lGrip.Name = "LeftGrip"; lGrip.Part1 = lFakeHandle lGrip.Parent = Character.LeftHand; lGrip.C0 = rGrip.C0;
                
                local Align = slot
                tools[toolnum].Hold = function(hold, hand)
                    if hold then
                        tools[toolnum].Hand = hand
                        Align = hand == "Left" and lFakeHandle or rFakeHandle
                    else
                        tools[toolnum].Hand = false
                        Align = slot
                    end
                end
                
                Event(RunService.Stepped:Connect(function()
                    realhandle.CanCollide = false
                end))
                
                local att = Netless:align(realhandle, Humanoid.RootPart)
                Event(RunService.Heartbeat:Connect(function()
                    att.WorldCFrame = typeof(Align) == "CFrame" and Character.UpperTorso.CFrame * Align or Align:IsA("Part") and Align.CFrame
                end))
            else
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Name = "Jitterless"; bv.Parent = realhandle
                
                Event(RunService.Heartbeat:Connect(function()
                    local closestPlayer, distance = Utils:getClosestPlayer()
                    if Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 5 or closestPlayer and distance < 7 then 
                        Netlesse(realhandle)
                    end
                end))
            
                realhandle.Transparency = 0
                local rFakeHandle = realhandle:Clone(); rFakeHandle.Parent = tool; rFakeHandle.Name = "RightFakeHandle"; rFakeHandle.Transparency = 1; rFakeHandle.CanCollide = false; rFakeHandle.Massless = true
                local rFakeGrip = Instance.new("Weld", Character["Right Arm"]); rFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); rFakeGrip.C1 = tool.Grip; rFakeGrip.Part1 = rFakeHandle; rFakeGrip.Part0 = ToolTrackR
                
                local lFakeHandle = realhandle:Clone(); lFakeHandle.Parent = tool; lFakeHandle.Name = "LeftFakeHandle"; lFakeHandle.Transparency = 1; lFakeHandle.CanCollide = false; lFakeHandle.Massless = true
                local lFakeGrip = Instance.new("Weld", Character["Left Arm"]); lFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); lFakeGrip.C1 = tool.Grip; lFakeGrip.Part1 = lFakeHandle; lFakeGrip.Part0 = ToolTrackL
                
                local rToolAtt, toolAP, toolAO = Utils:Align(realhandle, rFakeHandle, Vector3.new(), Vector3.new(), {reactionforce = true, resp = 70, orientationrig = true})
                local lToolAtt = Instance.new("Attachment", lFakeHandle)
                
                local function doAlign()
                    pcall(function()
                        realhandle.CFrame = toolAO.Attachment1.WorldCFrame
                    end)
                end
                Event(RunService.RenderStepped:Connect(doAlign))
                
                local slotAtts = {}
                for i,v in pairs(options.InventorySlots) do
                    local Attachment = Instance.new("Attachment", Character["Torso"])
                    Attachment.CFrame = v
                    slotAtts[i] = Attachment
                end
                
                toolAP.Attachment1 = slotAtts[toolnum]
                toolAO.Attachment1 = slotAtts[toolnum]
    
                tools[toolnum].Hold = function(hold, hand)
                    if hold then
                        tools[toolnum].Hand = hand
                        toolAP.Attachment1 = hand == "Left" and lToolAtt or rToolAtt
                        toolAO.Attachment1 = hand == "Left" and lToolAtt or rToolAtt
                    else
                        tools[toolnum].Hand = false
                        toolAP.Attachment1 = slotAtts[toolnum]
                        toolAO.Attachment1 = slotAtts[toolnum]
                    end
                end
                
                RunService.Stepped:Connect(function()
                    realhandle.CanCollide = false
                end)
            end
            Utils:NoCollideModel(tool, Character)
            Utils:NoCollideModel(tool, VRCharacter)
            Event(RunService.Heartbeat:Connect(function()
                tool.Parent = Character
            end))
        end
    end
    
    function holdPart(v, grabAtt, drop)
        if v:IsA("BasePart") and v.Anchored == false then
            --PhysicsService:SetPartCollisionGroup(v, "Default")
            for _, x in next, v:GetChildren() do
                if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") or x:IsA("Attachment")  or x:IsA("AlignPosition") then
                    x:Destroy()
                end
            end
            if drop then return end
            grabAtt.WorldPosition = v.Position
            local att0 = Instance.new("Attachment", v)
            local AlignPosition = Instance.new("AlignPosition", v)
            AlignPosition.ReactionForceEnabled = true
            AlignPosition.MaxForce = 99999999999999
            AlignPosition.MaxVelocity = math.huge   
            AlignPosition.Responsiveness = 200
            AlignPosition.Attachment0 = att0 
            AlignPosition.Attachment1 = grabAtt
            --PhysicsService:SetPartCollisionGroup(v, "Character")
        end
    end

    if RigType == "R6" and Character["Right Arm"]:FindFirstChild("RightGrip") then Character["Right Arm"].RightGrip:Destroy() end
    for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        task.spawn(doTool, tool)
    end
    Event(Character.ChildAdded:Connect(doTool))
    Event(LocalPlayer.Backpack.ChildAdded:Connect(doTool))
    
    --[Climbing & Touching]
    function getPointPart(hand, distance, vector)
        local pointRay = Ray.new(hand.Position, typeof(hand) == "Instance" and -hand.CFrame.upVector.Unit * distance or hand[vector].Unit * distance)
        local part, position, normal = Workspace:FindPartOnRayWithIgnoreList(pointRay, {VRCharacter, Character, CurrentCamera})
        return part, position, normal
    end

    --[Keyboard]
    local Keyboard = game:GetObjects("rbxassetid://7333397685")[1]; Keyboard.Parent = workspace
    local SelectionBox = Instance.new("SelectionBox", workspace)
    local Preview = Keyboard.Preview.Display.Input
    local SelectedKey
    local KeyboardActive = false
    local Caps = false
    
    for _,key in pairs(Keyboard:GetChildren()) do
        if key.Name == "Board" then continue end
        local display = key:FindFirstChild("Display");
        if display and display:FindFirstChild("Key") then
            display.Key.TextScaled = true
        end
        key.Touched:Connect(function(part)
            if KeyboardActive then
                if part:IsDescendantOf(Character) then
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
                        for i,v in pairs(Keyboard:GetChildren()) do
                            if v.Name:find("Key") then
                                v.Display.Key.Text = Caps and v.Display.Key.Text:upper() or v.Display.Key.Text:lower()
                            end
                        end
                    elseif key.Name == "Exit" then
                        KeyboardActive = false
                    end
                end
            end
        end)
    end
    
    function handleKeyboard()
        if (Humanoid.RootPart.Position - Keyboard.PrimaryPart.Position).Magnitude > 20 then
            KeyboardActive = false
        end
        if KeyboardActive then
            local VRInputs =  VRInputService:GetVRInputs()
            local HeadCFrame = VRInputs[Enum.UserCFrame.Head]
            local CameraCenterCFrame = (CurrentCamera.CFrame*CFrame.new(HeadCFrame.p*CurrentCamera.HeadScale)) *CFrame.fromEulerAnglesXYZ(HeadCFrame:ToEulerAnglesXYZ())
            Keyboard.Parent = workspace
            --Keyboard:SetPrimaryPartCFrame(Keyboard.PrimaryPart.CFrame:lerp(Keyboard.PrimaryPart.CFrame * (CameraCenterCFrame - header.Position), .01))
            Keyboard:SetPrimaryPartCFrame(Keyboard.PrimaryPart.CFrame:lerp(CFrame.lookAt(Keyboard.PrimaryPart.Position, CameraCenterCFrame.Position + Vector3.new(0,2,0)) * CFrame.Angles(0,math.rad(180),0), .01))
        else
            Keyboard.Parent = ReplicatedStorage
        end
        local VRInputs =  VRInputService:GetVRInputs()
        local CameraCenter = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
        local Key = getPointPart(CameraCenter * VRInputs[Enum.UserCFrame.RightHand], 100, "lookVector")
        if Key and Key:IsDescendantOf(Keyboard) and Key.Name ~= "Board" and Key.Name ~= "Preview" then
            SelectionBox.Adornee = Key
            SelectedKey = Key
        else
            SelectionBox.Adornee = nil
            SelectedKey = nil
        end
    end
    Event(RunService.RenderStepped:Connect(handleKeyboard))

    --[Controls]
    local holdR
    local holdL
    Event(UserInputService.InputBegan:connect(function(key)
        if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
            local tool = getClosestTool(VirtualRightArm)
            local part = getPointPart(VirtualRightArm, 1)
            if tool then
                tool.Hold(true, "Right")
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 3)
                wait()
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
            elseif part then
                if not part:IsGrounded() and not part.Anchored == true then
                    holdPart(part, rGrabAtt)
                    holdR = part
                else
                    if part.Parent:IsA("Tool") then return end
                    rGrabWeld.Part1 = part
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 3)
                    wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
                end
            end
        elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
            local tool = getClosestTool(VirtualLeftArm)
            local part = getPointPart(VirtualLeftArm, 1)
            if tool then
                tool.Hold(true, "Left")
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 3)
                wait()
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
            elseif part then
                if not part:IsGrounded() and not part.Anchored == true then
                    holdPart(part, lGrabAtt)
                    holdL = part
                else
                    if part.Parent:IsA("Tool") then return end
                    lGrabWeld.Part1 = part
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 3)
                    wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
                end
            end
        elseif key.KeyCode == Enum.KeyCode.ButtonL2 or key.UserInputType == Enum.UserInputType.MouseButton1 then
            local VRInputs =  VRInputService:GetVRInputs()
            local HeadCFrame = VRInputs[Enum.UserCFrame.Head]
            local CameraCenterCFrame = (CurrentCamera.CFrame*CFrame.new(HeadCFrame.p*CurrentCamera.HeadScale)) *CFrame.fromEulerAnglesXYZ(HeadCFrame:ToEulerAnglesXYZ())
            Keyboard:SetPrimaryPartCFrame((CameraCenterCFrame + Vector3.new(0,3,0)) * CFrame.new(0,0,-8))
            KeyboardActive = not KeyboardActive
            for _,tool in pairs(tools) do
                if tool.Hand == "Left" and tool.Handle then
                    tool.Handle.Parent:Activate()
                    print("Left")
                end
            end
        elseif key.KeyCode == Enum.KeyCode.ButtonR2 or key.UserInputType == Enum.UserInputType.MouseButton2 then
            if SelectedKey then
                firetouchinterest(Humanoid.RootPart, SelectedKey, 0)
                wait()
                firetouchinterest(Humanoid.RootPart, SelectedKey, 1)
            end
            for _,tool in pairs(tools) do
                if tool.Hand == "Right" and tool.Handle then
                    tool.Handle.Parent:Activate()
                    print("Right")
                end
            end
        end
    end))

    Event(UserInputService.InputEnded:connect(function(key)
        if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
            rGrabWeld.Part1 = nil
            pcall(holdPart, holdR, nil, true)
            for _,tool in pairs(tools) do
                if tool.Hand == "Right" then
                    tool.Hold(false)
                end
            end
        elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
            lGrabWeld.Part1 = nil
            pcall(holdPart, holdL, nil, true)
            for _,tool in pairs(tools) do
                if tool.Hand == "Left" then
                    tool.Hold(false)
                end
            end
        end
    end))
    
    --[Teleporting]
    local oldpos 
    Event(Humanoid.RootPart:GetPropertyChangedSignal("Position"):Connect(function()
        if oldpos and (oldpos - Humanoid.RootPart.Position).Magnitude > 10 then
            rGrabWeld.Part1 = nil
            lGrabWeld.Part1 = nil
            VirtualLeftArm.CFrame = Humanoid.RootPart.CFrame
            VirtualRightArm.CFrame = Humanoid.RootPart.CFrame
        end
        oldpos = Humanoid.RootPart.Position
    end))

    --[Death]
    function died()
        for i,v in pairs(Character:GetDescendants()) do
            if v:IsA("BodyVelocity") or v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
                v:Destroy()
            elseif options.HeadMovement and v:IsA("Humanoid") then
                v:Destroy()
            end
        end
        if CameraService.CurrentCamera then
            CameraService.CurrentCamera:Disable()
        end
        RunService:UnbindFromRenderStep("sauceVRCharacterModelUpdate")
        CurrentCamera.CameraType = "Custom"
        Keyboard:Destroy()
        Event:Clear()
        task.delay(6, function()
            VRCharacter:Destroy()
        end)
    end
    local deathEvent = Humanoid.Died:Connect(died)
    
    --[UI]
    local UI = require(sauceVR.Components.UI.Library)
    local window = UI:CreateWindow()
        local settingsTab = window:CreateTab()
            local movementMode = settingsTab:AddChoice("Movement Mode", {"None", "SmoothLocomotion", "TeleportController"}, options.DefaultMovementMethod, function(mode)
                ControlService:SetActiveController(mode)
            end)
            local cameraMode = settingsTab:AddChoice("Camera Mode", {"Default", "ThirdPersonTrack"}, options.DefaultCameraOption, function(mode) 
                CameraService:SetActiveCamera(mode)
            end)
            local recenterButton = settingsTab:AddButton("Recenter", function() 
                VRInputService:Recenter()
            end)
            local eyeLevelButton = settingsTab:AddButton("Set Eye Level", function() 
                VRInputService:SetEyeLevel()
            end)
            local rejoinButton = settingsTab:AddButton("Rejoin", function() 
                if #Players:GetPlayers() <= 1 then
                    Players.LocalPlayer:Kick("\nRejoining...")
                    wait()
                    game:GetService('TeleportService'):Teleport(game.PlaceId, LocalPlayer)
	            else
	    	        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)
    Event(RunService.RenderStepped:Connect(function()
        UIpart.SurfaceGui.AlwaysOnTop = true
        local VRInputs =  VRInputService:GetVRInputs()
        local HeadCFrame = VRInputs[Enum.UserCFrame.Head]
        local CameraCenterCFrame = (CurrentCamera.CFrame*CFrame.new(HeadCFrame.p*CurrentCamera.HeadScale)) *CFrame.fromEulerAnglesXYZ(HeadCFrame:ToEulerAnglesXYZ())
        UIpart.CFrame = UIpart.CFrame:Lerp(CameraCenterCFrame * CFrame.new(2,0,-5) * CFrame.Angles(0,math.rad(180),0), .02)
    end))
    window.SurfaceGui.Enabled = false
    
    local UIEnabled = false
    Event(BindableEvent.Event:Connect(function(type)
        if type == "UI" then
            UIEnabled = not UIEnabled
            window.SurfaceGui.Enabled = UIEnabled
        end
    end))
    
    

    function ViewHUD()
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
                
                Character:WaitForChild("Head")
                Character:WaitForChild("Humanoid")
                
                wait(3)
                
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
                        if not string.find(Part.Name, "Fake") and Part.Name ~= "HumanoidRootPart" and not Part.Parent:IsA("Tool") and Part ~= ToolTrackL and Part ~= ToolTrackR then
                            Part.Transparency = 0
                        else 
                            Part.Transparency = 1
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
    
    
    function ChatHUD()
        local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")
     
        local VRService = game:GetService("VRService")
     
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
                    if Input.KeyCode == Enum.KeyCode.ButtonB then
                        ChatHUD.Enabled = not ChatHUD.Enabled
                    end
                end
            end)
     
            local RenderStepped = RunService.RenderStepped:Connect(function()
                --local VRInputs =  VRInputService:GetVRInputs()
                --local CameraCenter = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
                ChatPart.CFrame = VirtualLeftArm.CFrame  * CFrame.Angles(math.rad(-90),math.rad(0), math.rad(180))
            end)
     
            local CharacterAdded
     
            CharacterAdded = Client.CharacterAdded:Connect(function()
                OnInput:Disconnect()
                RenderStepped:Disconnect()
                CharacterAdded:Disconnect()
     
                ChatHUD:Destroy()
                ChatHUD = nil
            end)
        end
     
        wait(9e9)
    end;
    
    task.spawn(ViewHUD)
    task.spawn(ChatHUD)
end

return StartVR