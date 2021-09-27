getgenv().options = {
    DefaultMovementMethod = "None",
    DefaultCameraOption = "Default",
    
    --Character Transparency in First Person
    LocalCharacterTransparency = 0.5,

    --Maximum angle the neck can turn before the torso turns.
    MaxNeckRotation = math.rad(35),
    MaxNeckSeatedRotation = math.rad(60),
    
    --Maximum angle the neck can tilt before the torso tilts.
    MaxNeckTilt = math.rad(60),
    
    --Maximum angle the center of the torso can bend.
    MaxTorsoBend = math.rad(10),
}


--repeat wait() until game:IsLoaded() and not _G.Executed
_G.Executed = true


--=========[Variables]
local Players = game:GetService("Players");     
local Lighting = game:GetService("Lighting");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ScriptContext = game:GetService("ScriptContext");
local VRService = game:GetService("VRService");
local VirtualUser = game:GetService("VirtualUser");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local HapticService = game:GetService("HapticService");
local UserInputService = game:GetService("UserInputService");
local CurrentCamera = workspace.CurrentCamera;
local LocalPlayer = game.Players.LocalPlayer;

--[Physics/Network Settings]
settings().Physics.AllowSleep = false 
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled



--=========[Modules]
function getModule(module)
    assert(type(module) == "string", "string only")
    local path = "https://raw.githubusercontent.com/saucekid/sauceVR/main/modules/"
    local module =  loadstring(game:HttpGetAsync(path.. module.. ".lua"))()
    return module
end

local Event = getModule("Event")
local Utils = getModule("Utils")

--[Services]
getgenv().CameraService = getModule("Services/CameraService");
getgenv().ControlService = getModule("Services/ControlService");
getgenv().VRInputService = getModule("Services/VRInputService");

--=========[VR script]
local function cframeAlign(a, b, pos)
    local Motor = Utils:GetMotorForLimb(a); if Motor then Motor:Destroy() end
    Event(RunService.Heartbeat:Connect(function()
        a.CFrame = pos and b.CFrame * pos or b.CFrame
    end))
    Event(RunService.Stepped:Connect(function()
        a.CFrame = pos and b.CFrame * pos or b.CFrame
    end))
end

local function align(a, b, pos, rot, settings)
    if typeof(settings) ~= 'table' then
        settings = {type = "None", resp = 200, length = 5, reactiontorque = false, reactionforce = false}
    end
    local a1
    local att0, att1 do
        att0 = a:IsA("Accessory") and Instance.new("Attachment", a.Handle) or Instance.new("Attachment", a)
        att1 = Instance.new("Attachment", b); 
        att1.Position = pos or Vector3.new(0,0,0); att1.Orientation = rot or Vector3.new(0,0,0);
    end
    
    local Handle = a:IsA("Accessory") and a.Handle or a;
    Handle.Massless = true;
    Handle.CanCollide = false;
    
    if a:IsA("Accessory") then Handle.AccessoryWeld:Destroy()  Handle:FindFirstChildOfClass("SpecialMesh"):Destroy()end
    local Motor = Utils:GetMotorForLimb(a); if Motor then Motor:Destroy() end
    
    if settings.type == "rope" then 
        att0.Position = rot
        al = Instance.new("RopeConstraint", Handle);
        al.Attachment0 = att0; al.Attachment1 = att1;
        al.Length = settings.length or 0.5
    elseif settings.type == "ball" then
        att0.Position = rot
        al = Instance.new("BallSocketConstraint", Handle)
        al.Attachment0 = att0
        al.Attachment1 = att1
        al.Restitution = 1
        al.LimitsEnabled = true
        al.MaxFrictionTorque = 10
        al.TwistLimitsEnabled = true
        al.UpperAngle = 50
        al.TwistLowerAngle = 10
        al.TwistUpperAngle = -100
    elseif settings.type == "hinge" then
        att0.Position = rot
        al = Instance.new("HingeConstraint", Handle)
        al.Attachment0 = att0
        al.Attachment1 = att1
    else
        al = Instance.new("AlignPosition", Handle);
        al.Attachment0 = att0; al.Attachment1 = att1;
        al.RigidityEnabled = true;
        al.ReactionForceEnabled = settings.reactionforce or false;
        al.ApplyAtCenterOfMass = true;
        al.MaxForce = 10000000;
        al.MaxVelocity = math.huge/9e110;
        al.Responsiveness = options.resp or 200;
        local ao = Instance.new("AlignOrientation", Handle);    
        ao.Attachment0 = att0; ao.Attachment1 = att1;
        ao.RigidityEnabled = false;
        ao.ReactionTorqueEnabled = settings.reactiontorque or true;
        ao.PrimaryAxisOnly = false;
        ao.MaxTorque = 10000000;
        ao.MaxAngularVelocity = math.huge/9e110;
        ao.Responsiveness = 200;
    end
    return att1, a1
end

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

        getgenv().VRCharacter = Utils:VRCharacter(Character, 1)
        
        local Weld = Instance.new("Motor6D")
        Weld.Part0 = Humanoid.RootPart
        Weld.Part1 = VRCharacter.Humanoid.RootPart
        Weld.Parent = VRCharacter.Humanoid.RootPart
    
        VRCharacter.Humanoid.AutoRotate = false
        VRCharacter.Humanoid.PlatformStand = true
    end
    
    if RigType == "R15" then
        local CharacterHandler = getModule("Character/Character").new(VRCharacter)
        CharacterHandler.Humanoid = Humanoid
        
        ControlService:UpdateCharacterReference(CharacterHandler)
        ControlService:SetActiveController("SmoothLocomotion")
       -- CameraService:SetActiveCamera("Default")

        RunService:BindToRenderStep("sauceVRCharacterModelUpdate",Enum.RenderPriority.Camera.Value - 1,function()
            ControlService:UpdateCharacter()
        end)
        
    elseif RigType == "R6" then
        
    end
    
    local DisabledParts = {}
    DisabledParts["HumanoidRootPart"] = true
    DisabledParts["Head"] = options.HeadMovement and false or true
    
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            Event(RunService.Stepped:connect(function()
                part.CanCollide = false
                VRCharacter:FindFirstChild(part.Name)
            end))
            
            if not DisabledParts[part.Name] then
                cframeAlign(part, VRCharacter:FindFirstChild(part.Name))

                local bv = Instance.new("BodyVelocity", part)
                bv.Velocity = Vector3.new(0,0,0)
                bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                bv.P = 10000
                
                Event(RunService.Heartbeat:connect(function()
                    part.AssemblyLinearVelocity = Vector3.new(0,0,0)
                end))
            end
        end
    end
    

    function doTool(tool)
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") and not tool:FindFirstChild("Done") then
            local realhandle = tool:FindFirstChild("Handle")
            realhandle.Massless = true
            RunService.Heartbeat:Connect(function()
                realhandle.Velocity = Vector3.new(45,0,0)
            end)
            local tag = Instance.new("StringValue", tool); tag.Name = "Done"
            if RigType == "R15" then
                realhandle.Name = "RealHandle"
                local bv = Instance.new("BodyVelocity", realhandle)
                bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.P = 9000; bv.Name = "Jitterless"
                local fakehandle = realhandle:Clone(); fakehandle.Parent = tool; fakehandle.Name = "Handle"
                fakehandle.Transparency = 1
                RunService.Stepped:Connect(function()
                    realhandle.CanCollide = false
                    realhandle.CFrame = fakehandle.CFrame
                end)
            else
                local fakehandle = realhandle:Clone(); fakehandle.Parent = tool; fakehandle.Name = "FakeHandle"; fakehandle.Transparency = 1; fakehandle.CanCollide = false
                local fakegrip = Instance.new("Weld", rhand); fakegrip.C0 = CFrame.new(0, -1, 0, 1, 0, -0, 0, 0, 1, 0, -1, -0); fakegrip.C1 = tool.Grip; fakegrip.Part1 = fakehandle; fakegrip.Part0 = ToolTrack
                local toolAtt = align(realhandle, ToolTrack, Vector3.new(), Vector3.new(), {reactiontorque = false, resp = 70})
                toolAtt.WorldCFrame = fakehandle.CFrame
                RunService.Stepped:Connect(function()
                    realhandle.CanCollide = false
                end)
            end
            wait()
            tool.Parent = LocalPlayer.Backpack
        end
    end
    
    if not R15 and rightarm:FindFirstChild("RightGrip") then rightarm.RightGrip:Destroy() end
    for i,tool in pairs(Character:GetChildren()) do
        task.spawn(doTool, tool)
    end
    Character.ChildAdded:Connect(doTool)


    --[Death]
    function died()
        Humanoid.Health = 0
        VRCharacter.Humanoid.Health = 0 
        Humanoid:Destroy() --stop perm death
        task.delay(6, function()
            VRCharacter:Destroy()
            Event:Clear()
        end)
    end
    
    local resetBindable = Instance.new("BindableEvent")
    resetBindable.Event:connect(died)
    
    game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
    VRCharacter.Humanoid.Died:Connect(died)
    Humanoid.Died:Connect(died)
end

StartVR()