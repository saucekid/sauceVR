--[[
    Netless bypass 
    edited from MW Reanimate
--]]

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

local shp = getfenv().sethiddenproperty
if shp then
    local con = nil
    con = heartbeat:Connect(function()
        if not c then return con:Disconnect() end
        shp(lp, "SimulationRadius", 1000)
    end)
end


local fenv = getfenv()

local shp = fenv.sethiddenproperty or fenv.set_hidden_property or fenv.set_hidden_prop or fenv.sethiddenprop
local ssr = fenv.setsimulationradius or fenv.set_simulation_radius or fenv.set_sim_radius or fenv.setsimradius or fenv.setsimrad or fenv.set_sim_rad

local reclaim, lostpart = c.PrimaryPart, nil

local v3_hide = v3(0, 400, 0)

pcall(function()
    settings().Physics.AllowSleep = false
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)


local netless = {}

function netless:align(Part0, Part1, offset, nameHide)
    local align = {
        nameHide = nameHide,
        offset = offset or v3_0,
        Part0 = Part0,
        Part1 = Part1,
    }

    --Create offset attachment
    local att1 = Instance.new("Attachment")
    att1.Name  = "att1_" .. Part1.Name
    att1[typeof(offset) == "CFrame" and "CFrame" or "Position"] = offset or v3_0
    align.att1 = att1

    --Remove any welds/motors connected to part.
    local Motor = Utils:GetMotorForLimb(Part0); if Motor then Motor:Destroy() end

    local accessoryWeld = Part0:FindFirstChild("AccessoryWeld")
    if accessoryWeld then
        accessoryWeld:Destroy()
    end

    --Hide health by moving head away for a moment (PATCHED)
    --[[
    local hide = false
    if Part0.Name == "Head" and align.nameHide then
        tdelay(0, function()
            while twait(6) and Part0 and c do
                hide = true
                twait(0.015)
                hide = false
            end
        end)
    end
    ]]

    --Align Part0 to Part1
    local rot = rad(0.05)
    local con0, con1 = nil, nil
    con0 = stepped:Connect(function()
        if not (align.Part0 and align.Part1) then return con0:Disconnect() and con1:Disconnect() end
        align.Part0.RotVelocity = align.Part1.RotVelocity
    end)

    local lastpos, vel = align.Part0.Position, align.Part1.Velocity
    con1 = heartbeat:Connect(function(delta)
        if not (align.Part0 and align.Part1 and att1) then return con0:Disconnect() and con1:Disconnect() end
        if (not align.Part0.Anchored) then
            if lostpart == align.Part0 then
                lostpart = nil
            end
            att1[typeof(align.offset) == "CFrame" and "CFrame" or "Position"] = align.offset or v3_0
            local newcf = align.Part1.CFrame * att1.CFrame
            local vel = (newcf.Position - lastpos) / delta
            align.Part0.Velocity = getNetlessVelocity(vel)
            if vel.Magnitude < 1 then
                rot = -rot
                newcf *= angles(0, 0, rot)
            end
            lastpos = newcf.Position
            if lostpart and (align.Part0 == reclaim) then
                newcf = lostpart.CFrame
            elseif hide then
                newcf += v3_hide
            end
            align.Part0.CFrame = newcf
        elseif (not align.Part0.Anchored) and (abs(align.Part0.Velocity.X) < 45) and (abs(align.Part0.Velocity.Y) < 25) and (abs(align.Part0.Velocity.Z) < 45) then
            lostpart = align.Part0
        end
    end)

    att1:GetPropertyChangedSignal("Parent"):Connect(function()
        Part1 = att1.Parent
        if Part1 and not Part1:IsA("BasePart") then
            att1 = nil
            Part1 = nil
        end
    end)
    att1.Parent = align.Part1

    return align
end


return netless

