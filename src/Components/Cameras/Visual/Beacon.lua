--[[
Visual indicator for the end of aiming.
--]]

local BEACON_SPEED_MULTIPLIER = 2

local Workspace = game:GetService("Workspace")


local BeaconModule = {}

--[[
Creates a beacon.
--]]
function BeaconModule.new()
    local Beacon = {}

    --Create the parts.
    Beacon.Sphere = Instance.new("Part")
    Beacon.Sphere.Transparency = 1
    Beacon.Sphere.Material = "Neon"
    Beacon.Sphere.Anchored = true
    Beacon.Sphere.CanCollide = false
    Beacon.Sphere.Size = Vector3.new(0.5,0.5,0.5)
    Beacon.Sphere.Shape = "Ball"
    Beacon.Sphere.TopSurface = "Smooth"
    Beacon.Sphere.BottomSurface = "Smooth"
    Beacon.Sphere.Parent = Workspace.CurrentCamera

    Beacon.ConstantRing = Instance.new("ImageHandleAdornment")
    Beacon.ConstantRing.Adornee = Beacon.Sphere
    Beacon.ConstantRing.Size = Vector2.new(2,2)
    Beacon.ConstantRing.Image = "rbxasset://textures/ui/VR/VRPointerDiscBlue.png"
    Beacon.ConstantRing.Visible = false
    Beacon.ConstantRing.Parent = Beacon.Sphere

    Beacon.MovingRing = Instance.new("ImageHandleAdornment")
    Beacon.MovingRing.Adornee = Beacon.Sphere
    Beacon.MovingRing.Size = Vector2.new(2,2)
    Beacon.MovingRing.Image = "rbxasset://textures/ui/VR/VRPointerDiscBlue.png"
    Beacon.MovingRing.Visible = false
    Beacon.MovingRing.Parent = Beacon.Sphere

    --[[
    Updates the beacon at a given CFrame.
    --]]
    function Beacon:Update(CenterCFrame,HoverPart)
        --Calculate the size for the current time.
        local Height = 0.4 + (-math.cos(tick() * 2 * BEACON_SPEED_MULTIPLIER)/8)
        local BeaconSize = 2 * ((tick() * BEACON_SPEED_MULTIPLIER) % math.pi)/math.pi

        --Update the size and position of the beacon.
        self.Sphere.CFrame = CenterCFrame * CFrame.new(0,Height,0)
        self.ConstantRing.CFrame = CFrame.new(0,-Height,0) * CFrame.Angles(math.pi/2,0,0)
        self.MovingRing.CFrame = CFrame.new(0,-Height,0) * CFrame.Angles(math.pi/2,0,0)
        self.MovingRing.Transparency = BeaconSize/2
        self.MovingRing.Size = Vector2.new(BeaconSize,BeaconSize)

        --Update the beacon color.
        local BeaconColor = Color3.new(0,170/255,0)
        if HoverPart then
            local VRBeaconColor = HoverPart:FindFirstChild("VRBeaconColor")
            if VRBeaconColor then
                BeaconColor = VRBeaconColor.Value
            elseif (HoverPart:IsA("Seat") or HoverPart:IsA("VehicleSeat")) and not HoverPart.Disabled then
                BeaconColor = Color3.new(0,170/255,255/255)
            end
        end
        self.Sphere.Color = BeaconColor

        --Show the beacon.
        self.Sphere.Transparency = 0
        self.ConstantRing.Visible = true
        self.MovingRing.Visible = true
    end

    --[[
    Hides the beacon.
    --]]
    function Beacon:Hide()
        --Hide the beacon.
        self.Sphere.Transparency = 1
        self.ConstantRing.Visible = false
        self.MovingRing.Visible = false
    end

    --[[
    Destroys the beacon.
    --]]
    function Beacon:Destroy()
        self.Sphere:Destroy()
    end

    return Beacon
end



return BeaconModule