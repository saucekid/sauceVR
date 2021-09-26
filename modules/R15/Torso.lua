local torsoModule = {}

function torsoModule.new(LowerTorso,UpperTorso)
    local Torso = {}
    Torso.LowerTorso = LowerTorso
    Torso.UpperTorso = UpperTorso

    function Torso:GetAttachmentCFrame(Part,AttachmentName)
        local Attachment = Part:FindFirstChild(AttachmentName)
        return Attachment and Attachment.CFrame or CFrame.new()
    end

    function Torso:GetTorsoCFrames(NeckCFrame)
        local UpperTorsoCFrame = NeckCFrame * self:GetAttachmentCFrame(self.UpperTorso,"NeckRigAttachment"):inverse()
    
        local MaxTorsoBend = options.MaxTorsoBend or math.rad(10)
        local NeckTilt = math.asin(NeckCFrame.LookVector.Y)
        local LowerTorsoAngle = math.sign(NeckTilt) * math.min(math.abs(NeckTilt),MaxTorsoBend)
        local TorsoCenterCFrame = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"WaistRigAttachment") * CFrame.Angles(-LowerTorsoAngle,0,0)
        return TorsoCenterCFrame * self:GetAttachmentCFrame(self.LowerTorso,"WaistRigAttachment"):inverse(),UpperTorsoCFrame
    end
    
    function Torso:GetAppendageJointCFrames(LowerTorsoCFrame,UpperTorsoCFrame)
        return {
            RightShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"RightShoulderRigAttachment"),
            LeftShoulder = UpperTorsoCFrame * self:GetAttachmentCFrame(self.UpperTorso,"LeftShoulderRigAttachment"),
            LeftHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso,"LeftHipRigAttachment"),
            RightHip = LowerTorsoCFrame * self:GetAttachmentCFrame(self.LowerTorso,"RightHipRigAttachment"),
        }
    end

    return Torso
end




return torsoModule