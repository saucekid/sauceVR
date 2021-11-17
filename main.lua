getgenv().options = {
    --None, SmoothLocomotion, or teleport (These can be changed in settings)
    DefaultMovementMethod = "SmoothLocomotion",
    
    --Default or ThirdPersonTrack (These can be changed in settings)
    DefaultCameraOption = "Default",
    
    --Bodyslots or Default (Bodyslots is buggy and)
    Inventory = "Bodyslots" ,
    
    --Button to press to jump
    JumpButton = Enum.KeyCode.ButtonA,
    
--==[Advanced Options]
    --Character Transparency in First Person
    LocalCharacterTransparency = 0.5,

    --Maximum angle the neck can turn before the torso turns.
    MaxNeckRotation = math.rad(35),
    MaxNeckSeatedRotation = math.rad(60),
    
    --Maximum angle the neck can tilt before the torso tilts.
    MaxNeckTilt = math.rad(30),
    
    --Maximum angle the center of the torso can bend.
    MaxTorsoBend = math.rad(10),
    
    InventorySlots = { 
        [1] = CFrame.new(-1,-.25,0) * CFrame.Angles(0,math.rad(0),0),
        [2] = CFrame.new(1,-.25,0) * CFrame.Angles(0,math.rad(90),0),
        [3] = CFrame.new(0,0,.5) * CFrame.Angles(0,math.rad(90),0),
    },
        
    --Velocity of part (more = more jitter, but more stable)
    NetlessVelocity = Vector3.new(0,-45,0)
}



repeat wait() until game:IsLoaded() and not _G.Executed
_G.Executed = true

loadstring(game:HttpGet("https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/Services/PhysicsService.lua"))()

--=========[Variables]
local Players = game:GetService("Players");     
local Lighting = game:GetService("Lighting");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local PhysicsService = game:GetService("PhysicsService");
local ScriptContext = game:GetService("ScriptContext");
local VRService = game:GetService("VRService");
local VirtualUser = game:GetService("VirtualUser");
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

--[Physics/Network Settings]
settings().Physics.AllowSleep = false 
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled

PhysicsService:CreateCollisionGroup("Character")
PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)

--[Disable Default VR Controls]
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
ContextActionService:BindActionAtPriority("DisableInventoryKeys", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2)

--[Bypass BodyMover Check]
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
    if i == "ClassName" and OrgFunc(Self, "BodyMover") then
        return "Instance"
    end
    return OldIndex(Self, i)
end)

--=========[Modules]
function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module = loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local Event = getModule("Event")
local Utils = getModule("Utils")

--[Services]

getgenv().CameraService = getModule("Services/CameraService");
getgenv().ControlService = getModule("Services/ControlService");
getgenv().VRInputService = getModule("Services/VRInputService");

--=========[Other Functions]
local function cframeAlign(a, b, pos)
    local Motor = Utils:GetMotorForLimb(a); if Motor then Motor:Destroy() end
    local function doAlign()
        pcall(function()
            if b:IsA("Attachment") then
                a.CFrame = pos and b.WorldCFrame * pos or b.WorldCFrame
            else
                a.CFrame = pos and b.CFrame * pos or b.CFrame
            end
        end)
    end
    Event(RunService.Stepped:Connect(doAlign))
    Event(RunService.Heartbeat:Connect(doAlign))
    Event(RunService.RenderStepped:Connect(doAlign))
end

local function createBeam(hand, part, position)
    if hand:FindFirstChild("Beam") then
        hand.Beam.Attachment0:Destroy()
        hand.Beam.Attachment1:Destroy()
        hand.Beam:Destroy()
    end
end

local function Netless(part)
    if not part:IsA("BasePart") then return end
    part.Velocity = options.NetlessVelocity
end

--=========[VR script]
function StartVR()
    coroutine.wrap(function()
        for i = 1,600 do
            local Worked = pcall(function()
                StarterGui:SetCore("VRLaserPointerMode",0)
                StarterGui:SetCore("VREnableControllerModels",false)
            end)
            if Worked then break end
            wait(0.1)
        end
    end)()
    
    for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then 
            task.spawn(function() 
                tool.Parent = Character 
                task.wait(.1) 
                tool.Parent = LocalPlayer.Backpack 
            end) 
        end
    end
    
    local Character, Humanoid, RigType do
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        Humanoid = Utils.WaitForChildOfClass(Character, "Humanoid")
        RigType = Humanoid.RigType.Name
        
        --[Anticheat Bypass]
        for _, connection in pairs(getconnections(Character.DescendantAdded)) do
            connection:Disable()
        end
        for i,v in pairs(Character:GetChildren()) do
            for _, connection in pairs(getconnections(v.ChildRemoved)) do
                connection:Disable()
            end
            for _, connection in pairs(getconnections(v.ChildAdded)) do
                connection:Disable()
            end
        end
        
        if RigType == "R15" then
            getgenv().VRCharacter = Utils:VRCharacter(Character, 1)
        else
            getgenv().VRCharacter = game:GetObjects("rbxassetid://7307187904")[1]
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
        function createArm(name, cframe, size)
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
        
        VirtualLeftArm, lAO, lAO, lAtt, LHA, lGrabWeld, lGrabAtt = createArm("Fake Left", VRCharacter["LeftHand"].CFrame, VRCharacter["LeftHand"].Size)
        VirtualRightArm, rAO, rAO, rAtt, RHA, rGrabWeld, rGrabAtt = createArm("Fake Right", VRCharacter["RightHand"].CFrame, VRCharacter["RightHand"].Size)
        
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
    
    --[Updating VR Character]
    local VirtualCharacter do
        VirtualCharacter = getModule("Character/Character").new(VRCharacter)
        VirtualCharacter.Humanoid = Humanoid
        VirtualCharacter.Parts.HumanoidRootPart = Humanoid.RootPart

        ControlService:UpdateCharacterReference(VirtualCharacter)
        ControlService:SetActiveController(options.DefaultMovementMethod)
        CameraService:SetActiveCamera(VRReady and options.DefaultCameraOption)
        
        local MainMenu = getModule("UI/MainMenu")
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
    DisabledParts["Head"] = options.HeadMovement and false or true
    
    for _, part in pairs(VRCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "Character")
        end
    end

    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "Character")
            if not DisabledParts[part.Name] and not part.Parent:IsA("Accessory") then 
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0,0,0)
                bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                bv.P = 9e9
                bv.Parent = part
                
                if RigType == "R15" then
                    cframeAlign(part, VRCharacter:FindFirstChild(part.Name))
                    part.CustomPhysicalProperties = PhysicalProperties.new(0,10,10)
                    Event(RunService.Heartbeat:connect(function()
                        local closestPlayer, distance = Utils:getClosestPlayer()
                        if Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 3 or closestPlayer and distance < 7 then  
                            Netless(part)
                        end
                    end))
                else
                    part.CustomPhysicalProperties = PhysicalProperties.new(5,10,10)
                    Event(RunService.Heartbeat:connect(function()
                        local closestPlayer, distance = Utils:getClosestPlayer()
                        if Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 3 or closestPlayer and distance < 7 then  
                            Netless(part)
                        end
                    end))
                end
            end
        end
    end
    
    if RigType == "R6" then
        Utils:Align(Character["Torso"], VRCharacter["UpperTorso"], Vector3.new(0,-.4,0))
        cframeAlign(Character["Torso"], VRCharacter["UpperTorso"], CFrame.new(0,-.4,0))
        
        Utils:Align(Character["Left Leg"], VRCharacter["LeftLowerLeg"], Vector3.new(0,0,0))
        cframeAlign(Character["Left Leg"], VRCharacter["LeftLowerLeg"], CFrame.new(0,0,0))
        
        Utils:Align(Character["Right Leg"], VRCharacter["RightLowerLeg"], Vector3.new(0,0,0))
        cframeAlign(Character["Right Leg"], VRCharacter["RightLowerLeg"], CFrame.new(0,0,0))
        
        Utils:Align(Character["Left Arm"], VRCharacter["LeftLowerArm"], Vector3.new(0,.4,0))
        cframeAlign(Character["Left Arm"], VRCharacter["LeftLowerArm"], CFrame.new(0,.4,0))
        
        Utils:Align(Character["Right Arm"], VRCharacter["RightLowerArm"], Vector3.new(0,.4,0))
        cframeAlign(Character["Right Arm"], VRCharacter["RightLowerArm"], CFrame.new(0,.4,0))
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
            
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Name = "Jitterless"; bv.Parent = realhandle
            
            Event(RunService.Heartbeat:Connect(function()
                local closestPlayer, distance = Utils:getClosestPlayer()
                if Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 5 or closestPlayer and distance < 7 then 
                    Netless(realhandle)
                end
            end))
            
            local toolnum = #tools + 1
            local slot = options.InventorySlots[toolnum]
            tools[toolnum] = {Handle = realhandle, Hand = false}
            
            if not slot then return end
                
            if RigType == "R15" then
                realhandle.Name = "RealHandle"
                
                local lFakeHandle = realhandle:Clone(); lFakeHandle.Massless = true lFakeHandle.Name = "LeftHandle"; lFakeHandle.Parent = tool
                lFakeHandle.Transparency = 1
                
                local rFakeHandle = realhandle:Clone(); rFakeHandle.Massless = true; rFakeHandle.Name = "Handle"; rFakeHandle.Parent = tool
                rFakeHandle.Transparency = 1
                
                tool.Parent = Character
                
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
                realhandle.Transparency = 0
                local rFakeHandle = realhandle:Clone(); rFakeHandle.Parent = tool; rFakeHandle.Name = "RightFakeHandle"; rFakeHandle.Transparency = 1; rFakeHandle.CanCollide = false; rFakeHandle.Massless = true
                local rFakeGrip = Instance.new("Weld", Character["Right Arm"]); rFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); rFakeGrip.C1 = tool.Grip; rFakeGrip.Part1 = rFakeHandle; rFakeGrip.Part0 = ToolTrackR
                
                local lFakeHandle = realhandle:Clone(); lFakeHandle.Parent = tool; lFakeHandle.Name = "LeftFakeHandle"; lFakeHandle.Transparency = 1; lFakeHandle.CanCollide = false; lFakeHandle.Massless = true
                local lFakeGrip = Instance.new("Weld", Character["Left Arm"]); lFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); lFakeGrip.C1 = tool.Grip; lFakeGrip.Part1 = lFakeHandle; lFakeGrip.Part0 = ToolTrackL
                
                local rToolAtt, toolAP, toolAO = Utils:Align(realhandle, rFakeHandle, Vector3.new(), Vector3.new(), {reactionforce = true, resp = 70})
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
                tool.Parent = Character
    
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
        end
    end
    
    function holdPart(v, grabAtt, drop)
        if v:IsA("BasePart") and v.Anchored == false then
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
    Event(Character.ChildAdded:Connect(doTool))
    Event(LocalPlayer.Backpack.ChildAdded:Connect(doTool))
    
    --[Climbing & Touching]
    function getPointPart(hand, distance)
        local pointRay = Ray.new(hand.Position, -hand.CFrame.upVector.Unit * distance)
        local part, position, normal = Workspace:FindPartOnRayWithIgnoreList(pointRay, {VRCharacter, Character, CurrentCamera})
        return part, position, normal
    end
    
    --[Controls]
    local holdR
    local holdL
    Event(UserInputService.InputBegan:connect(function(key)
        if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
            local tool = getClosestTool(VirtualRightArm)
            local part = getPointPart(VirtualRightArm, 3)
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
            local part = getPointPart(VirtualLeftArm, 3)
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
            for _,tool in pairs(tools) do
                if tool.Hand == "Left" and tool.Handle then
                    tool.Handle.Parent:Activate()
                    print("Left")
                end
            end
        elseif key.KeyCode == Enum.KeyCode.ButtonR2 or key.UserInputType == Enum.UserInputType.MouseButton2 then
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

    --[UI]
    local UI = getModule('UI/Library')
    local window = UI:CreateWindow()
        local settingsTab = window:CreateTab()
            local movementMode = settingsTab:AddChoice("Movement Mode", {"None", "SmoothLocomotion"}, options.DefaultMovementMethod, function(mode)
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
    
    Event(RunService.RenderStepped:Connect(function()
        local VRInputs =  VRInputService:GetVRInputs()
        local CameraCenterCFrame = Workspace.CurrentCamera:GetRenderCFrame() * VRInputs[Enum.UserCFrame.Head]:Inverse()
        UIpart.CFrame = UIpart.CFrame:Lerp(CameraCenterCFrame * CFrame.new(0,0,5), .1)
    end))
    window.SurfaceGui.Enabled = false
    
    local UIEnabled = false
    Event(BindableEvent.Event:Connect(function(type)
        if type == "UI" then
            UIEnabled = not UIEnabled
            window.SurfaceGui.Enabled = UIEnabled
        end
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
        Humanoid.Health = 0
        VRCharacter.Humanoid.Health = 0 
        RunService:UnbindFromRenderStep("sauceVRCharacterModelUpdate")
        CurrentCamera.CameraType = "Custom"
        Event:Clear()
        task.delay(6, function()
            VRCharacter:Destroy()
        end)
    end
    
    Event(VRCharacter.Humanoid.Died:Connect(died))
    Event(Humanoid.Died:Connect(died))
end

StartVR()
