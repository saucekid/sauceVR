local appendageModule = {}

local ArmPrecisionDepth = 4
local MinimumArmPrecision = 0.03

function appendageModule.new(UpperLimb,LowerLimb,LimbEnd,StartAttachment,LimbJointAttachment,LimbEndAttachment,LimbHoldAttachment,PreventDisconnection)
    local Appendage = {}

    Appendage.UpperLimb = UpperLimb
    Appendage.LowerLimb = LowerLimb
    Appendage.LimbEnd = LimbEnd
    Appendage.StartAttachment = StartAttachment
    Appendage.LimbJointAttachment = LimbJointAttachment
    Appendage.LimbEndAttachment = LimbEndAttachment
    Appendage.LimbHoldAttachment = LimbHoldAttachment
    Appendage.PreventDisconnection = PreventDisconnection or false

    function Appendage:GetAttachmentCFrame(Part,AttachmentName)
        local Attachment = Part:FindFirstChild(AttachmentName)
        return Attachment and Attachment.CFrame or CFrame.new()
    end

    function Appendage:SolveJoint(OriginCFrame,TargetPosition,Length1,Length2)
        local LocalizedPosition = OriginCFrame:pointToObjectSpace(TargetPosition)
        local LocalizedUnit = LocalizedPosition.unit
        local Hypotenuse = LocalizedPosition.magnitude
    
        --Get the axis and correct it if it is 0.
        local Axis = Vector3.new(0,0,-1):Cross(LocalizedUnit)
        if Axis == Vector3.new(0,0,0) then 
            if LocalizedPosition.Z < 0 then
                Axis = Vector3.new(0,0,0.001)
            else
                Axis = Vector3.new(0,0,-0.001)
            end
        end
    
        --Calculate and return the angles.
        local PlaneRotation = math.acos(-LocalizedUnit.Z)
        local PlaneCFrame = OriginCFrame * CFrame.fromAxisAngle(Axis,PlaneRotation)
        if Hypotenuse < math.max(Length2,Length1) - math.min(Length2,Length1) then
            local ShoulderAngle,ElbowAngle = -math.pi/2,math.pi
            if self.PreventDisconnection then
                return PlaneCFrame,ShoulderAngle,ElbowAngle
            else
                return PlaneCFrame * CFrame.new(0,0,math.max(Length2,Length1) - math.min(Length2,Length1) - Hypotenuse),ShoulderAngle,ElbowAngle
            end
        elseif Hypotenuse > Length1 + Length2 then
            local ShoulderAngle,ElbowAngle = math.pi/2, 0
            if self.PreventDisconnection then
                return PlaneCFrame,ShoulderAngle,ElbowAngle
            else
                return PlaneCFrame * CFrame.new(0,0,Length1 + Length2 - Hypotenuse),ShoulderAngle,ElbowAngle
            end
        else
            local Angle1 = -math.acos((-(Length2 * Length2) + (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length1 * Hypotenuse))
            local Angle2 = math.acos(((Length2  * Length2) - (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length2 * Hypotenuse))
            if self.InvertBendDirection then
                Angle1 = -Angle1
                Angle2 = -Angle2
            end
            return PlaneCFrame,Angle1 + math.pi/2,Angle2 - Angle1
        end
    end
    
    --[[
    Returns the rotation offset relative to the Y axis
    to an end CFrame.
    --]]
    function Appendage:RotationTo(StartCFrame,EndCFrame)
        local Offset = (StartCFrame:Inverse() * EndCFrame).Position
        return CFrame.Angles(math.atan2(Offset.Z,Offset.Y),0,-math.atan2(Offset.X,Offset.Y))
    end
    
    --[[
    Returns the CFrames of the appendage for
    the starting and holding CFrames. The implementation
    works, but could be improved.
    --]]
    function Appendage:GetAppendageCFrames(StartCFrame,HoldCFrame, Arm)
        --Get the attachment CFrames.
        local LimbHoldCFrame = self:GetAttachmentCFrame(self.LimbEnd,self.LimbHoldAttachment)
        local LimbEndCFrame = self:GetAttachmentCFrame(self.LimbEnd,self.LimbEndAttachment)
        local UpperLimbStartCFrame = self:GetAttachmentCFrame(self.UpperLimb,self.StartAttachment)
        local UpperLimbJointCFrame = self:GetAttachmentCFrame(self.UpperLimb,self.LimbJointAttachment)
        local LowerLimbJointCFrame = self:GetAttachmentCFrame(self.LowerLimb,self.LimbJointAttachment)
        local LowerLimbEndCFrame = self:GetAttachmentCFrame(self.LowerLimb,self.LimbEndAttachment)
        
         --Define return variables (probably a terrible practice, but its just so my code makes a tiny bit more sense!)
        local UpperLimbCFrame,LowerLimbCFrame,AppendageEndCFrame

        --Start of the arm solver
        if Arm then
            --Calculate the appendage lengths. In my own way....
            local UpperLimbLength = math.abs(UpperLimbStartCFrame.Position.Y - UpperLimbJointCFrame.Position.Y)
            local LowerLimbLength = math.abs(LowerLimbJointCFrame.Position.Y - LowerLimbEndCFrame.Position.Y)

            --Calculate the end point of the limb.
            AppendageEndCFrame = HoldCFrame * LimbHoldCFrame:Inverse()

            --Calculates the desired IK target, and the offset that it needs to take for the wrist on the lower arm to math up with the wrist on the hand.
            local RealIKTarget, WristOffset = CFrame.new((AppendageEndCFrame * LimbEndCFrame).p), CFrame.new((UpperLimbStartCFrame * UpperLimbJointCFrame:Inverse() * LowerLimbJointCFrame * LowerLimbEndCFrame:Inverse()).Position*Vector3.new(1,0,1))

            --IK target of the arm, for it to, again, match up the wrist position with the real IK target
            local IKTarget = AppendageEndCFrame * WristOffset * LimbEndCFrame

            --Init...
            local Precision = math.huge
            for z=1, ArmPrecisionDepth do -- Precision depth!
                --Solve the joint.
                local PlaneCFrame,UpperAngle,CenterAngle = self:SolveJoint(StartCFrame,IKTarget.Position,UpperLimbLength,LowerLimbLength)

                --Calculate the tranforms
                local ShoulderTransform = PlaneCFrame * CFrame.Angles(UpperAngle, 0, 0)
                local ElbowTransform = CFrame.Angles(CenterAngle, 0, 0)

                local CurrentUpperLimbCFrame = ShoulderTransform * UpperLimbStartCFrame:Inverse()
                local CurrentLowerLimbCFrame = CurrentUpperLimbCFrame * UpperLimbJointCFrame * ElbowTransform * LowerLimbJointCFrame:Inverse()
                local LimbEnd = CurrentLowerLimbCFrame * LowerLimbEndCFrame	

                local CurrentPrecision = (LimbEnd.p-RealIKTarget.p).Magnitude

                --If current precision regresses, then break to avoid making it worst :el_demo:
                if CurrentPrecision > Precision then
                    break
                end

                Precision = CurrentPrecision
                UpperLimbCFrame, LowerLimbCFrame = CurrentUpperLimbCFrame, CurrentLowerLimbCFrame

                IKTarget = RealIKTarget * CFrame.fromOrientation(LimbEnd:ToOrientation()) * WristOffset
            end	

            --If the precision doesn't reach the desired theshold, then it'll revert to the old method. Because I cba.
            if Precision < MinimumArmPrecision then
                return UpperLimbCFrame,LowerLimbCFrame,AppendageEndCFrame
            end
        end

        --Calculate the appendage lengths.
        local UpperLimbLength = (UpperLimbStartCFrame.Position - UpperLimbJointCFrame.Position).magnitude
        local LowerLimbLength = (LowerLimbJointCFrame.Position - LowerLimbEndCFrame.Position).magnitude
    
        --Calculate the end point of the limb.
        local AppendageEndJointCFrame = HoldCFrame * LimbHoldCFrame:Inverse() * LimbEndCFrame
    
        --Solve the join.
        local PlaneCFrame,UpperAngle,CenterAngle = self:SolveJoint(StartCFrame,AppendageEndJointCFrame.Position,UpperLimbLength,LowerLimbLength)
    
        --Calculate the CFrame of the limb join before and after the center angle.
        local JointUpperCFrame = PlaneCFrame * CFrame.Angles(UpperAngle,0,0) * CFrame.new(0,-UpperLimbLength,0)
        local JointLowerCFrame = JointUpperCFrame * CFrame.Angles(CenterAngle,0,0)
    
        --Calculate the part CFrames.
        --The appendage end is not calculated with hold CFrame directly since it can ignore PreventDisconnection = true.
        local UpperLimbCFrame = JointUpperCFrame * self:RotationTo(UpperLimbJointCFrame,UpperLimbStartCFrame):Inverse() * UpperLimbJointCFrame:Inverse()
        local LowerLimbCFrame = JointLowerCFrame * self:RotationTo(LowerLimbEndCFrame,LowerLimbJointCFrame):Inverse() * LowerLimbJointCFrame:Inverse()
        local AppendageEndCFrame = CFrame.new((LowerLimbCFrame * LowerLimbEndCFrame).Position) * (CFrame.new(-AppendageEndJointCFrame.Position) * AppendageEndJointCFrame) * LimbEndCFrame:Inverse()
    
        --Return the part CFrames.
        return UpperLimbCFrame,LowerLimbCFrame,AppendageEndCFrame
    end

    return Appendage
end





return appendageModule