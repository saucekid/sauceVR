local handModule = {}

function handModule:createHand(Character, name, cframe, size)
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

return handModule