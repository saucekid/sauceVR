local Utils = {}

local sauceVR = script:FindFirstAncestor("sauceVR")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local cacheFolder = workspace.Terrain:FindFirstChild("Cache") or Instance.new("Folder", workspace.Terrain)
cacheFolder.Name = "Cache"

local PhysicsService = game:GetService("PhysicsService")

function Utils.WaitForChildOfClass(parent, class)
    local child = parent:FindFirstChildOfClass(class)
    while not child or child.ClassName ~= class do
        child = parent.ChildAdded:Wait()
    end
    return child
end

function Utils:NoCollideModel(a, b)
    for _,part in pairs(a:GetDescendants()) do
        if part:IsA("BasePart") then
            for i,part2 in pairs(b:GetDescendants()) do
                if part2:IsA("BasePart") then
                    local noCollide = Instance.new("NoCollisionConstraint")
                    noCollide.Part0 = part
                    noCollide.Part1 = part2
                    noCollide.Name = ""
                    noCollide.Parent = cacheFolder
                end
            end
        end
    end
end

function Utils:NoCollide(a, b, parent)
    local noCollide = Instance.new("NoCollisionConstraint")
    noCollide.Part0 = a
    noCollide.Part1 = b
    noCollide.Name = ""
    noCollide.Parent = parent or cacheFolder
    return noCollide
end

function Utils:ClearCache()
    cacheFolder:ClearAllChildren()
end

function Utils:AddCache(instance)
    instance.Parent = cacheFolder
end

function Utils:getPointPart(hand, distance, vector, ignorelist, reverse)
    vector = vector or "upVector";
    vector = typeof(hand) == "Instance" and -hand.CFrame[vector].Unit or hand[vector].Unit 
    vector  = reverse and -vector or vector
    local pointRay = Ray.new(hand.Position, vector * distance)
    local part, position, normal = Workspace:FindPartOnRayWithIgnoreList(pointRay, ignorelist)
    return part, position, normal
end


function Utils:FindCollidablePartOnRay(StartPosition,Direction,IgnoreList,CollisionGroup)
    --Convert the collision group.
    if typeof(CollisionGroup) == "Instance" and CollisionGroup:IsA("BasePart") then
        CollisionGroup = PhysicsService:GetCollisionGroupName(CollisionGroup.CollisionGroupId)
    end

    --Create the ignore list.
    local Camera = Workspace.CurrentCamera
    local NewIgnoreList = {Camera, game.Players.LocalPlayer.Character, workspace.Terrain:FindFirstChild("VRCharacter")}
    if typeof(IgnoreList) == "Instance" then
        table.insert(NewIgnoreList,IgnoreList)
    elseif typeof(IgnoreList) == "table" then
        for _,Entry in pairs(IgnoreList) do
            if Entry ~= Camera then
                table.insert(NewIgnoreList,Entry)
            end
        end
    end

    --Create the parameters.
    local RaycastParameters = RaycastParams.new()
    RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParameters.FilterDescendantsInstances = NewIgnoreList
    RaycastParameters.IgnoreWater = true
    if CollisionGroup then
        RaycastParameters.CollisionGroup = CollisionGroup
    end

    --Raycast and continue if the hit part isn't collidable.
    local RaycastResult = Workspace:Raycast(StartPosition,Direction,RaycastParameters)
    if not RaycastResult then
        return nil,StartPosition + Direction
    end
    local HitPart,EndPosition = RaycastResult.Instance,RaycastResult.Position
    if HitPart and not HitPart.CanCollide and (not HitPart:IsA("Seat") or not HitPart:IsA("VehicleSeat") or HitPart.Disabled) then
        table.insert(NewIgnoreList,HitPart)
        return self:FindCollidablePartOnRay(EndPosition,Direction + (EndPosition - StartPosition),NewIgnoreList,CollisionGroup)
    end

    --Return the hit result.
    return HitPart,EndPosition
end

function Utils:GetMotorForLimb(Limb)
	for _, Motor in next, Limb.Parent:GetDescendants() do
		if Motor:IsA("Motor6D") and Motor.Part1 == Limb then
			return Motor
		end
	end
end

function Utils:createMotor(part0, part1, c0, c1, name)
    part1.Transparency = 1;
    part1.Massless = true
    local motor = Instance.new("Motor6D"); motor.Name = name; motor.Part0 = part0; motor.Part1 = part1; motor.C0 = c0; motor.C1 = c1; motor.Parent = part1
    return motor, motor.C0
end


function Utils:Align(a, b, pos, rot, options)
    if typeof(options) ~= 'table' then
        options = {resp = 200, reactiontorque = false, reactionforce = false, orientationrig = true}
    end

    local att0, att1 do
        att0 = a:IsA("Accessory") and Instance.new("Attachment", a.Handle) or Instance.new("Attachment", a)
        att1 = Instance.new("Attachment"); 
        att1.Position = pos or Vector3.new(0,0,0); att1.Orientation = rot or Vector3.new(0,0,0); att1.Parent = b
    end
    
    local Handle = a:IsA("Accessory") and a.Handle or a;
    Handle.Massless = true;
    Handle.CanCollide = false;
    
    if a:IsA("Accessory") then 
        Handle.AccessoryWeld:Destroy()  
    else
        local Motor = self:GetMotorForLimb(a); if Motor then Motor:Destroy() end
    end

    local al = Instance.new("AlignPosition");
    al.Attachment0 = att0; al.Attachment1 = att1;
    al.RigidityEnabled = true;
    al.ReactionForceEnabled = options.reactionforce or false;
    al.ApplyAtCenterOfMass = true;
    al.MaxForce = 10000000;
    al.MaxVelocity = math.huge/9e110;
    al.Responsiveness = options.resp or 200;
    al.Parent = Handle
    local ao = Instance.new("AlignOrientation");    
    ao.Attachment0 = att0; ao.Attachment1 = att1;
    ao.RigidityEnabled = options.orientationrig or true;
    ao.ReactionTorqueEnabled = options.reactiontorque or true;
    ao.PrimaryAxisOnly = false;
    ao.MaxTorque = 10000000;
    ao.MaxAngularVelocity = math.huge/9e110;
    ao.Responsiveness = 200;
    ao.Parent = Handle

    return att1, al, ao
end

function Utils:getClosestPlayer()
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if  (not Character or not HumanoidRootPart) then return end

    local TargetDistance = math.huge
    local Target

    for i,v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local TargetHRP = v.Character.HumanoidRootPart
            local mag = (HumanoidRootPart.Position - TargetHRP.Position).magnitude
            if mag < TargetDistance then
                TargetDistance = mag
                Target = v
            end
        end
    end

    return Target, TargetDistance
end

function Utils:VRCharacter(Character, trans)
    Character.Archivable = true
    local VRCharacter = Character:Clone()
    --self:NoCollideModel(VRCharacter, Character)
    for _,v in pairs(VRCharacter:GetDescendants()) do
        if v:IsA("BasePart") then 
            v.CanCollide = false
            v.Transparency = trans or 1
        elseif v:IsA("Decal") then
            v.Transparency = trans or 1
        elseif v:IsA("ParticleEmitter") then
            v:Destroy()
        end
    end 
    VRCharacter:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame)
    VRCharacter.Name = "VRCharacter"
    VRCharacter.Parent = workspace.Terrain

    return VRCharacter
end

function Utils:permaDeath(character)
    LocalPlayer.Character = nil
    LocalPlayer.Character = character
    task.wait(Players.RespawnTime + .05)

    character.Humanoid.BreakJointsOnDeath = false
    character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

function Utils:cframeAlign(a, b, pos, frame)
    local frame = frame or "Heartbeat"
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
    RunService[frame]:Connect(doAlign)
    --RunService.RenderStepped:Connect(doAlign)
end


function Utils:loadingScreen(sec)
    local first = tick()
    local oldFogEnd, oldFogColor, oldClockTime = Lighting.FogEnd, Lighting.FogColor, Lighting.ClockTime

    local logoPart = sauceVR.Assets.Logo:Clone()
    logoPart.Parent = workspace.CurrentCamera
    logoPart.CFrame =  (workspace.CurrentCamera.CFrame * CFrame.Angles(0,math.rad(180),0)) * CFrame.new(0,0,9)

    local loadCon; loadCon = RunService.RenderStepped:Connect(function()
        if tick() - first >= sec then
            logoPart:Destroy()

            Lighting.FogEnd = oldFogEnd
            Lighting.FogColor = oldFogColor
            Lighting.ClockTime = oldClockTime

            loadCon:Disconnect()
        else
            logoPart.CFrame =  logoPart.CFrame:Lerp((workspace.CurrentCamera.CFrame * CFrame.Angles(0,math.rad(180),0)) * CFrame.new(0,0,9),0.1)

            Lighting.FogEnd = 50
            Lighting.FogColor = Color3.new(0,0,0)
            Lighting.ClockTime = 0
        end
    end)
end

return Utils