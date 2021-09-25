local Utils = {}

function Utils.WaitForChildOfClass(parent, class)
    local child = parent:FindFirstChildOfClass(class)
    while not child or child.ClassName ~= class do
            child = parent.ChildAdded:Wait()
    end
    return child
end

return Utils