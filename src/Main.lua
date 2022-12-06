local sauceVR = script:FindFirstAncestor("sauceVR")

local Players = game:GetService("Players")  
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = require(sauceVR.Components.UI.VRLibrary)
local Keyboard = require( sauceVR.Components.UI.Keyboard)

local Event = require(sauceVR.Util.Event)
local Utils = require(sauceVR.Util.Utils)
local Netless = require(sauceVR.Util.Netless)

local VRReady = UserInputService.VREnabled
local diedFunc

getgenv().options = {
    HeadMovement = true,
    Inventory = "Bodyslots" ,
    DefaultMovementMethod = "SmoothLocomotion",
    DefaultCameraOption = "Default",

    LocalCharacterTransparency = 0.5,
    MaxNeckRotation = math.rad(45),
    MaxNeckSeatedRotation = math.rad(60),
    MaxNeckTilt = math.rad(60),
    MaxTorsoBend = math.rad(10),
    InventorySlots = {
        [1] = CFrame.new(-1,-.25,0) * CFrame.Angles(0,math.rad(0),0),
        [2] = CFrame.new(1,-.25,0) * CFrame.Angles(0,math.rad(90),0),
        [3] = CFrame.new(0,0,.5) * CFrame.Angles(0,math.rad(90),0),
    },
    NetlessVelocity = Vector3.new(0,-45,0)
}

--Disable default VR controls.
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
ContextActionService:BindActionAtPriority("DisableInventoryKeys", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2)


--Disable the native VR controller models.
--Done in a pcall in case the SetCore is not registered or is removed.
StarterGui:SetCore("VREnableControllerModels", false)
DefaultCursorService:SetCursorState("Detect")

--Enables bubble chat if disabled.
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

--Bypass any bodymover checks.
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


--[[
Load sauceVR.
--]]
function Init()
    --Set up Character.
    local LoadCharacter; LoadCharacter = function()
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
            
            if options.HeadMovement then
                Humanoid.RootPart.Anchored = true
                Utils:loadingScreen(Players.RespawnTime)
                Utils:permaDeath(Character)
                Humanoid.RootPart.Anchored = false
            else
                options.MaxNeckRotation = math.rad(0)
                options.MaxNeckSeatedRotation = math.rad(0)
                options.MaxNeckTilt = math.rad(0)
                options.MaxTorsoBend = math.rad(0)
            end

            if RigType == "R15" then
                VRCharacter = Utils:VRCharacter(Character, 1)
            else
                VRCharacter = game:GetObjects("rbxassetid://7307187904")[1]
                for i,v in pairs(VRCharacter:GetDescendants()) do
                    if v:IsA("BasePart") or v:IsA("Decal") then
                        if v:IsA("BasePart") then
                            Event(RunService.Stepped:Connect(function()
                                v.CanCollide = false
                            end))
                        end
                        v.Transparency = 1
                    end
                end
                VRCharacter.Parent = workspace.Terrain
                VRCharacter:SetPrimaryPartCFrame(Humanoid.RootPart.CFrame)
            end
            
            
            Utils:cframeAlign(VRCharacter.Humanoid.RootPart, Humanoid.RootPart)
            
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Parent = VRCharacter.Humanoid.RootPart

            local bg = Instance.new("BodyGyro", Humanoid.RootPart)
            bg.Name = "TurnGyro"
            bg.MaxTorque = Vector3.new(9e9,20000,9e9); bg.P = 20000 bg.D = 20
            
            Character.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(50, 100, 0, 100,100)
            VRCharacter.Humanoid.AutoRotate = false
            VRCharacter.Humanoid.PlatformStand = true
        end
        
        --Create hand collision.
        local VirtualRightArm, VirtualLeftArm, RHA, LHA, RgrabWeld, LgrabWeld, RgrabAtt, LgrabAtt do
            function createCollisonHand(name, cframe, size)
                local arm = Instance.new("Part")
                arm.CFrame = cframe
                arm.Name = name 
                arm.Size = size
                arm.Transparency = 1
                arm.CustomPhysicalProperties = PhysicalProperties.new(1, 1000, -100, 100,100)
                arm.Parent = Character
                    
                local ap = Instance.new("AlignPosition");
                ap.RigidityEnabled = true; ap.ReactionForceEnabled = true; ap.ApplyAtCenterOfMass = false; ap.MaxForce = 100000000; ap.MaxVelocity = math.huge/9e110; ap.Responsiveness = 200; ap.Parent = arm
                local ao = Instance.new("AlignOrientation");
                ao.RigidityEnabled = true; ao.ReactionTorqueEnabled = false; ao.PrimaryAxisOnly = false; ao.MaxTorque = 100000000; ao.MaxAngularVelocity = math.huge/9e110; ao.Responsiveness = 200; ao.Parent = arm
                local att = Instance.new("Attachment", arm)
                    
                local rootAtt = Instance.new("Attachment", Character.HumanoidRootPart)
            
                local grabWeld = Instance.new("WeldConstraint", arm); grabWeld.Part0 = arm
                local grabAtt = Instance.new("Attachment", arm)
                    
                ap.Attachment0 = att; ap.Attachment1 = rootAtt
                ao.Attachment0 = att; ao.Attachment1 = rootAtt
                    
                return arm, ap, ao, att, rootAtt, grabWeld, grabAtt
            end

            VirtualLeftArm, lAO, lAO, lAtt, LHA, lGrabWeld, lGrabAtt = createCollisonHand("Fake Left", VRCharacter["LeftHand"].CFrame, VRCharacter["LeftHand"].Size)
            VirtualRightArm, rAO, rAO, rAtt, RHA, rGrabWeld, rGrabAtt = createCollisonHand("Fake Right", VRCharacter["RightHand"].CFrame, VRCharacter["RightHand"].Size)
            
            Event(VirtualRightArm.Touched:Connect(function(part)
                if VirtualRightArm:CanCollideWith(part) and not part:IsDescendantOf(Character) and not part:IsDescendantOf(VRCharacter) then
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, (VirtualRightArm.Velocity - part.Velocity).Magnitude / 10)
                    wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
                end
            end))
            
            Event(VirtualLeftArm.Touched:Connect(function(part)
                if VirtualLeftArm:CanCollideWith(part) and not part:IsDescendantOf(Character) and not part:IsDescendantOf(VRCharacter) then
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, (VirtualLeftArm.Velocity - part.Velocity).Magnitude / 10)
                    wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
                end
            end))
        end
        
        --Update VR Character
        local VirtualCharacter do
            VirtualCharacter = require(sauceVR.Components.Character.Character).new(VRCharacter)
            VirtualCharacter.Humanoid = Humanoid
            VirtualCharacter.Parts.HumanoidRootPart = Humanoid.RootPart

            ControlService:UpdateCharacterReference(VirtualCharacter)
            ControlService:SetActiveController("None")
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

        Humanoid.RootPart.Anchored = false

        --Replicate parts.
        local DisabledParts = {}
        DisabledParts["HumanoidRootPart"] = true
        DisabledParts["Fake Right"] = true
        DisabledParts["Fake Left"] = true
        DisabledParts["Head"] = not options.HeadMovement

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
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Parent = part

                        Utils:cframeAlign(part, VRCharacter:FindFirstChild(part.Name))

                        Event(RunService.Heartbeat:connect(function()
                            local closestPlayer, distance = Utils:getClosestPlayer()
                            if closestPlayer and distance < 7 then  
                                part.Velocity = options.NetlessVelocity
                            end
                        end))


                        continue
                    end
                    Netless:align(part, VRCharacter:FindFirstChild(part.Name))
                end
            end
        end
        
        if RigType == "R6" then
            Netless:align(Character["Torso"], VRCharacter["UpperTorso"], Vector3.new(0,-.4,0))
            Netless:align(Character["Left Leg"], VRCharacter["LeftLowerLeg"], Vector3.new(0,0,0))
            Netless:align(Character["Right Leg"], VRCharacter["RightLowerLeg"], Vector3.new(0,0,0))
            Netless:align(Character["Left Arm"], VirtualLeftArm, Vector3.new(0,.6,0))
            Netless:align(Character["Right Arm"], VirtualRightArm, Vector3.new(0,.6,0))
            if options.HeadMovement then
                Netless:align(Character["Head"], VRCharacter["Head"], Vector3.new(0,-.2,0))
            end
        end
        
        --Set up tool holding.
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
            if RigType == "R15" then return end -- Disable for R15 for now

            if tool:IsA("Tool") and tool:FindFirstChild("Handle") and not tool:FindFirstChild("Done") then
                tool.ManualActivationOnly = true
                local tag = Instance.new("StringValue", tool); tag.Name = "Done"

                local realhandle = tool:FindFirstChild("Handle")
                realhandle.Massless = true
                realhandle.CFrame = Character.Humanoid.RootPart.CFrame
                
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Name = "Jitterless"; bv.Parent = realhandle

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
                           
                    RunService.Stepped:Connect(function()
                        realhandle.CanCollide = false
                        realhandle.CFrame = typeof(Align) == "CFrame" and Character.UpperTorso.CFrame * Align or Align:IsA("Part") and Align.CFrame
                    end)
                else
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Name = "Jitterless"; bv.Parent = realhandle
                    
                    Event(RunService.Heartbeat:Connect(function()
                        local closestPlayer, distance = Utils:getClosestPlayer()
                        if part and (Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 5 or closestPlayer and distance < 7) then 
                            part.Velocity = options.NetlessVelocity
                        end
                    end))
                
                    realhandle.Transparency = 0
                    local rFakeHandle = realhandle:Clone(); rFakeHandle.Parent = tool; rFakeHandle.Name = "RightFakeHandle"; rFakeHandle.Transparency = 1; rFakeHandle.CanCollide = false; rFakeHandle.Massless = true
                    local rFakeGrip = Instance.new("Weld", Character["Right Arm"]); rFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); rFakeGrip.C1 = tool.Grip; rFakeGrip.Part1 = rFakeHandle; rFakeGrip.Part0 = ToolTrackR
                    
                    local lFakeHandle = realhandle:Clone(); lFakeHandle.Parent = tool; lFakeHandle.Name = "LeftFakeHandle"; lFakeHandle.Transparency = 1; lFakeHandle.CanCollide = false; lFakeHandle.Massless = true
                    local lFakeGrip = Instance.new("Weld", Character["Left Arm"]); lFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); lFakeGrip.C1 = tool.Grip; lFakeGrip.Part1 = lFakeHandle; lFakeGrip.Part0 = ToolTrackL
                    
                    local rToolAtt, toolAP, toolAO = Utils:Align(realhandle, rFakeHandle, Vector3.new(), Vector3.new(), {reactionforce = true, reactiontorque = true, resp = 70, orientationrig = false})
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
        Event(Character.ChildAdded:Connect(doTool))
        Event(LocalPlayer.Backpack.ChildAdded:Connect(doTool))

        function holdPart(v, grabAtt, drop)
            if v:IsA("BasePart") and v.Anchored == false then
                for _, x in next, v:GetChildren() do
                    if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") or x:IsA("Attachment")  or x:IsA("AlignPosition") or x:IsA("NoCollisionConstraint") then
                        x:Destroy()
                    end
                end

                if drop then return end
                
                Utils:NoCollide(v, grabAtt.Parent, v)

                grabAtt.WorldPosition = v.Position

                local att0 = Instance.new("Attachment", v)
                local AlignPosition = Instance.new("AlignPosition", v)
                AlignPosition.ReactionForceEnabled = false
                AlignPosition.MaxForce = 9999999999999999
                AlignPosition.MaxVelocity = math.huge
                AlignPosition.Responsiveness = 200
                AlignPosition.Attachment0 = att0 
                AlignPosition.Attachment1 = grabAtt
            end
        end

        if RigType == "R6" and Character["Right Arm"]:FindFirstChild("RightGrip") then Character["Right Arm"].RightGrip:Destroy() end
        for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            task.spawn(doTool, tool)
        end
        


        --Set up controls.
        local holdR, holdL
        Event(UserInputService.InputBegan:connect(function(key)
            if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
                local tool = getClosestTool(VirtualRightArm)
                local part = Utils:getPointPart(VirtualRightArm, 1, "upVector", {VRCharacter, Character, CurrentCamera}) or Utils:getPointPart(VirtualRightArm, 1, "rightVector", {VRCharacter, Character, CurrentCamera}) 
                if tool then
                    tool.Hold(true, "Right")
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 3)
                    task.wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
                elseif part then
                    if not part:IsGrounded() and not part.Anchored == true then
                        holdPart(part, rGrabAtt)
                        holdR = part
                    else
                        if part.Parent:IsA("Tool") then return end
                        rGrabWeld.Part1 = part
                        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 3)
                        task.wait()
                        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
                    end
                end
            elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
                local tool = getClosestTool(VirtualLeftArm)
                local part = Utils:getPointPart(VirtualLeftArm, 1, "upVector",  {VRCharacter, Character, CurrentCamera}) or Utils:getPointPart(VirtualLeftArm, 1, "rightVector",  {VRCharacter, Character, CurrentCamera}, true)
                if tool then
                    tool.Hold(true, "Left")
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 3)
                    task.wait()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
                elseif part then
                    if not part:IsGrounded() and not part.Anchored == true then
                        holdPart(part, lGrabAtt)
                        holdL = part
                    else
                        if part.Parent:IsA("Tool") then return end
                        lGrabWeld.Part1 = part
                        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 3)
                        task.wait()
                        HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
                    end
                end
            elseif key.KeyCode == Enum.KeyCode.ButtonL2 then--or key.UserInputType == Enum.UserInputType.MouseButton1 then
            elseif key.KeyCode == Enum.KeyCode.ButtonR2 or key.UserInputType == Enum.UserInputType.MouseButton2 then
                if SelectedKey then
                    firetouchinterest(Humanoid.RootPart, SelectedKey, 0)
                    wait()
                    firetouchinterest(Humanoid.RootPart, SelectedKey, 1)
                end
                for _,tool in pairs(tools) do
                    if tool.Hand == "Right" and tool.Handle then
                        tool.Handle.Parent:Activate()
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
        
        --Handle teleporting.
        local oldpos; Event(Humanoid.RootPart:GetPropertyChangedSignal("Position"):Connect(function()
            if oldpos and (oldpos - Humanoid.RootPart.Position).Magnitude > 10 then
                rGrabWeld.Part1 = nil
                lGrabWeld.Part1 = nil
                VirtualLeftArm.CFrame = Humanoid.RootPart.CFrame
                VirtualRightArm.CFrame = Humanoid.RootPart.CFrame
            end
            oldpos = Humanoid.RootPart.Position
        end))

        --Reset character when death.
        diedFunc = function()
            diedFunc = nil
            Character:BreakJoints()
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
            Event:Clear()
            VRCharacter:Destroy()
            task.delay(Players.RespawnTime+1, function()
                LoadCharacter()
            end)
        end

        local resetBindable = Instance.new("BindableEvent") do
            Event(Humanoid.Died:Connect(diedFunc))
            Event(resetBindable.Event:connect(diedFunc))
            StarterGui:SetCore("ResetButtonCallback", resetBindable)
        end

        --fuck it noclip
        for i,v in pairs(VRCharacter:GetDescendants()) do
            Event(RunService.Stepped:Connect(function()
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end))
        end

        for i,v in pairs(Character:GetDescendants()) do
            Event(RunService.Stepped:Connect(function()
                if v:IsA("BasePart") and not v.Name:find("Fake") then
                    v.CanCollide = false
                end
            end))
        end
    end

    -- Prompt head movement.
    Library:CreatePrompt("Enable Head Movement?", "This will permanently kill your character and may break some functions in-game", {"No", "Yes"}, function(response) 
        if response == "Yes" then
            options.HeadMovement = true
        else
            options.HeadMovement = false
        end
    end)
    
    -- Set up Keyboard.
    Keyboard:Init()

    --Set up VR Menu.
    local optionsMenu = Library:CreateMenu("Options") do
        local generalTab = optionsMenu:AddTab("General", "rbxassetid://10675474985")

            generalTab:AddSelectButton("Movement", options.DefaultMovementMethod, {"None", "SmoothLocomotion", "TeleportController"}, function(mode) 
                ControlService:SetActiveController(mode)
            end)

            generalTab:AddSelectButton("Cursor", "Detect", {"Detect", "Enabled", "Disabled"}, function(mode) 
                DefaultCursorService:SetCursorState(mode)
            end)

            generalTab:AddButton("Set Eye Level", function() 
                VRInputService:SetEyeLevel() 
            end)

        
            generalTab:AddButton("Reset", function()
                if diedFunc then
                    diedFunc()
                end
            end)

            generalTab:AddButton("Rejoin", function() 
                if #Players:GetPlayers() <= 1 then
                    Players.LocalPlayer:Kick("\nRejoining...")
                    wait()
                    game:GetService('TeleportService'):Teleport(game.PlaceId, LocalPlayer)
                else
                    game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)

        local bodyTab = optionsMenu:AddTab("Body", "rbxassetid://10653366793")
            bodyTab:AddSlider("Character Transparency", options.LocalCharacterTransparency, 0, 1, 0.1, function(num) 
                options.LocalCharacterTransparency = num
            end)

            
            bodyTab:AddSlider("Max Neck Rotation", math.round(options.MaxNeckRotation*(180/math.pi)), 0, 180, 15, function(num) 
                options.MaxNeckRotation = math.rad(num)
            end)

            bodyTab:AddSlider("Max Neck Tilt", math.round(options.MaxNeckTilt*(180/math.pi)), 0, 180, 15, function(num) 
                options.MaxNeckTilt = math.rad(num)
            end)

            bodyTab:AddSlider("Max Torso Bend", math.round(options.MaxTorsoBend*(180/math.pi)), 0, 180, 15, function(num) 
                options.MaxTorsoBend = math.rad(num)
            end)

            bodyTab:AddSlider("Max Neck Tilt", math.round(options.MaxNeckTilt*(180/math.pi)), 0, 180, 15, function(num) 
                options.MaxNeckTilt = math.rad(num)
            end)

    end


    local buttonGroup = Library:CreateButtonGroup() do
        buttonGroup:AddButton("Options", "rbxassetid://7059346373", function() 
            optionsMenu:SetEnabled(true) 
        end)

        buttonGroup:AddButton("Keyboard", "rbxassetid://11738672671", function() 
            Keyboard.Active = true
            local VRInputs =  VRInputService:GetVRInputs()
            local HeadCFrame = VRInputs[Enum.UserCFrame.Head]
            local CameraCenterCFrame = ((CurrentCamera.CFrame*CFrame.new(HeadCFrame.p*CurrentCamera.HeadScale)) * CFrame.fromEulerAnglesXYZ(HeadCFrame:ToEulerAnglesXYZ())) 
            Keyboard.Model:PivotTo((CameraCenterCFrame) * CFrame.new(0,0,-8))
        end)

        local switch = false
        buttonGroup:AddButton("Camera", "rbxassetid://11738494422", function() 
            if switch then
                CameraService:SetActiveCamera("Default")
            else
                CameraService:SetActiveCamera("ThirdPersonTrack")
            end
            switch = not switch
        end)

        buttonGroup:AddButton("Recenter", "rbxassetid://11738671901", function()  
            VRInputService:Recenter() 
        end)

        buttonGroup:AddButton("Reset", "rbxassetid://6433106861", function()  
            if diedFunc then
                diedFunc()
            end
        end)
    end

    if not VRReady then -- debug
        buttonGroup:SetEnabled(true)
    end

    sauceVREvent.Event:Connect(function(type)
        if type == "UI" then
            buttonGroup:SetEnabled(not buttonGroup.Enabled)
        end
    end)
    
    --Load Huds.
    local viewHUD, chatHUD = require(sauceVR.Components.UI.HUDs.Viewport), require(sauceVR.Components.UI.HUDs.Chat)

    task.spawn(viewHUD)
    task.spawn(chatHUD)

    --Load Character.
    LoadCharacter()
end

return Init