local headModule = {}

function headModule.new(Head)
    local Head = {}
    Head.Head = Head

    function Head:GetEyesOffset()
        return self:GetAttachmentCFrame(self.Head,"FaceFrontAttachment") * CFrame.new(0,self.Head.Size.Y/4,0)
    end
    
    function Head:GetHeadCFrame(VRHeadCFrame)
        return VRHeadCFrame * self:GetEyesOffset():Inverse()
    end
    
    function Head:GetNeckCFrame(VRHeadCFrame,TargetAngle)
        --Get the base neck CFrame and angles.
        local BaseNeckCFrame = self:GetHeadCFrame(VRHeadCFrame) * self:GetAttachmentCFrame(self.Head,"NeckRigAttachment")
        local BaseNeckLookVector = BaseNeckCFrame.LookVector
        local BaseNeckLook,BaseNeckTilt = math.atan2(BaseNeckLookVector.X,BaseNeckLookVector.Z) + math.pi,math.asin(BaseNeckLookVector.Y)
    
        --Clamp the new neck tilt.
        local NewNeckTilt = 0
        local MaxNeckTilt = settings.MaxNeckTilt or math.rad(60)
        if BaseNeckTilt > MaxNeckTilt then
            NewNeckTilt = BaseNeckTilt - MaxNeckTilt
        elseif BaseNeckTilt < -MaxNeckTilt then
            NewNeckTilt = BaseNeckTilt + MaxNeckTilt
        end

        if TargetAngle then
            local RotationDifference = (BaseNeckLook - TargetAngle)
            while RotationDifference > math.pi do RotationDifference = RotationDifference - (2 * math.pi) end
            while RotationDifference < -math.pi do RotationDifference = RotationDifference + (2 * math.pi) end
    
            local MaxNeckSeatedRotation = settings.MaxNeckSeatedRotationor math.rad(60)
            if RotationDifference > MaxNeckSeatedRotation then
                BaseNeckLook = RotationDifference - MaxNeckSeatedRotation
            elseif RotationDifference < -MaxNeckSeatedRotation then
                BaseNeckLook = RotationDifference + MaxNeckSeatedRotation
            else
                BaseNeckLook = 0
            end
        else
            local MaxNeckRotation = settings.MaxNeckRotation or math.rad(35)
            if self.LastNeckRotationGlobal then
                --Determine the minimum angle difference.
                --Modulus is not used as it guarentees a positive answer, not the minimum answer, which can be negative.
                local RotationDifference = (BaseNeckLook - self.LastNeckRotationGlobal)
                while RotationDifference > math.pi do RotationDifference = RotationDifference - (2 * math.pi) end
                while RotationDifference < -math.pi do RotationDifference = RotationDifference + (2 * math.pi) end
    
                --Set the angle based on if it is over the limit or not.
                --Ignore if there is no previous stored rotation or if the rotation is "big" (like teleporting).
                if math.abs(RotationDifference) < 1.5 * MaxNeckRotation then
                    if RotationDifference > MaxNeckRotation then
                        BaseNeckLook = BaseNeckLook - MaxNeckRotation
                    elseif RotationDifference < -MaxNeckRotation then
                        BaseNeckLook = BaseNeckLook + MaxNeckRotation
                    else
                        BaseNeckLook = self.LastNeckRotationGlobal
                    end
                end
            end
        end
        self.LastNeckRotationGlobal = BaseNeckLook
    
        --Return the new neck CFrame.
        return CFrame.new(BaseNeckCFrame.Position) * CFrame.Angles(0,BaseNeckLook,0) * CFrame.Angles(NewNeckTilt,0,0)
    end

    return Head
end




return headModule