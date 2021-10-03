--[[

              ████      ████                
            ████████████████████            
          ████████████████████████          
        ████████████████████████████        
        ████████████████████████████        
      ████████████████████████████████      
      ██▒▒▒▒▒▒▒▒██████████████▒▒▒▒████      
      ██▒▒▒▒▒▒▒▒▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒██      
    ▒▒██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▒▒    
    ▒▒██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    
    ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██    
    ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██    
    ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████    
    ██████████▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒████████    
      ████████▒▒▒▒░░░░░░░░░░▒▒▒▒████████    
      ██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████      
          ██████████▒▒▒▒▒▒██████████        
        ████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████      
        ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████      
      ████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████    
    ██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████  
  ██████████  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ████████  
  ████████  ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██  ██████████
██████████  ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██  ██████████
██████████   ███▒▒▒▒▒▒▒▒▒▒▒▒███   ██████████
▒▒▒▒████▒▒    ████████████████    ▒▒██████▒▒
▒▒▒▒▒▒▒▒▒▒                        ▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒                          ▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒                            ▒▒▒▒▒▒▒▒
]]--
 
options.Hands = false          -- If you want hands in R6 (You need hats)
 options.RightHand = "Racing Helmet Flames"
 options.LeftHand = "Racing Helmet USA"

if getgenv and not getgenv().options then
    getgenv().options = options
end

--=========[Variables]==========--
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
local CurrentCamera = workspace.CurrentCamera
local sethiddenprop = (sethiddenproperty or set_hidden_property or sethiddenprop or set_hidden_prop);
local setsimulationrad = setsimulationradius or set_simulation_radius or function(Radius) sethiddenprop(PlayerInstance, "SimulationRadius", Radius) end

local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local hum = Character:FindFirstChildOfClass("Humanoid");
local root = hum.RootPart;
local startCF = root.CFrame

local VRReady = UserInputService.VREnabled;
local R15 = hum.RigType == Enum.HumanoidRigType.R15 and true or false

for i,v in pairs(Character:GetChildren()) do
    for _, connection in pairs(getconnections(v.ChildAdded)) do
        connection:Disable()
    end
end

--[Tools Fix]
for i,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
    if tool:IsA("Tool") then tool.Parent = Character end
end

--[Anti Kick]
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
    local args = {...} 
    if getnamecallmethod() == 'Kick' then 
        return false
    end
    return OldNamecall(Self, unpack(args))
end)

--[Net]
settings().Physics.AllowSleep = false 
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled

--[Execute when rejoin]
LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.InProgress and syn then
        syn.queue_on_teleport([[
            repeat wait() until game:IsLoaded() and game.Players.LocalPlayer.Character
            Wait(1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/saucekid/sauceVR/main/extra/ROrilla.lua"))()
        ]])
    end
end)

--=========[Functions]==========--
local function Motor6D(part0, part1, c0, c1, name)
    part1.Transparency = 1;
    part1.Massless = true
    local motor = Instance.new("Motor6D", part1); motor.Name = name; motor.Part0 = part0; motor.Part1 = part1; motor.C0 = c0; motor.C1 = c1;
    return motor, motor.C0
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function solveIK(originCF, targetPos, l1, l2)	
	local localized = originCF:pointToObjectSpace(targetPos)
	local localizedUnit = localized.unit
	local l3 = localized.magnitude
	local axis = Vector3.new(0, 0, -1):Cross(localizedUnit)
	local angle = math.acos(-localizedUnit.Z)
	local planeCF = originCF * CFrame.fromAxisAngle(axis, angle)
	if l3 < math.max(l2, l1) - math.min(l2, l1) then
		return planeCF * CFrame.new(0, 0,  math.max(l2, l1) - math.min(l2, l1) - l3), -math.pi/2, math.pi
	elseif l3 > l1 + l2 then
		return planeCF, math.pi/2, 0
	else
		local a1 = -math.acos((-(l2 * l2) + (l1 * l1) + (l3 * l3)) / (2 * l1 * l3))
		local a2 = math.acos(((l2  * l2) - (l1 * l1) + (l3 * l3)) / (2 * l2 * l3))
		return planeCF, a1 + math.pi/2, a2 - a1
	end
end

local function GetMotorForLimb(Limb)
	for _, Motor in next, Character:GetDescendants() do
		if Motor:IsA("Motor6D") and Motor.Part1 == Limb then
			return Motor
		end
	end
end

local function cframeAlign(a, b, pos)
    local Motor = GetMotorForLimb(a); if Motor then Motor:Destroy() end
    RunService.Stepped:Connect(function()
        a.CFrame = pos and b.CFrame * pos or b.CFrame
    end)
end

local function align(a, b, pos, rot, options)
    if typeof(options) ~= 'table' then
        options = {type = "None", resp = 200, length = 5, reactiontorque = false, reactionforce = false}
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
    local Motor = GetMotorForLimb(a); if Motor then Motor:Destroy() end
    
    if options.type == "rope" then 
        att0.Position = rot
        al = Instance.new("RopeConstraint", Handle);
        al.Attachment0 = att0; al.Attachment1 = att1;
        al.Length = options.length or 0.5
    elseif options.type == "ball" then
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
    elseif type == "hinge" then
        att0.Position = rot
        al = Instance.new("HingeConstraint", Handle)
        al.Attachment0 = att0
        al.Attachment1 = att1
    else
        al = Instance.new("AlignPosition", Handle);
        al.Attachment0 = att0; al.Attachment1 = att1;
        al.RigidityEnabled = true;
        al.ReactionForceEnabled = options.reactionforce or false;
        al.ApplyAtCenterOfMass = true;
        al.MaxForce = 10000000;
        al.MaxVelocity = math.huge/9e110;
        al.Responsiveness = options.resp or 200;
        local ao = Instance.new("AlignOrientation", Handle);    
        ao.Attachment0 = att0; ao.Attachment1 = att1;
        ao.RigidityEnabled = true;
        ao.ReactionTorqueEnabled = options.reactiontorque or true;
        ao.PrimaryAxisOnly = false;
        ao.MaxTorque = 10000000;
        ao.MaxAngularVelocity = math.huge/9e110;
        ao.Responsiveness = 200;
    end
    return att1, a1
end

function alignHand(hand, pospart, rotpart, pos, rot)
    local Motor = GetMotorForLimb(hand); if Motor then Motor:Destroy() end
    
    local handatt = Instance.new("Attachment", hand)
    local posatt = Instance.new("Attachment", pospart)
    posatt.Position = pos or Vector3.new(0,0,0)
    local rotatt = Instance.new("Attachment", rotpart)
    rotatt.Orientation = rot or Vector3.new(0,0,0)
    
    local al = Instance.new("AlignPosition", hand);
    al.RigidityEnabled = true;
    al.ReactionForceEnabled = false;
    al.ApplyAtCenterOfMass = true;
    al.MaxForce = 10000000;
    al.MaxVelocity = math.huge/9e110;
    al.Responsiveness = resp or 200;
    local ao = Instance.new("AlignOrientation", hand);    
    ao.RigidityEnabled = false;
    ao.ReactionTorqueEnabled = true;
    ao.PrimaryAxisOnly = false;
    ao.MaxTorque = 10000000;
    ao.MaxAngularVelocity = math.huge/9e110;
    ao.Responsiveness = 200;
    
    al.Attachment0 = handatt
    al.Attachment1 = posatt
    
    ao.Attachment0 = handatt
    ao.Attachment1 = rotatt
end

local function holdPart(v, grabAtt, drop)
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

--=========[VR stuff]==========--
local vrparts, rhand, lhand, header, ToolTrack, HeadTrack, ratt, latt do
    vrparts = Instance.new("Folder", workspace); vrparts.Name = "VRParts"
    rhand = Instance.new("Part", vrparts); rhand.Anchored = true; rhand.CanCollide = false; rhand.Transparency = 1;
    ratt = Instance.new("Attachment", rhand);
    lhand = Instance.new("Part", vrparts); lhand.Anchored = true; lhand.CanCollide = false; lhand.Transparency = 1;
    latt = Instance.new("Attachment", lhand);
    header = Instance.new("Part", vrparts); header.Anchored = true; header.CanCollide = false; header.Transparency = 1;
    ToolTrack = Instance.new("Part", vrparts); ToolTrack.Anchored = true; ToolTrack.CanCollide = false; ToolTrack.Transparency = 1;
    HeadTrack = Instance.new("Part", vrparts); HeadTrack.Anchored = true; HeadTrack.CanCollide = false; HeadTrack.Transparency = 1;
    
    if VRReady then
        VRService.UserCFrameChanged:Connect(function()
            local LeftHandCFrame = VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
            local RightHandCFrame = VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
            local HeadCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
            rhand.CFrame = (CurrentCamera.CFrame*CFrame.new(RightHandCFrame.p*options.HeadScale))*CFrame.fromEulerAnglesXYZ(RightHandCFrame:ToEulerAnglesXYZ())*CFrame.Angles(math.rad(90), math.rad(90), math.rad(0))
            lhand.CFrame = (CurrentCamera.CFrame*CFrame.new(LeftHandCFrame.p*options.HeadScale))*CFrame.fromEulerAnglesXYZ(LeftHandCFrame:ToEulerAnglesXYZ())*CFrame.Angles(math.rad(90), math.rad(90), math.rad(0))
            header.CFrame = (CurrentCamera.CFrame*CFrame.new(HeadCFrame.p*options.HeadScale)) *CFrame.fromEulerAnglesXYZ(HeadCFrame:ToEulerAnglesXYZ())
            ToolTrack.CFrame = (CurrentCamera.CFrame*CFrame.new(RightHandCFrame.p*options.HeadScale))*CFrame.fromEulerAnglesXYZ(RightHandCFrame:ToEulerAnglesXYZ())*CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)) * CFrame.new(0,1,0)
        end)
    else
        RunService.RenderStepped:Connect(function()
            header.CFrame = CurrentCamera.CFrame
        end)
    end
end
    
--=========[Setting-Up]==========--
if options.BubbleChat then
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

--[Camera]
if VRReady then
    VRService:RecenterUserHeadCFrame();
    CurrentCamera.CameraType = "Scriptable";
    CurrentCamera.HeadScale = options.HeadScale;
    CurrentCamera.HeadLocked = true
    game:GetService("StarterGui"):SetCore("VRLaserPointerMode", 0);
    game:GetService("StarterGui"):SetCore("VREnableControllerModels", false);
end

hum.PlatformStand = true
wait()

--[Replicating]
local torso = R15 and Character["UpperTorso"] or Character["Torso"]
local rightarm = R15 and Character["RightHand"] or Character["Right Arm"]
local leftarm = R15 and Character["LeftHand"] or Character["Left Arm"]
local rightleg = R15 and Character["RightUpperLeg"] or Character:FindFirstChild("Right Leg")
local leftleg = R15 and Character["LeftUpperLeg"] or Character:FindFirstChild("Left Leg")
local motor = Character:FindFirstChild("LowerTorso") and Character.UpperTorso:FindFirstChild("LowerTorso") or GetMotorForLimb(root) if motor then motor:Destroy() end

local RUA, RLA, LUA, LLA, RH, LH = Instance.new("Part", Character), Instance.new("Part", Character), Instance.new("Part", Character), Instance.new("Part", Character), Instance.new("Part", Character), Instance.new("Part", Character) do
    RUA.Name = "RUA [Fake]"; RUA.Size = Vector3.new(1, 2, 1); RUA.CanCollide = false;
    RLA.Name = "RLA [Fake]"; RLA.Size = Vector3.new(1, 2, 1); RLA.CanCollide = false;
    LUA.Name = "LUA [Fake]"; LUA.Size = Vector3.new(1, 2, 1); LUA.CanCollide = false;
    LLA.Name = "LLA [Fake]"; LLA.Size = Vector3.new(1, 2, 1); RUA.CanCollide = false; 
    RH.Name = "RH [Fake]"; RH.Size = Vector3.new(.7,.7,.7); RH.CanCollide = false;
    LH.Name = "LH [Fake]"; LH.Size = Vector3.new(.7,.7,.7); LH.CanCollide = false; 
end

local rightShoulder, RSHOULDER_C0_CACHE = Motor6D(torso, RUA, CFrame.new(1.5,1,0), CFrame.new(0,1,0), "RS");
local rightElbow, RELBOW_C0_CACHE = Motor6D(RUA, RLA, CFrame.new(0,-1,0), CFrame.new(0,1,0), "RE");
local rightWrist = Motor6D(RLA, RH, CFrame.new(0,-0.5,0), CFrame.new(0,0.5,0), "RW");
local leftShoulder, LSHOULDER_C0_CACHE = Motor6D(torso, LUA, CFrame.new(-1.5,1,0), CFrame.new(0,1,0), "LS");
local leftElbow, LELBOW_C0_CACHE = Motor6D(LUA, LLA, CFrame.new(0,-1,0), CFrame.new(0,1,0), "LE");
local leftWrist = Motor6D(LLA, LH, CFrame.new(0,-0.5,0), CFrame.new(0,0.5,0), "LW");

local RUPPER_LENGTH			= math.abs(rightShoulder.C1.Y) + math.abs(rightElbow.C0.Y)
local RLOWER_LENGTH			= math.abs(rightElbow.C1.Y) + math.abs(rightWrist.C0.Y) + math.abs(rightWrist.C1.Y)
local LUPPER_LENGTH			= math.abs(leftShoulder.C1.Y) + math.abs(leftElbow.C0.Y)
local LLOWER_LENGTH			= math.abs(leftElbow.C1.Y) + math.abs(leftWrist.C0.Y) + math.abs(leftWrist.C1.Y)

local fakerightarm, fakeleftarm, RHA, LHA, RgrabWeld, LgrabWeld, RgrabAtt, LgrabAtt do
    fakeleftarm, fakerightarm = Instance.new("Part", Character), Instance.new("Part", Character)
    fakeleftarm.CFrame = lhand.CFrame
    fakeleftarm.Name = "Fake Left"
    fakeleftarm.Size = Vector3.new(1,1,.5)
    fakeleftarm.Transparency = options.FakeHandsTransparency
    fakerightarm.CFrame = rhand.CFrame
    fakerightarm.Name = "Fake Right"
    fakerightarm.Size = Vector3.new(1,1,.5)
    fakerightarm.Transparency = options.FakeHandsTransparency
    
    local nocol = Instance.new("NoCollisionConstraint", fakeleftarm)
    nocol.Part1 = fakerightarm; nocol.Part0 = fakeleftarm;
    
    local Rap = Instance.new("AlignPosition", fakerightarm);
    Rap.RigidityEnabled = false; Rap.ReactionForceEnabled = true; Rap.ApplyAtCenterOfMass = false; Rap.MaxForce = 10000000; Rap.MaxVelocity = math.huge/9e110; Rap.Responsiveness = 75;
    local Rao = Instance.new("AlignOrientation", fakerightarm);
    Rao.RigidityEnabled = false; Rao.ReactionTorqueEnabled = false; Rao.PrimaryAxisOnly = false; Rao.MaxTorque = 10000000; Rao.MaxAngularVelocity = math.huge/9e110; Rao.Responsiveness = 75;
    local Lap = Instance.new("AlignPosition", fakeleftarm);
    Lap.RigidityEnabled = false; Lap.ReactionForceEnabled = true; Lap.ApplyAtCenterOfMass = false; Lap.MaxForce = 10000000; Lap.MaxVelocity = math.huge/9e110; Lap.Responsiveness = 75;
    local Lao = Instance.new("AlignOrientation", fakeleftarm); 
    Lao.RigidityEnabled = false; Lao.ReactionTorqueEnabled = false; Lao.PrimaryAxisOnly = false; Lao.MaxTorque = 10000000; Lao.MaxAngularVelocity = math.huge/9e110; Lao.Responsiveness = 75;
    
    local Ratt = Instance.new("Attachment", fakerightarm)
    RHA = Instance.new("Attachment", root)
    local Latt = Instance.new("Attachment", fakeleftarm)
    LHA = Instance.new("Attachment", root)
    
    Rap.Attachment0 = Ratt; Rap.Attachment1 = RHA
    Rao.Attachment0 = Ratt; Rao.Attachment1 = RHA
    Lap.Attachment0 = Latt; Lap.Attachment1 = LHA
    Lao.Attachment0 = Latt; Lao.Attachment1 = LHA
    
    RgrabWeld = Instance.new("WeldConstraint", fakerightarm); RgrabWeld.Part0 = fakerightarm
    LgrabWeld = Instance.new("WeldConstraint", fakeleftarm); LgrabWeld.Part0 = fakeleftarm 
    
    RgrabAtt = Instance.new("Attachment", fakerightarm)
    LgrabAtt = Instance.new("Attachment", fakeleftarm)
    
    fakerightarm.Touched:Connect(function(part)
        if part.CanCollide == true and not part:IsDescendantOf(Character) and part.Parent ~= vrparts then
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, (fakerightarm.Velocity - part.Velocity).Magnitude / 10)
		    wait()
		    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.RightHand, 0)
        end
    end)
    fakeleftarm.Touched:Connect(function(part)
        if part.CanCollide == true and not part:IsDescendantOf(Character) and part.Parent ~= vrparts then
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, (fakeleftarm.Velocity - part.Velocity).Magnitude / 10)
		    wait()
		    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.LeftHand, 0)
        end
    end)
end

local NoCollideCache = Instance.new("Folder")
NoCollideCache.Name = "NoCollideCache"
NoCollideCache.Parent = workspace.Terrain
for _,part in pairs(Character:GetDescendants()) do
    if part:IsA("BasePart") then
        if part ~= root and part ~= fakeleftarm and part ~= fakerightarm then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0,0,0)
            bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            bv.P = 9000
            bv.Parent = part
            for i,v in pairs(Character:GetChildren()) do
                if v:IsA("BasePart") then
                    local nocol = Instance.new("NoCollisionConstraint")
                    nocol.Part1 = part; nocol.Part0 = v;
                    nocol.Parent = NoCollideCache
                end
            end
            if part.Name:find("Arm") or part.Name:find("Leg") or part.Name:find("tHand") or part.Name:find("Foot") then
                part.Transparency = 0
                RunService.Heartbeat:connect(function()
                    part.AssemblyLinearVelocity = Vector3.new(70,0,0)
                end)
                RunService.Stepped:connect(function()
                    part.CanCollide = false
                end)
            elseif part == RH or part == LH or part == RLA or part == LLA or part == RUA or part == LUA  then
                part.Transparency = 1
            elseif part.Parent:IsA("Accessory") then
                if part.Parent.Name == options.RightHand or part.Parent.Name == options.LeftHand then --or table.find(armParts, part.Parent) ~= nil  then
                    part.Transparency = 0
                else
                    part.Transparency = 1
                end
            elseif part.Parent:IsA("Tool") then
            else
                part.Transparency = 0.6
            end
        elseif part == fakeleftarm or part == fakerightarm then
            part.Transparency = options.FakeHandsTransparency
            part.CustomPhysicalProperties = PhysicalProperties.new(10, 1000, -100, 100,100)
            part.Massless = false
        else
            part.CustomPhysicalProperties = PhysicalProperties.new(20, 100, 0, 100,100)
            game:GetService("RunService").Stepped:connect(function()
                part.CanCollide = true
            end)
        end
        if part == torso or part.Name == "Head" then
            game:GetService("RunService").Stepped:connect(function()
                part.CanCollide = false
            end)
        end
        if part.Name == "LowerTorso" or part.Name:find("Foot") then
            part:Destroy()
        end
    end
end

align(torso, header, Vector3.new(0,-.8,0))
if R15 then
    align(Character["RightUpperLeg"],RUA, Vector3.new(0,.5,0), Vector3.new(0,0,0))
    align(Character["RightLowerLeg"],RUA, Vector3.new(0,-.5,0), Vector3.new(0,0,0))
    align(Character["RightUpperArm"],RLA, Vector3.new(0,.5,0), Vector3.new(0,0,0))
    align(Character["RightLowerArm"],RLA, Vector3.new(0,-.5,0), Vector3.new(0,0,0))
    align(Character["LeftUpperLeg"],LUA, Vector3.new(0,.5,0), Vector3.new(0,0,0))
    align(Character["LeftLowerLeg"],LUA, Vector3.new(0,-.5,0), Vector3.new(0,0,0))
    align(Character["LeftUpperArm"],LLA, Vector3.new(0,.5,0), Vector3.new(0,0,0))
    align(Character["LeftLowerArm"],LLA, Vector3.new(0,-.5,0), Vector3.new(0,0,0))
    alignHand(Character["RightHand"], RH, fakerightarm, Vector3.new(0,-.2,0), Vector3.new(0,-90,0))
    alignHand(Character["LeftHand"], LH, fakeleftarm, Vector3.new(0,-.2,0), Vector3.new(0,-90,0))
else
    align(rightleg,RUA, Vector3.new(0,0,0), Vector3.new(0,0,0))
    align(rightarm,RLA, Vector3.new(0,0,0), Vector3.new(0,-90,0))
    align(leftleg,LUA, Vector3.new(0,0,0), Vector3.new(0,0,0))
    align(leftarm,LLA, Vector3.new(0,0,0), Vector3.new(0,-90,0))
end
if options.Hands then
    align(Character[options.RightHand], RH)
    align(Character[options.LeftHand], LH)
end

local bg = Instance.new("BodyGyro", root); bg.MaxTorque = Vector3.new(17000,17000,17000); bg.P = 17000

local Twist = 0
local Height = .5
local SelectionBox = Instance.new("SelectionBox", workspace)
local SelectedPart

local LgrabPart
local RgrabPart

local Lholding
local Rholding
RunService.Heartbeat:Connect(function()
	local RshoulderCFrame = torso.CFrame * RSHOULDER_C0_CACHE
	local RplaneCF, RshoulderAngle, RelbowAngle = solveIK(RshoulderCFrame, fakerightarm.Position, RUPPER_LENGTH, RLOWER_LENGTH)
	local LshoulderCFrame = torso.CFrame * LSHOULDER_C0_CACHE
	local LplaneCF, LshoulderAngle, LelbowAngle = solveIK(LshoulderCFrame, fakeleftarm.Position, LUPPER_LENGTH, LLOWER_LENGTH)
	rightShoulder.C0 = torso.CFrame:toObjectSpace(RplaneCF) * CFrame.Angles(RshoulderAngle, 0, 0)
	rightElbow.C0 = RELBOW_C0_CACHE * CFrame.Angles(RelbowAngle, 0, 0)
	leftShoulder.C0 = torso.CFrame:toObjectSpace(LplaneCF) * CFrame.Angles(LshoulderAngle, 0, 0)
	leftElbow.C0 = LELBOW_C0_CACHE * CFrame.Angles(LelbowAngle, 0, 0)
end)

RunService.Stepped:Connect(function()
	rightShoulder.Transform = CFrame.new()
	rightElbow.Transform = CFrame.new()
	rightWrist.Transform = CFrame.new()
	leftShoulder.Transform = CFrame.new()
	leftElbow.Transform = CFrame.new()
	leftWrist.Transform = CFrame.new()
end)

RunService.RenderStepped:Connect(function()
    RHA.WorldCFrame = rhand.CFrame
    LHA.WorldCFrame = lhand.CFrame
    hum.PlatformStand = true
    workspace.Gravity = 75
    if VRReady then
        local HeadCF = VRService:GetUserCFrame(Enum.UserCFrame.Head);
	    u1 = CFrame.new((root.Position - HeadCF.Position * Workspace.CurrentCamera.HeadScale) + Vector3.new(0,1.5,0)) * CFrame.Angles(0, math.rad(Twist), 0);
	    CurrentCamera.CFrame = (u1 * CFrame.new(0, 0, 0) * CFrame.fromEulerAnglesXYZ(CFrame.new(HeadCF.p * options.HeadScale):ToEulerAnglesXYZ())) --+ Vector3.new(0,Height,0)
	    
        for _,hat in pairs(Character:GetChildren()) do
            if hat:IsA("Accessory") and hat:FindFirstChild("Handle") then hat.Handle.Transparency = 1 end
        end
        
        local selectRay = Ray.new(rhand.Position, -rhand.CFrame.upVector.Unit * options.PointerRange)
        local hit, position, normal	= Workspace:FindPartOnRayWithIgnoreList(selectRay, {vrparts, Character})
        if hit and (hit:FindFirstChild("TouchInterest") or hit:FindFirstChildOfClass("ClickDetector")) then
            SelectionBox.Adornee = hit
            SelectedPart = hit
        else
            SelectionBox.Adornee = nil
        end
        
        local RgrabRay = Ray.new(rhand.Position, -rhand.CFrame.upVector.Unit * 1.3)
        local Rpart, Rposition, Rnormal	= Workspace:FindPartOnRayWithIgnoreList(RgrabRay, {vrparts, Character})
        local LgrabRay = Ray.new(lhand.Position, -lhand.CFrame.upVector.Unit * 1.3)
        local Lpart, Rposition, Rnormal	= Workspace:FindPartOnRayWithIgnoreList(LgrabRay, {vrparts, Character})
        if Rpart then RgrabPart = Rpart else RgrabPart = nil end
        if Lpart then LgrabPart = Lpart else LgrabPart = nil end
    else
        CurrentCamera.CameraType = "Scriptable"
    end
end)

--[Teleporting]
root:GetPropertyChangedSignal("Position"):Connect(function(pos)
    root.Velocity = Vector3.new(0,0,0)
    fakeleftarm.Velocity = Vector3.new(0,0,0)
    fakerightarm.Velocity = Vector3.new(0,0,0)
    root.Anchored = true
    RgrabWeld.Part1 = nil
    LgrabWeld.Part1 = nil
    torso.CFrame = root.CFrame
    fakeleftarm.CFrame = root.CFrame
    fakerightarm.CFrame = root.CFrame
    wait(2)
    root.Anchored = false
    for i = 1,4 do
        root.Velocity = Vector3.new(0,0,0)
        fakeleftarm.Velocity = Vector3.new(0,0,0)
        fakerightarm.Velocity = Vector3.new(0,0,0)
    end
end)

--[Dying]
hum.Died:Connect(function()
    if #Players:GetPlayers() <= 1 then
        Players.LocalPlayer:Kick("\nRejoining...")
        wait()
        game:GetService('TeleportService'):Teleport(game.PlaceId, LocalPlayer)
	else
		game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)
    
--[Tools]
local toolrot = Vector3.new(0,0,0)
function doTool(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") and not tool:FindFirstChild("Done") then
        local realhandle = tool:FindFirstChild("Handle")
        realhandle.Massless = true
        RunService.Heartbeat:Connect(function()
            realhandle.Velocity = Vector3.new(45,0,0)
        end)
        local tag = Instance.new("StringValue", tool); tag.Name = "Done"
        if R15 then
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
    
--=========[Keyboard]==========--
local Keyboard = game:GetObjects("rbxassetid://7333397685")[1]; Keyboard.Parent = workspace
local Preview = Keyboard.Preview.Display.Input
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
            if part == leftarm or part == rightarm then
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
    if (root.Position - Keyboard.PrimaryPart.Position).Magnitude > 20 then
        KeyboardActive = false
    end
    if KeyboardActive then
        Keyboard.Parent = workspace
        --Keyboard:SetPrimaryPartCFrame(Keyboard.PrimaryPart.CFrame:lerp(Keyboard.PrimaryPart.CFrame * (header.CFrame - header.Position), .01))
        Keyboard:SetPrimaryPartCFrame(Keyboard.PrimaryPart.CFrame:lerp(CFrame.lookAt(Keyboard.PrimaryPart.Position, header.Position) * CFrame.Angles(0,math.rad(180),0), .01))
    else
        Keyboard.Parent = ReplicatedStorage
    end
end
RunService.RenderStepped:Connect(handleKeyboard)

--=========[Controls]==========--
local turnDB = false
local keyboardDB = false
UserInputService.InputChanged:connect(function(key)
    if key.KeyCode == Enum.KeyCode.Thumbstick2 then
        if key.Position.Y > 0.8 then
            Height = Height + .1
        elseif key.Position.Y < -0.8 then
            Height = Height - .1
        end
        if key.Position.X > 0.8 and not turnDB then
            turnDB = true
            Twist = Twist - options.TurnAngle
            wait(options.TurnDelay)
            turnDB = false
        elseif key.Position.X < -0.8 and not turnDB then
            turnDB = true
            Twist = Twist + options.TurnAngle
            wait(options.TurnDelay)
            turnDB = false
        end
    end
end)

UserInputService.InputChanged:connect(function(key)
    if key.KeyCode == Enum.KeyCode.Thumbstick1 then
    end
end)

UserInputService.InputChanged:connect(function(key)
    if key.KeyCode == Enum.KeyCode.ButtonL2 then
        if key.Position.Z > 0.8 and not keyboardDB then
            keyboardDB = true
            Keyboard:SetPrimaryPartCFrame((header.CFrame + Vector3.new(0,1,0)) * CFrame.new(0,0,-8))
            KeyboardActive = not KeyboardActive
            wait(.5)
            keyboardDB = false
        end
    end
end)

UserInputService.InputChanged:connect(function(key)
    if key.KeyCode == Enum.KeyCode.ButtonR2 then
        if not R15 then
            for i,tool in pairs(Character:GetChildren()) do
                if tool:IsA("Tool") then tool:Activate() end
            end
        end
        if SelectedPart then
            if key.Position.Z > 0.8 then
                if SelectedPart:FindFirstChild("TouchInterest") then
                    firetouchinterest(rightarm, SelectedPart, 0)
                elseif SelectedPart:FindFirstChildOfClass("ClickDetector") then
                    fireclickdetector(SelectedPart:FindFirstChildOfClass("ClickDetector"))
                end
            else
                if SelectedPart:FindFirstChild("TouchInterest") then
                    firetouchinterest(rightarm, SelectedPart, 1)
                end
            end
        end
    end 
end)

UserInputService.InputBegan:connect(function(key)
    if key.KeyCode == Enum.KeyCode.ButtonR1 then
        if RgrabPart and not RgrabPart.Parent:FindFirstChildOfClass("Humanoid") and RgrabPart.Parent.Name ~= "Handle" then
            if not RgrabPart.Parent:IsA("Accessory") and (RgrabPart:IsGrounded() or RgrabPart.Anchored) then
                RgrabWeld.Part1 = RgrabPart
                root.Velocity = Vector3.new(0,0,0)
                fakerightarm.Velocity = Vector3.new(0,0,0)
                fakeleftarm.Velocity = Vector3.new(0,0,0)
                root.Massless = false
                fakerightarm.Massless =  true
                fakerightarm.CanCollide = false
            else
                Rholding = RgrabPart
                holdPart(RgrabPart, RgrabAtt)
            end
        end
    elseif key.KeyCode == Enum.KeyCode.ButtonL1 then
        if LgrabPart and not LgrabPart.Parent:FindFirstChildOfClass("Humanoid") and LgrabPart.Parent.Name ~= "Handle" then
            if not LgrabPart.Parent:IsA("Accessory") and (LgrabPart:IsGrounded() or LgrabPart.Anchored) then
                LgrabWeld.Part1 = LgrabPart
                root.Velocity = Vector3.new(0,0,0)
                fakerightarm.Velocity = Vector3.new(0,0,0)
                fakeleftarm.Velocity = Vector3.new(0,0,0)
                root.Massless = true
                fakeleftarm.Massless =  true
                fakeleftarm.CanCollide = false
            else
                Lholding = LgrabPart
                holdPart(LgrabPart, LgrabAtt)
            end
        end
    end 
end)

UserInputService.InputEnded:connect(function(key)
    if key.KeyCode == Enum.KeyCode.ButtonR1 then
        RgrabWeld.Part1 = nil
        fakerightarm.Massless =  false
        fakerightarm.CanCollide = true
        if Rholding then
            holdPart(Rholding, nil, true)
        end
    elseif key.KeyCode == Enum.KeyCode.ButtonL1 then
        LgrabWeld.Part1 = nil
        fakeleftarm.Massless =  false
        fakeleftarm.CanCollide = true
        if Lholding then
            holdPart(Lholding, nil, true)
        end
    end 
end)

--=========[Cool Things]==========--
ViewHUDFunc = function()
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
					if not string.find(Part.Name, "Fake") and Part.Name ~= "HumanoidRootPart" then
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


ChatHUDFunc = function()
	--[[
		Variables
	--]]
 
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
 
	--[[
		Code
	--]]
 
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
 
	--
 
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
 
		if Distance and Distance <= options.ChatLocalRange then
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
 
			ChatPart.CFrame = lhand.CFrame * CFrame.Angles(math.rad(-90),math.rad(0), math.rad(0))
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

task.spawn(ChatHUDFunc)
task.spawn(ViewHUDFunc)
