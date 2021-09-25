local Utils = {}

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