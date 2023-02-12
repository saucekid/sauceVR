local sauceVR = script:FindFirstAncestor("sauceVR")

local Players = game:GetService("Players")  
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

local VRReady = UserInputService.VREnabled
local diedFunc
local propMenu

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
        [1] = CFrame.new(-1,-.5,0) * CFrame.Angles(0,math.rad(0),0),
        [2] = CFrame.new(1,-.5,0) * CFrame.Angles(0,math.rad(90),0),
        [3] = CFrame.new(-.5,0,.5) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(90)),
        [4] = CFrame.new(.5,0,.5) * CFrame.Angles(0,math.rad(90),0)
    },
    NetlessVelocity = Vector3.new(0,-45,0)
}

--Disable default VR controls.
ContextActionService:BindActionAtPriority("DisableInventoryKeys", function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

--Disable the native VR controller models.
StarterGui:SetCore("VREnableControllerModels", false)
DefaultCursorService:SetCursorState("Detect")

--Enable bubble chat if disabled.
game.Chat.BubbleChatEnabled = true

--.Chatted fix by Stefanuk12
require(sauceVR.Util.FixChatted)

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
    "BodyMover",
    "VectorForce"
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
        local Character, Humanoid, RigType, VRCharacter, renderCharacter do
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Humanoid = Utils.WaitForChildOfClass(Character, "Humanoid")
            RigType = Humanoid.RigType.Name

            --Wait for player to be on ground
            repeat task.wait() until Humanoid.FloorMaterial ~= Enum.Material.Air 

            --Stop all animations
            local Animate = Character:FindFirstChild("Animate")
            if Animate then
                Animate:Destroy()
            end

            for _,anim in pairs(Humanoid:GetPlayingAnimationTracks()) do
                anim:Stop()
            end

            for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") then 
                    task.spawn(function() 
                        tool.Parent = Character 
                        task.wait(.1)
                        tool.Parent = LocalPlayer.Backpack
                    end) 
                end
            end

            --Create a client sided character that handles joints
            if RigType == "R15" then
                VRCharacter = Utils:VRCharacter(Character, 1)
            else
                Character.Archivable = true

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
            
            --Create a client sided character which will have no delay (Original character's alignment is delayed giving me a headache)
            renderCharacter = Character:Clone()
            for _,part in pairs(renderCharacter:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == "Head" then
                    part:Destroy()
                elseif not part:IsA("BasePart") and not part:IsA("Humanoid") and not part:IsA("Clothing") and not part:IsA("Decal") and not part:IsA("SurfaceAppearance")  then
                    part:Destroy()
                end
            end

            --Permanent death if headmovement is turned on.
            if options.HeadMovement then
                Humanoid.RootPart.Anchored = true
                Utils:loadingScreen(Players.RespawnTime)
                Utils:permaDeath(Character)
                Humanoid.RootPart.Anchored = false

                --Reweld hats in case unwelded
                --[[
                task.delay(0.5, function()
                    for _,hat in pairs(Character:GetChildren()) do
                        if hat:IsA("Accessory") then
                            task.spawn(function()
                                for i = 1,3 do
                                    sethiddenproperty(hat, "BackendAccoutrementState", 3) 
                                    for i,att in pairs(hat.Handle:GetChildren()) do
                                        if att:IsA("Attachment") then att:Destroy() end 
                                    end
                                    task.wait()
                                end
                            end)
                        end
                    end
                end)
                ]]
            else
                options.MaxNeckRotation = math.rad(0)
                options.MaxNeckSeatedRotation = math.rad(0)
                options.MaxNeckTilt = math.rad(0)
                options.MaxTorsoBend = math.rad(0)
            end

            renderCharacter.Parent = VRCharacter

            --Align RootParts
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
                ap.RigidityEnabled = false; ap.ReactionForceEnabled = true; ap.ApplyAtCenterOfMass = false; ap.MaxForce = 100000000; ap.MaxVelocity = math.huge/9e110; ap.Responsiveness = 200; ap.Parent = arm
                local ao = Instance.new("AlignOrientation");
                ao.RigidityEnabled = false; ao.ReactionTorqueEnabled = false; ao.PrimaryAxisOnly = false; ao.MaxTorque = 100000000; ao.MaxAngularVelocity = math.huge/9e110; ao.Responsiveness = 200; ao.Parent = arm
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
                    task.wait(.1)
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
                end
            end))
            
            Event(VirtualLeftArm.Touched:Connect(function(part)
                if VirtualLeftArm:CanCollideWith(part) and not part:IsDescendantOf(Character) and not part:IsDescendantOf(VRCharacter) then
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, (VirtualLeftArm.Velocity - part.Velocity).Magnitude / 10)
                    task.wait(.1)
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
                end
            end))
        end
        
        --Update VR Character
        local VirtualCharacter do
            VirtualCharacter = require(sauceVR.Components.Character.Character).new(VRCharacter)
            VirtualCharacter.Humanoid = Humanoid
            VirtualCharacter.Parts.HumanoidRootPart = Humanoid.RootPart

            VirtualCharacter.RealCharacter = Character
            VirtualCharacter.RenderCharacter = renderCharacter

            VirtualCharacter.RigType = RigType

            VirtualCharacter.PhysicalLeftHand = VirtualLeftArm
            VirtualCharacter.PhysicalRightHand = VirtualRightArm

            VirtualCharacter.Aligns = {}
            VirtualCharacter.Accessories = {}
            
            ControlService:UpdateCharacterReference(VirtualCharacter)

            CameraService:SetActiveCamera(options.DefaultCameraOption)

            
            RunService:BindToRenderStep("sauceVRCharacterModelUpdate",Enum.RenderPriority.Camera.Value - 1,function()
                ControlService:UpdateCharacter()
                RHA.WorldCFrame = VRCharacter["RightHand"].CFrame 
                LHA.WorldCFrame = VRCharacter["LeftHand"].CFrame
            end)
        end

        Humanoid.RootPart.Anchored = false

        --Replicate parts.
        local Netless = require(sauceVR.Util.Netless)

        local disabledParts, R6Parts = {
            ["HumanoidRootPart"] = true,
            ["Fake Right"] = true,
            ["Fake Left"] = true,
            ["Head"] = not options.HeadMovement
        }, {
            ["Torso"] = {Align = VRCharacter["UpperTorso"], Offset = Vector3.new(0,-.4,0)},
            ["Left Leg"] = {Align = VRCharacter["LeftLowerLeg"], Offset = Vector3.new(0,0,0)},
            ["Right Leg"] = {Align = VRCharacter["RightLowerLeg"], Offset = Vector3.new(0,0,0)},
            ["Left Arm"] = {Align = VirtualLeftArm, Offset = Vector3.new(0,.6,0)},
            ["Right Arm"] = {Align = VirtualRightArm, Offset = Vector3.new(0,.6,0)},
            ["Head"] = {Align = VRCharacter["Head"], Offset = Vector3.new(0,-.2,0)},
        }

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
            if part:IsA("Decal") and part.Parent.Name ~= "Head" then
                part.Transparency = 1
            end

            if part:IsA("BasePart") and not part.Parent:IsA("Tool") and not part.Parent:IsA("Accessory") then
                VRCollision(part)
                
                local renderPart = renderCharacter:FindFirstChild(part.Name)

                if renderPart then
                    renderPart.LocalTransparencyModifier = part.LocalTransparencyModifier
                    Event(RunService.RenderStepped:Connect(function()
                        if (part.Position - renderPart.Position).Magnitude > 20 then
                            renderPart:Destroy()
                        end
                        renderPart.LocalTransparencyModifier = part.LocalTransparencyModifier
                    end))

                    Event(Character.DescendantRemoving:Connect(function(removed)
                        if removed == part then
                            renderPart:Destroy()
                        end
                    end))
                end

                Event(part.Touched:Connect(function(seat)
                    if seat:IsA("Seat") then
                        print("seat")
                        seat:Sit(Humanoid)
                    end
                end))

                if not disabledParts[part.Name] then
                    local partAlign

                    if RigType == "R15" then
                        if part.Name ~= "Head" then
                            part.Transparency = 1
                            Utils:cframeAlign(renderPart, VRCharacter:FindFirstChild(part.Name), CFrame.new(0,0,0), "RenderStepped")
                        end

                        partAlign = Netless:align(part, VRCharacter:FindFirstChild(part.Name))
                    else
                        if R6Parts[part.Name] then
                            if part.Name ~= "Head" then
                                part.Transparency = 1
                                Utils:cframeAlign(renderPart, R6Parts[part.Name].Align, CFrame.new(R6Parts[part.Name].Offset), "RenderStepped")
                            end
                            
                            partAlign = Netless:align(part, R6Parts[part.Name].Align, R6Parts[part.Name].Offset, true)
                        end
                    end

                    if partAlign then
                        function partAlign.Reset()
                            if Character and Humanoid and part then
                                local vrPart = RigType == "R15" and VRCharacter:FindFirstChild(part.Name) or R6Parts[part.Name].Align
                                partAlign.offset = RigType == "R15" and Vector3.new(0,0,0) or R6Parts[part.Name].Offset
                                partAlign.Part1 = vrPart
                            end
                        end

                        VirtualCharacter.Aligns[part.Name] = partAlign
                    end
                end
            elseif part.Name == "Handle" and part.Parent:IsA("Accessory") then

                local hatClone = part.Parent:Clone()
                hatClone.Parent = workspace
                
                local renderPart = hatClone.Handle
                renderPart.Transparency = 1
                
                for _, pe in pairs(renderPart:GetDescendants()) do
                    if pe:IsA("ParticleEmitter") then
                        pe:Destroy()
                    end
                end

                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Parent = renderPart
    
                if renderPart then
                    Event(RunService.RenderStepped:Connect(function()
                        renderPart.LocalTransparencyModifier = part.LocalTransparencyModifier
                    end))

                    Event(Character.DescendantRemoving:Connect(function(removed)
                        if removed == part then
                            renderPart:Destroy()
                        end
                    end))
                end
                
                part.AccessoryWeld:Destroy()

                local partAlign = Netless:align(part, renderPart)
                partAlign.Handle = part
                partAlign.Name = part.Parent.Name

                function partAlign.Reset()
                    if Character and Humanoid and part then
                        partAlign.offset = Vector3.new(0,0,0) 
                        partAlign.Part1 = renderPart
                    end
                end
                
                VirtualCharacter.Accessories[part.Parent.Name] = partAlign
            end
        end


        --Set up prop menu
        propMenu = Library:createPropMenu(VirtualCharacter.Accessories) 
        propMenu.propCreated = function(align)
            local physics = align.Physics
            local propPart = align.Handle:Clone()
            propPart.Name = "Prop"
            propPart.Anchored = not physics
            propPart.CanCollide = true
            propPart.Transparency = 0
            propPart.LocalTransparencyModifier = 0
            propPart.Parent = align.Handle.Parent

            VRCollision(propPart)

            local propHighlight = Instance.new("Highlight")
            propHighlight.FillTransparency = 1
            propHighlight.Parent = propPart

            local holding = false
            local offset = Humanoid.RootPart.CFrame * CFrame.new(0,0,-3)
            Event(RunService.RenderStepped:Connect(function()
                if not physics or holding then
                    propPart.CFrame = offset
                end
            end))

            
            Event(UserInputService.InputBegan:connect(function(key)
                if holding or not propPart then return end
                if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
                    if (VirtualRightArm.Position - propPart.Position).Magnitude < 1 then
                        local start = propPart.CFrame:ToObjectSpace(VirtualRightArm.CFrame)
                        holding = true

                        repeat task.wait()
                            offset = (VirtualRightArm.CFrame * start)
                        until not holding
                    end
                elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
                    if (VirtualLeftArm.Position - propPart.Position).Magnitude < 1 then
                        local start = propPart.CFrame:ToObjectSpace(VirtualLeftArm.CFrame)
                        holding = true

                        repeat task.wait()
                            offset = (VirtualLeftArm.CFrame * start)
                        until not holding
                    end
                end
            end))

            Event(UserInputService.InputEnded:connect(function(key)
                if key.KeyCode == Enum.KeyCode.ButtonR1 or key.KeyCode == Enum.KeyCode.E then
                    holding = false
                elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
                    holding = false
                end
            end))

            align.Part1 = propPart
        end

        propMenu.propRemoved = function(align)
            local propPart = align.Handle.Parent:FindFirstChild("Prop")
            if propPart then
                propPart:Destroy()
            end
            align.Reset()
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
                    ToolTrackR.CFrame = VirtualRightArm.CFrame  * CFrame.Angles(math.rad(0),0,0) * CFrame.new(0,1,0)
                    ToolTrackL.CFrame = VirtualLeftArm.CFrame * CFrame.Angles(math.rad(0),0,0) * CFrame.new(0,1,0) 
                end))
            end
        end
        

        function doTool(tool)
            task.wait()
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") and not tool:GetAttribute("Done") then
                tool:SetAttribute("Done", true)
                tool.ManualActivationOnly = true

                local realhandle = tool:FindFirstChild("Handle")
                realhandle.Massless = true
                realhandle.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0,0)

                repeat task.wait()
                    realhandle.CFrame = Humanoid.RootPart.CFrame
                until (realhandle.Position -  Humanoid.RootPart.Position).Magnitude < 5
                tool.Parent = Character

                local toolnum = #tools + 1
                local slot = options.InventorySlots[toolnum]
                tools[toolnum] = {Handle = realhandle, Hand = false}
                
                if not slot then return end
                
                local toolAlign, lFakeHandle, rFakeHandle
                if RigType == "R15" then
                    realhandle.Name = "RealHandle"
                    
                    lFakeHandle = realhandle:Clone(); lFakeHandle.Massless = true; lFakeHandle.Name = "LeftHandle"; lFakeHandle.Parent = tool; lFakeHandle.Transparency = 1
                    rFakeHandle = realhandle:Clone(); rFakeHandle.Massless = true; rFakeHandle.Name = "Handle"; rFakeHandle.Parent = tool; rFakeHandle.Transparency = 1
                     
                    local rightGrip = Character.RightHand["RightGrip"]
                    if Character["RightHand"]:FindFirstChild("RightGrip") then Character["RightHand"].RightGrip:Destroy() end   
                    local rGrip = rightGrip:Clone(); rGrip.Part0 = VRCharacter.RightHand; rGrip.Part1 = rFakeHandle; rGrip.Parent = VRCharacter.RightHand; rGrip.C0 = rightGrip.C0;
                    local lGrip = rightGrip:Clone(); lGrip.Part0 = VRCharacter.LeftHand; lGrip.Name = "LeftGrip"; lGrip.Part1 = lFakeHandle; lGrip.Parent = VRCharacter.LeftHand; lGrip.C0 = rightGrip.C0;

                    rightGrip:Destroy()
                    Character.RightHand:ClearAllChildren()

                    toolAlign = Netless:align(realhandle, VRCharacter["UpperTorso"], slot)
                else

                    if Character["Right Arm"]:FindFirstChild("RightGrip") then Character["Right Arm"].RightGrip:Destroy() end         
                    rFakeHandle = realhandle:Clone(); rFakeHandle.Parent = tool; rFakeHandle.Name = "RightFakeHandle"; rFakeHandle.Transparency = 1; rFakeHandle.CanCollide = false; rFakeHandle.Massless = true
                    lFakeHandle = realhandle:Clone(); lFakeHandle.Parent = tool; lFakeHandle.Name = "LeftFakeHandle"; lFakeHandle.Transparency = 1; lFakeHandle.CanCollide = false; lFakeHandle.Massless = true
                    
                    local rFakeGrip = Instance.new("Weld", ToolTrackR); rFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); rFakeGrip.C1 = tool.Grip; rFakeGrip.Part1 = rFakeHandle; rFakeGrip.Part0 = ToolTrackR
                    local lFakeGrip = Instance.new("Weld", ToolTrackL); lFakeGrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); lFakeGrip.C1 = tool.Grip; lFakeGrip.Part1 = lFakeHandle; lFakeGrip.Part0 = ToolTrackL
                    
                    toolAlign = Netless:align(realhandle, VRCharacter["UpperTorso"], slot)
                end

                tools[toolnum].Hold = function(hold, hand)
                    if hold then
                        tools[toolnum].Hand = hand
                        toolAlign.Part1 = hand == "Left" and lFakeHandle or rFakeHandle
                        toolAlign.offset = CFrame.new(0,0,0)
                    else
                        tools[toolnum].Hand = false
                        toolAlign.Part1 = VRCharacter["UpperTorso"]
                        toolAlign.offset = slot
                    end
                end

                Event(RunService.Stepped:Connect(function()
                    realhandle.CanCollide = true
                end))



                Utils:NoCollideModel(tool, Character)
                Utils:NoCollideModel(tool, VRCharacter)
            end
        end

        

        if RigType == "R6" and Character["Right Arm"]:FindFirstChild("RightGrip") then Character["Right Arm"].RightGrip:Destroy() end
        for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            doTool(tool)
        end

        Event(Character.ChildAdded:Connect(doTool))
        Event(LocalPlayer.Backpack.ChildAdded:Connect(doTool))

        --Unanchored parts holding.
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
                        ControlService.CurrentController.ClimbingRight = true
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
                        ControlService.CurrentController.ClimbingLeft = true
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
                ControlService.CurrentController.ClimbingRight = false
                pcall(holdPart, holdR, nil, true)
                for _,tool in pairs(tools) do
                    if tool.Hand == "Right" then
                        tool.Hold(false)
                    end
                end
            elseif key.KeyCode == Enum.KeyCode.ButtonL1 or key.KeyCode == Enum.KeyCode.Q then
                lGrabWeld.Part1 = nil
                ControlService.CurrentController.ClimbingLeft = false
                pcall(holdPart, holdL, nil, true)
                for _,tool in pairs(tools) do
                    if tool.Hand == "Left" then
                        tool.Hold(false)
                    end
                end
            end
        end))
        
        --Handle teleporting.
        local oldpos = Humanoid.RootPart.Position; Event(Humanoid.RootPart:GetPropertyChangedSignal("Position"):Connect(function()
            if Humanoid and Humanoid.RootPart then
                if oldpos and (oldpos - Humanoid.RootPart.Position).Magnitude > 10 then
                    rGrabWeld.Part1 = nil
                    lGrabWeld.Part1 = nil
                    VirtualLeftArm.CFrame = Humanoid.RootPart.CFrame
                    VirtualRightArm.CFrame = Humanoid.RootPart.CFrame
                end
                oldpos = Humanoid.RootPart.Position
            end
        end))

        --Reset character when death.
        diedFunc = function()
            diedFunc = nil

            RunService:UnbindFromRenderStep("sauceVRCharacterModelUpdate")

            Character:BreakJoints()

            propMenu:Destroy()

            for i,v in pairs(Character:GetDescendants()) do
                if v:IsA("BodyVelocity") or v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
                    v:Destroy()
                elseif v:IsA("Humanoid") and (options.HeadMovement or v.Health == 0) then
                    v:Destroy()
                end
            end

            if CameraService.CurrentCamera then
                CameraService.CurrentCamera:Disable()
            end


            CurrentCamera.CameraType = "Custom"

            Event:Clear()
            Utils:ClearCache()
            VRCharacter:Destroy()

            task.delay(Players.RespawnTime + 1, function()
                LoadCharacter()
            end)
        end

        local resetBindable = Instance.new("BindableEvent") do
            Event(Character.DescendantRemoving:Connect(function(removed)
                if removed.Name == "HumanoidRootPart" then
                    diedFunc()
                end
            end))
            Event(Humanoid.Died:Connect(diedFunc))
            Event(resetBindable.Event:connect(diedFunc))
            StarterGui:SetCore("ResetButtonCallback", resetBindable)
        end

        --Load Camera and Controller
        ControlService:SetActiveController("None")
        ControlService:SetActiveController(options.DefaultMovementMethod)

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
                if v:IsA("BasePart") and not (v.Name:find("Fake") and v.Parent == Character) then
                    if ControlService.ActiveController == "Gorilla" and v.Name == "HumanoidRootPart" then
                        v.CanCollide = true
                    else
                        v.CanCollide = false
                    end
                end
            end))
        end
    end

    --Prompt head movement.
    Library:CreatePrompt("Enable Head Movement?", "This will permanently kill your character and may break some functions in-game", {"No", "Yes"}, function(response) 
        if response == "Yes" then
            options.HeadMovement = true
        else
            options.HeadMovement = false
        end
    end)
    
    --Set up Keyboard.
    Keyboard:Init()

    --Set up VR Menu.

    local optionsMenu = Library:CreateMenu("Options") do
        local generalTab = optionsMenu:AddTab("General", "rbxassetid://10675474985")
            generalTab:AddSelectButton("Movement", options.DefaultMovementMethod, {"None", "SmoothLocomotion", "TeleportController", "GorillaLocomotion"}, function(mode) 
                ControlService:SetActiveController(mode)
            end)

            generalTab:AddSelectButton("VR Cursor", "Detect", {"Detect", "Enabled", "Disabled"}, function(mode) 
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
                    task.wait()
                    game:GetService('TeleportService'):Teleport(game.PlaceId, LocalPlayer)
                else
                    game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end)

        local bodyTab = optionsMenu:AddTab("Body", "rbxassetid://10653366793")
            bodyTab:AddSelectButton("Head Movement", options.HeadMovement == true and "Enabled" or "Disabled", {"Enabled", "Disabled"}, function(b)
                optionsMenu:SetEnabled(false)
                
                local cancel = false
                Library:CreatePrompt("Respawn?", "This option requires you to respawn your character for changes to take place.", {"Cancel", "Ok"}, function(response) 
                    if response == "Ok" then
                        options.HeadMovement = b == "Enabled" and true or false 
                        task.spawn(diedFunc)
                    else
                        cancel = true
                    end
                end)

                return cancel
            end)

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

        buttonGroup:AddButton("Props", "rbxassetid://12403104094", function() 
            propMenu:SetEnabled(true) 
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
            if CameraService.ActiveCamera == "Default" then
                CameraService:SetActiveCamera("ThirdPersonTrack")
            elseif CameraService.ActiveCamera == "ThirdPersonTrack" then
                CameraService:SetActiveCamera("Mirror")
            else
                CameraService:SetActiveCamera("Default")
            end
            Library:ToolTip(CameraService.ActiveCamera, 1)
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


    if not VRReady then 
        UserInputService.InputBegan:connect(function(key)
            if key.KeyCode == Enum.KeyCode.M then
                buttonGroup:SetEnabled(not buttonGroup.Enabled)
            end
        end)
    else
        buttonGroup:SetUpOpening()
    end

    --Load Huds.
    local viewHUD, chatHUD = require(sauceVR.Components.UI.HUDs.Viewport), require(sauceVR.Components.UI.HUDs.Chat)

    task.spawn(viewHUD)
    task.spawn(chatHUD)

    --Load Character.
    LoadCharacter()

    Library:ToolTip("Face both hands towards the floor to toggle the menu", 4)
end

return Init