local Utils = {}

function Utils.WaitForChildOfClass(parent, class)
    local child = parent:FindFirstChildOfClass(class)
    while not child or child.ClassName ~= class do
        child = parent.ChildAdded:Wait()
    end
    return child
end

function Utils.VRCharacter(Character)
    Character.Archivable = true
    local VRCharacter = Character:Clone()
    for _,v in pairs(VRCharacter:GetDescendants()) do
        if v:IsA("BasePart") then end
    end 
    VRCharacter:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame)
    VRCharacter.Parent = workspace.Terrain
end

function Utils.NoCollide(a, b)
    for i,v in pairs(a:GetChildren()) 
end

return Utils