local sauceVR = script:FindFirstAncestor("sauceVR")
local Utils = require(sauceVR.Util.Utils)

local lp = game:GetService("Players").LocalPlayer
local rs, ws, sg = game:GetService("RunService"), game:GetService("Workspace"), game:GetService("StarterGui")
local stepped, heartbeat, renderstepped = rs.Stepped, rs.Heartbeat, rs.RenderStepped
local twait, tdelay, rad, inf, abs, mclamp = task.wait, task.delay, math.rad, math.huge, math.abs, math.clamp
local cf, v3, angles = CFrame.new, Vector3.new, CFrame.Angles
local v3_0, cf_0 = v3(0, 0, 0), cf(0, 0, 0)

local c = lp.Character

if not (c and c.Parent) then
    return
end

c:GetPropertyChangedSignal("Parent"):Connect(function()
    if not (c and c.Parent) then
        c = nil
    end
end)

local destroy = c.Destroy

local v3_xz, v3_net = v3(8, 0, 8), v3(0.1, 25.1, 0.1)
local function getNetlessVelocity(realPartVelocity) --edit this if you have a better netless method
    if realPartVelocity.Magnitude < 0.1 then return v3_net end
    return realPartVelocity * v3_xz + v3_net
end

local fenv = getfenv()

local shp = fenv.sethiddenproperty or fenv.set_hidden_property or fenv.set_hidden_prop or fenv.sethiddenprop
local ssr = fenv.setsimulationradius or fenv.set_simulation_radius or fenv.set_sim_radius or fenv.setsimradius or fenv.setsimrad or fenv.set_sim_rad

local reclaim, lostpart = c.PrimaryPart, nil

local v3_hide = v3(0, 1000, 0)

pcall(function()
    settings().Physics.AllowSleep = false
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)


local netless = {}

function netless:align(Part0, Part1, offset)
    offset = offset or v3_0
    local Motor = Utils:GetMotorForLimb(Part0); if Motor then Motor:Destroy() end

    local att0 = Instance.new("Attachment")
    att0.Position, att0.Orientation, att0.Name = v3_0 , v3_0, "att0_" .. Part0.Name
    local att1 = Instance.new("Attachment")
    att1.Position, att1.Orientation, att1.Name = v3_0 + offset, v3_0, "att1_" .. Part1.Name
    
    local hide = false

    --[[
    if Part0.Name == "Head" then
        tdelay(0, function()
            while twait(2.9) and Part0 and c do
                hide = #Part0:GetConnectedParts() > 0
                twait(0.1)
                hide = false
            end
        end)
    end
    ]]

    local rot = rad(0.05)
    local con0, con1 = nil, nil
    con0 = stepped:Connect(function()
        if not (Part0 and Part1) then return con0:Disconnect() and con1:Disconnect() end
        Part0.RotVelocity = Part1.RotVelocity
    end)
    local lastpos, vel = Part0.Position, Part0.Velocity
    con1 = heartbeat:Connect(function(delta)
        if not (Part0 and Part1 and att1) then return con0:Disconnect() and con1:Disconnect() end
        if (not Part0.Anchored) then
            if lostpart == Part0 then
                lostpart = nil
            end
            local newcf = Part1.CFrame * att1.CFrame
            local vel = (newcf.Position - lastpos) / delta
            Part0.Velocity = getNetlessVelocity(vel)
            if vel.Magnitude < 1 then
                rot = -rot
                newcf *= angles(0, 0, rot)
            end
            lastpos = newcf.Position
            if lostpart and (Part0 == reclaim) then
                newcf = lostpart.CFrame
            elseif hide then
                newcf += v3_hide
            end
            if (newcf.Y < ws.FallenPartsDestroyHeight + 0.1) then
                newcf += v3(0, ws.FallenPartsDestroyHeight + 0.1 - newcf.Y, 0)
            end
            Part0.CFrame = newcf
        elseif (not Part0.Anchored) and (abs(Part0.Velocity.X) < 45) and (abs(Part0.Velocity.Y) < 25) and (abs(Part0.Velocity.Z) < 45) then
            lostpart = Part0
        end
    end)

    att0:GetPropertyChangedSignal("Parent"):Connect(function()
        Part0 = att0.Parent
        if not Part0:IsA("BasePart") then
            att0 = nil
            if lostpart == Part0 then
                lostpart = nil
            end
            Part0 = nil
        end
    end)
    att0.Parent = Part0
    
    att1:GetPropertyChangedSignal("Parent"):Connect(function()
        Part1 = att1.Parent
        if not Part1:IsA("BasePart") then
            att1 = nil
            Part1 = nil
        end
    end)
    att1.Parent = Part1

    return att1
end

return netless

