local Utils = {}

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
        if part:IsA("BasePart") and part.CanCollide then
            for i,part2 in pairs(b:GetDescendants()) do
                if part2:IsA("BasePart") and part2.CanCollide then
                    local noCollide = Instance.new("NoCollisionConstraint")
                    noCollide.Part0 = part
                    noCollide.Part1 = part2
                    noCollide.Name = ""
                    noCollide.Parent = part
                end
            end
        end
    end
end

function Utils:FindCollidablePartOnRay(StartPosition,Direction,IgnoreList,CollisionGroup)
    --Convert the collision group.
    if typeof(CollisionGroup) == "Instance" and CollisionGroup:IsA("BasePart") then
        CollisionGroup = PhysicsService:GetCollisionGroupName(CollisionGroup.CollisionGroupId)
    end

    --Create the ignore list.
    local Camera = Workspace.CurrentCamera
    local NewIgnoreList = {Camera}
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

function Utils:VRCharacter(Character)
    Character.Archivable = true
    local VRCharacter = Character:Clone()
    self.NoCollideModel(VRCharacter, Character)
    for _,v in pairs(VRCharacter:GetDescendants()) do
        if v:IsA("BasePart") then 
            v.CanCollide = false
            v.Transparency = .5 
        end
    end 
    VRCharacter:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame)
    VRCharacter.Parent = workspace.Terrain

    return VRCharacter
end

return Utils