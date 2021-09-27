local Utils = {}

local NoCollideFolder = workspace,Terrain:FindFirstChild("NoCollideCache") or Instance.new("Folder", workspace.Terrain)
NoCollideFolder.Name = "NoCollideCache"

local PhysicsService = game:GetService("PhysicsService")

function Utils.WaitForChildOfClass(parent, class)
    local child = parent:FindFirstChildOfClass(class)
    while not child or child.ClassName ~= class do
        child = parent.ChildAdded:Wait()
    end
    return child
end

function Utils.NoCollideModel(a, b)
    for _,part in pairs(a:GetDescendants()) do
        if part:IsA("BasePart") then
            for i,part2 in pairs(b:GetDescendants()) do
                if part2:IsA("BasePart") then
                    local noCollide = Instance.new("NoCollisionConstraint")
                    noCollide.Part0 = part
                    noCollide.Part1 = part2
                    noCollide.Name = ""
                    noCollide.Parent = NoCollideCache
                end
            end
        end
    end
end

function Utils.NoCollide(a, b)
    local noCollide = Instance.new("NoCollisionConstraint")
    noCollide.Part0 = a
    noCollide.Part1 = b
    noCollide.Name = ""
    noCollide.Parent = NoCollideCache
end

function Utils:ClearNoCollide()
    NoCollideFolder:ClearAllChildren()
end

function Utils:FindCollidablePartOnRay(StartPosition,Direction,IgnoreList,CollisionGroup)
    --Convert the collision group.
    if typeof(CollisionGroup) == "Instance" and CollisionGroup:IsA("BasePart") then
        CollisionGroup = PhysicsService:GetCollisionGroupName(CollisionGroup.CollisionGroupId)
    end

    --Create the ignore list.
    local Camera = Workspace.CurrentCamera
    local NewIgnoreList = {Camera, game.Players.LocalPlayer.Character}
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

function Utils:Align(a, b, pos, rot, options)
    if typeof(options) ~= 'table' then
        options = {resp = 200, reactiontorque = false, reactionforce = false}
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
    ao.RigidityEnabled = false;
    ao.ReactionTorqueEnabled = options.reactiontorque or true;
    ao.PrimaryAxisOnly = false;
    ao.MaxTorque = 10000000;
    ao.MaxAngularVelocity = math.huge/9e110;
    ao.Responsiveness = 200;
    ao.Parent = Handle
end

function Utils:VRCharacter(Character, trans)
    Character.Archivable = true
    local VRCharacter = Character:Clone()
    self.NoCollideModel(VRCharacter, Character)
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

return Utils