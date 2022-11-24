local sauceVR = script:FindFirstAncestor("sauceVR")
local Arc = require(sauceVR.Components.Cameras.Visual.Arc)
local Beacon = require(sauceVR.Components.Cameras.Visual.Beacon)

local ArcWithBeaconModule = {}

--[[
Creates an arc.
--]]
function ArcWithBeaconModule.new()
    local ArcWithBeacon = {}
    ArcWithBeacon.super = Arc.new()
    ArcWithBeacon.BeamParts = {}
    ArcWithBeacon.Beacon = Beacon.new()

    --[[
    Updates the arc. Returns the part and
    position that were hit.
    --]]
    function ArcWithBeacon:Update(StartCFrame)
        --Update the arc.
        local HitPart,HitPosition = self.super:Update(StartCFrame)

        --Update the beacon.
        if HitPart then
            self.Beacon:Update(CFrame.new(HitPosition) * CFrame.new(0,0.001,0),HitPart)
        else
            self.Beacon:Hide()
        end

        --Return the arc's returns.
        return HitPart,HitPosition
    end

    --[[
    Hides the arc.
    --]]
    function ArcWithBeacon:Hide()
        self.super:Hide()
        self.Beacon:Hide()
    end

    --[[    
    Destroys the arc.
    --]]
    function ArcWithBeacon:Destroy()
        self.super:Destroy()
        self.Beacon:Destroy()
    end

    ArcWithBeacon:Hide()
    return ArcWithBeacon
end



return ArcWithBeaconModule