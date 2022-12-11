local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local sauceVR = script:FindFirstAncestor("sauceVR")
local Head = require(sauceVR.Components.Character.Head)
local Torso = require(sauceVR.Components.Character.Torso)
local Appendage = require(sauceVR.Components.Character.Appendage)
local FootPlanter = require(sauceVR.Components.Character.FootPlanting)

local char = {}


function char.new(CharacterModel)
    local Character = {}

    Character.TweenComponents = true
    Character.Model = CharacterModel
    
    local PreventArmDisconnection = false

    --Store the body parts.
    Character.Humanoid = CharacterModel:WaitForChild("Humanoid")
    Character.Parts = {
        Head = CharacterModel:WaitForChild("Head"),
        UpperTorso = CharacterModel:WaitForChild("UpperTorso"),
        LowerTorso = CharacterModel:WaitForChild("LowerTorso"),
        HumanoidRootPart = CharacterModel:WaitForChild("HumanoidRootPart"),
        RightUpperArm = CharacterModel:WaitForChild("RightUpperArm"),
        RightLowerArm = CharacterModel:WaitForChild("RightLowerArm"),
        RightHand = CharacterModel:WaitForChild("RightHand"),
        LeftUpperArm = CharacterModel:WaitForChild("LeftUpperArm"),
        LeftLowerArm = CharacterModel:WaitForChild("LeftLowerArm"),
        LeftHand = CharacterModel:WaitForChild("LeftHand"),
        RightUpperLeg = CharacterModel:WaitForChild("RightUpperLeg"),
        RightLowerLeg = CharacterModel:WaitForChild("RightLowerLeg"),
        RightFoot = CharacterModel:WaitForChild("RightFoot"),
        LeftUpperLeg = CharacterModel:WaitForChild("LeftUpperLeg"),
        LeftLowerLeg = CharacterModel:WaitForChild("LeftLowerLeg"),
        LeftFoot = CharacterModel:WaitForChild("LeftFoot"),
    }
    Character.Motors = {
        Neck = Character.Parts.Head:WaitForChild("Neck"):Clone(),
        Waist = Character.Parts.UpperTorso:WaitForChild("Waist"):Clone(),
        Root = Character.Parts.LowerTorso:WaitForChild("Root"):Clone(),
        RightShoulder = Character.Parts.RightUpperArm:WaitForChild("RightShoulder"):Clone(),
        RightElbow = Character.Parts.RightLowerArm:WaitForChild("RightElbow"):Clone(),
        RightWrist = Character.Parts.RightHand:WaitForChild("RightWrist"):Clone(),
        LeftShoulder = Character.Parts.LeftUpperArm:WaitForChild("LeftShoulder"):Clone(),
        LeftElbow = Character.Parts.LeftLowerArm:WaitForChild("LeftElbow"):Clone(),
        LeftWrist = Character.Parts.LeftHand:WaitForChild("LeftWrist"):Clone(),
        RightHip = Character.Parts.RightUpperLeg:WaitForChild("RightHip"):Clone(),
        RightKnee = Character.Parts.RightLowerLeg:WaitForChild("RightKnee"):Clone(),
        RightAnkle = Character.Parts.RightFoot:WaitForChild("RightAnkle"):Clone(),
        LeftHip = Character.Parts.LeftUpperLeg:WaitForChild("LeftHip"):Clone(),
        LeftKnee = Character.Parts.LeftLowerLeg:WaitForChild("LeftKnee"):Clone(),
        LeftAnkle = Character.Parts.LeftFoot:WaitForChild("LeftAnkle"):Clone(),
    }
    Character.RealMotors = {
        Neck = Character.Parts.Head:WaitForChild("Neck"),
        Waist = Character.Parts.UpperTorso:WaitForChild("Waist"),
        Root = Character.Parts.LowerTorso:WaitForChild("Root"),
        RightShoulder = Character.Parts.RightUpperArm:WaitForChild("RightShoulder"),
        RightElbow = Character.Parts.RightLowerArm:WaitForChild("RightElbow"),
        RightWrist = Character.Parts.RightHand:WaitForChild("RightWrist"),
        LeftShoulder = Character.Parts.LeftUpperArm:WaitForChild("LeftShoulder"),
        LeftElbow = Character.Parts.LeftLowerArm:WaitForChild("LeftElbow"),
        LeftWrist = Character.Parts.LeftHand:WaitForChild("LeftWrist"),
        RightHip = Character.Parts.RightUpperLeg:WaitForChild("RightHip"),
        RightKnee = Character.Parts.RightLowerLeg:WaitForChild("RightKnee"),
        RightAnkle = Character.Parts.RightFoot:WaitForChild("RightAnkle"),
        LeftHip = Character.Parts.LeftUpperLeg:WaitForChild("LeftHip"),
        LeftKnee = Character.Parts.LeftLowerLeg:WaitForChild("LeftKnee"),
        LeftAnkle = Character.Parts.LeftFoot:WaitForChild("LeftAnkle"),
    }
    Character.Attachments = {
        Head = {
            NeckRigAttachment = Character.Parts.Head:WaitForChild("NeckRigAttachment"),
        },
        UpperTorso = {
            NeckRigAttachment = Character.Parts.UpperTorso:WaitForChild("NeckRigAttachment"),
            LeftShoulderRigAttachment = Character.Parts.UpperTorso:WaitForChild("LeftShoulderRigAttachment"),
            RightShoulderRigAttachment = Character.Parts.UpperTorso:WaitForChild("RightShoulderRigAttachment"),
            WaistRigAttachment = Character.Parts.UpperTorso:WaitForChild("WaistRigAttachment"),
        },
        LowerTorso = {
            WaistRigAttachment = Character.Parts.LowerTorso:WaitForChild("WaistRigAttachment"),
            LeftHipRigAttachment = Character.Parts.LowerTorso:WaitForChild("LeftHipRigAttachment"),
            RightHipRigAttachment = Character.Parts.LowerTorso:WaitForChild("RightHipRigAttachment"),
            RootRigAttachment = Character.Parts.LowerTorso:WaitForChild("RootRigAttachment"),
        },
        HumanoidRootPart = {
            RootRigAttachment = Character.Parts.HumanoidRootPart:WaitForChild("RootRigAttachment"),
        },
        RightUpperArm = {
            RightShoulderRigAttachment = Character.Parts.RightUpperArm:WaitForChild("RightShoulderRigAttachment"),
            RightElbowRigAttachment = Character.Parts.RightUpperArm:WaitForChild("RightElbowRigAttachment"),
        },
        RightLowerArm = {
            RightElbowRigAttachment = Character.Parts.RightLowerArm:WaitForChild("RightElbowRigAttachment"),
            RightWristRigAttachment = Character.Parts.RightLowerArm:WaitForChild("RightWristRigAttachment"),
        },
        RightHand = {
            RightWristRigAttachment = Character.Parts.RightHand:WaitForChild("RightWristRigAttachment"),
        },
        LeftUpperArm = {
            LeftShoulderRigAttachment = Character.Parts.LeftUpperArm:WaitForChild("LeftShoulderRigAttachment"),
            LeftElbowRigAttachment = Character.Parts.LeftUpperArm:WaitForChild("LeftElbowRigAttachment"),
        },
        LeftLowerArm = {
            LeftElbowRigAttachment = Character.Parts.LeftLowerArm:WaitForChild("LeftElbowRigAttachment"),
            LeftWristRigAttachment = Character.Parts.LeftLowerArm:WaitForChild("LeftWristRigAttachment"),
        },
        LeftHand = {
            LeftWristRigAttachment = Character.Parts.LeftHand:WaitForChild("LeftWristRigAttachment"),
        },
        RightUpperLeg = {
            RightHipRigAttachment = Character.Parts.RightUpperLeg:WaitForChild("RightHipRigAttachment"),
            RightKneeRigAttachment = Character.Parts.RightUpperLeg:WaitForChild("RightKneeRigAttachment"),
        },
        RightLowerLeg = {
            RightKneeRigAttachment = Character.Parts.RightLowerLeg:WaitForChild("RightKneeRigAttachment"),
            RightAnkleRigAttachment = Character.Parts.RightLowerLeg:WaitForChild("RightAnkleRigAttachment"),
        },
        RightFoot = {
            RightAnkleRigAttachment = Character.Parts.RightFoot:WaitForChild("RightAnkleRigAttachment"),
            RightFootAttachment = Character.Parts.RightFoot:FindFirstChild("RightFootAttachment"),
        },
        LeftUpperLeg = {
            LeftHipRigAttachment = Character.Parts.LeftUpperLeg:WaitForChild("LeftHipRigAttachment"),
            LeftKneeRigAttachment = Character.Parts.LeftUpperLeg:WaitForChild("LeftKneeRigAttachment"),
        },
        LeftLowerLeg = {
            LeftKneeRigAttachment = Character.Parts.LeftLowerLeg:WaitForChild("LeftKneeRigAttachment"),
            LeftAnkleRigAttachment = Character.Parts.LeftLowerLeg:WaitForChild("LeftAnkleRigAttachment"),
        },
        LeftFoot = {
            LeftAnkleRigAttachment = Character.Parts.LeftFoot:WaitForChild("LeftAnkleRigAttachment"),
            LeftFootAttachment = Character.Parts.LeftFoot:FindFirstChild("LeftFootAttachment"),
        },
    }
    Character.ScaleValues = {
        BodyDepthScale = Character.Humanoid:WaitForChild("BodyDepthScale"),
        BodyWidthScale = Character.Humanoid:WaitForChild("BodyWidthScale"),
        BodyHeightScale = Character.Humanoid:WaitForChild("BodyHeightScale"),
        HeadScale = Character.Humanoid:WaitForChild("HeadScale"),
    }

    --Add the missing attachments that not all rigs have.
    if not Character.Attachments.RightFoot.RightFootAttachment then
        local NewAttachment = Instance.new("Attachment")
        NewAttachment.Position = Vector3.new(0,-Character.Parts.RightFoot.Size.Y/2,0)
        NewAttachment.Name = "RightFootAttachment"

        local OriginalPositionValue = Instance.new("Vector3Value")
        OriginalPositionValue.Name = "OriginalPosition"
        OriginalPositionValue.Value = NewAttachment.Position
        OriginalPositionValue.Parent = NewAttachment
        NewAttachment.Parent = Character.Parts.RightFoot
        Character.Attachments.RightFoot.RightFootAttachment = NewAttachment
    end
    if not Character.Attachments.LeftFoot.LeftFootAttachment then
        local NewAttachment = Instance.new("Attachment")
        NewAttachment.Position = Vector3.new(0,-Character.Parts.LeftFoot.Size.Y/2,0)
        NewAttachment.Name = "LeftFootAttachment"

        local OriginalPositionValue = Instance.new("Vector3Value")
        OriginalPositionValue.Name = "OriginalPosition"
        OriginalPositionValue.Value = NewAttachment.Position
        OriginalPositionValue.Parent = NewAttachment
        NewAttachment.Parent = Character.Parts.LeftFoot
        Character.Attachments.LeftFoot.LeftFootAttachment = NewAttachment
    end

    --Store the limbs.
    Character.Head = Head.new(Character.Parts.Head)
    Character.Torso = Torso.new(Character.Parts.LowerTorso,Character.Parts.UpperTorso)
    Character.LeftArm = Appendage.new(CharacterModel:WaitForChild("LeftUpperArm"),CharacterModel:WaitForChild("LeftLowerArm"),CharacterModel:WaitForChild("LeftHand"),"LeftShoulderRigAttachment","LeftElbowRigAttachment","LeftWristRigAttachment","LeftGripAttachment",PreventArmDisconnection)
    Character.RightArm = Appendage.new(CharacterModel:WaitForChild("RightUpperArm"),CharacterModel:WaitForChild("RightLowerArm"),CharacterModel:WaitForChild("RightHand"),"RightShoulderRigAttachment","RightElbowRigAttachment","RightWristRigAttachment","RightGripAttachment",PreventArmDisconnection)
    Character.LeftLeg = Appendage.new(CharacterModel:WaitForChild("LeftUpperLeg"),CharacterModel:WaitForChild("LeftLowerLeg"),CharacterModel:WaitForChild("LeftFoot"),"LeftHipRigAttachment","LeftKneeRigAttachment","LeftAnkleRigAttachment","LeftFootAttachment",true)
    Character.LeftLeg.InvertBendDirection = true
    Character.RightLeg = Appendage.new(CharacterModel:WaitForChild("RightUpperLeg"),CharacterModel:WaitForChild("RightLowerLeg"),CharacterModel:WaitForChild("RightFoot"),"RightHipRigAttachment","RightKneeRigAttachment","RightAnkleRigAttachment","RightFootAttachment",true)
    Character.RightLeg.InvertBendDirection = true
    Character.FootPlanter = FootPlanter:CreateSolver(CharacterModel:WaitForChild("LowerTorso"),Character.ScaleValues.BodyHeightScale)

    --Stop the character animations.
    local Animator = Character.Humanoid:FindFirstChild("Animator")
    if Animator then
        if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
            CharacterModel:WaitForChild("Animate"):Destroy()
            for _,Track in pairs(Animator:GetPlayingAnimationTracks()) do
                Track:AdjustWeight(0, 0)
                Track:Stop(0)
            end
            Animator.AnimationPlayed:Connect(function(Track)
                Track:AdjustWeight(0, 0)
                Track:Stop(0)
            end)
        else
            Animator:Destroy()
        end
    end
    Character.Humanoid.ChildAdded:Connect(function(NewAnimator)
        if NewAnimator:IsA("Animator") then
            if Players.LocalPlayer and Players.LocalPlayer.Character == CharacterModel then
                CharacterModel:WaitForChild("Animate"):Destroy()
                for _,Track in pairs(NewAnimator:GetPlayingAnimationTracks()) do
                    Track:AdjustWeight(0, 0)
                    Track:Stop(0)
                end
                NewAnimator.AnimationPlayed:Connect(function(Track)
                    Track:AdjustWeight(0, 0)
                    Track:Stop(0)
                end)
            else
                NewAnimator:Destroy()
            end
        end
    end)

    --Set up replication at 30hz.
    if Players.LocalPlayer then
        coroutine.wrap(function()
            while true do--Character.Humanoid.Health > 0 do
                --Send the new CFrames if the CFrames changed.
                if Character.LastReplicationCFrames ~= Character.ReplicationCFrames then
                    Character.LastReplicationCFrames = Character.ReplicationCFrames
                    Character:UpdateFromInputs(unpack(Character.ReplicationCFrames))
                end

                --Wait 1/30th of a second to send the next set of CFrames.
                wait(1/30)
            end
        end)()
    end



    function Character:GetHumanoidSeatPart()
        --Return nil if the Humanoid is not sitting.
        if not self.Humanoid.Sit then
            return nil
        end
    
        --Return if the seat part is defined.
        if self.Humanoid.SeatPart then
            return self.Humanoid.SeatPart
        end
    
        --Iterated through the connected parts and return if a seat exists.
        --While SeatPart may not be set, a SeatWeld does exist.
        for _,ConnectedPart in pairs(self.Parts.HumanoidRootPart:GetConnectedParts()) do
            if ConnectedPart:IsA("Seat") or ConnectedPart:IsA("VehicleSeat") then
                return ConnectedPart
            end
        end
    end
    --[[
    Sets a property. The property will either be
    set instantly or tweened depending on how
    it is configured.
    --]]
    function Character:SetCFrameProperty(Object,PropertyName,PropertyValue)
        if self.TweenComponents then
            TweenService:Create(
                Object,
                TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {
                    [PropertyName] = PropertyValue,
                }
            ):Play()
        else
            Object[PropertyName] = PropertyValue
        end
    end
    
    function Character:SetTransform(MotorName,AttachmentName,StartLimbName,EndLimbName,StartCFrame,EndCFrame)
        self:SetCFrameProperty(self.Motors[MotorName],"Transform",(StartCFrame * self.Attachments[StartLimbName][AttachmentName].CFrame):Inverse() * (EndCFrame * self.Attachments[EndLimbName][AttachmentName].CFrame))
    end
    

    function Character:UpdateFromInputs(HeadControllerCFrame,LeftHandControllerCFrame,RightHandControllerCFrame)
        --Return if the humanoid is dead.
        --[[
        if self.Humanoid.Health <= 0 then
            return
        end
        ]]
        local SeatPart = self:GetHumanoidSeatPart()
        if SeatPart then
            self:UpdateFromInputsSeated(HeadControllerCFrame,LeftHandControllerCFrame,RightHandControllerCFrame)
            return
        end
    
        --Get the CFrames.
        local HeadCFrame = self.Head:GetHeadCFrame(HeadControllerCFrame)
        local NeckCFrame = self.Head:GetNeckCFrame(HeadControllerCFrame)
        local LowerTorsoCFrame,UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
        local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame,UpperTorsoCFrame)
        local LeftUpperArmCFrame,LeftLowerArmCFrame,LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"],LeftHandControllerCFrame)
        local RightUpperArmCFrame,RightLowerArmCFrame,RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"],RightHandControllerCFrame)

        local LeftFoot,RightFoot = self.FootPlanter:GetFeetCFrames()
        local LeftUpperLegCFrame,LeftLowerLegCFrame,LeftFootCFrame = self.LeftLeg:GetAppendageCFrames(JointCFrames["LeftHip"],LeftFoot * CFrame.Angles(0,math.pi,0))
        local RightUpperLegCFrame,RightLowerLegCFrame,RightFootCFrame = self.RightLeg:GetAppendageCFrames(JointCFrames["RightHip"],RightFoot * CFrame.Angles(0,math.pi,0))
        local TargetHumanoidRootPartCFrame = LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame:Inverse()
        local ActualHumanoidRootPartCFrame = self.Parts.HumanoidRootPart.CFrame
        local HumanoidRootPartHeightDifference = ActualHumanoidRootPartCFrame.Y - TargetHumanoidRootPartCFrame.Y
        local NewTargetHumanoidRootPartCFrame = CFrame.new(TargetHumanoidRootPartCFrame.Position)
        self:SetCFrameProperty(self.Parts.HumanoidRootPart,"CFrame",CFrame.new(0,HumanoidRootPartHeightDifference,0) * NewTargetHumanoidRootPartCFrame)
        self:SetCFrameProperty(self.Motors.Root,"Transform",CFrame.new(0,-HumanoidRootPartHeightDifference,0) * (NewTargetHumanoidRootPartCFrame * self.Attachments.HumanoidRootPart.RootRigAttachment.CFrame):Inverse() * LowerTorsoCFrame * self.Attachments.LowerTorso.RootRigAttachment.CFrame)
        self:SetTransform("RightHip","RightHipRigAttachment","LowerTorso","RightUpperLeg",LowerTorsoCFrame,RightUpperLegCFrame)
        self:SetTransform("RightKnee","RightKneeRigAttachment","RightUpperLeg","RightLowerLeg",RightUpperLegCFrame,RightLowerLegCFrame)
        self:SetTransform("RightAnkle","RightAnkleRigAttachment","RightLowerLeg","RightFoot",RightLowerLegCFrame,RightFootCFrame)
        self:SetTransform("LeftHip","LeftHipRigAttachment","LowerTorso","LeftUpperLeg",LowerTorsoCFrame,LeftUpperLegCFrame)
        self:SetTransform("LeftKnee","LeftKneeRigAttachment","LeftUpperLeg","LeftLowerLeg",LeftUpperLegCFrame,LeftLowerLegCFrame)
        self:SetTransform("LeftAnkle","LeftAnkleRigAttachment","LeftLowerLeg","LeftFoot",LeftLowerLegCFrame,LeftFootCFrame)
        self:SetTransform("Neck","NeckRigAttachment","UpperTorso","Head",UpperTorsoCFrame,HeadCFrame)
        self:SetTransform("Waist","WaistRigAttachment","LowerTorso","UpperTorso",LowerTorsoCFrame,UpperTorsoCFrame)
        self:SetTransform("RightShoulder","RightShoulderRigAttachment","UpperTorso","RightUpperArm",UpperTorsoCFrame,RightUpperArmCFrame)
        self:SetTransform("RightElbow","RightElbowRigAttachment","RightUpperArm","RightLowerArm",RightUpperArmCFrame,RightLowerArmCFrame)
        self:SetTransform("RightWrist","RightWristRigAttachment","RightLowerArm","RightHand",RightLowerArmCFrame,RightHandCFrame)
        self:SetTransform("LeftShoulder","LeftShoulderRigAttachment","UpperTorso","LeftUpperArm",UpperTorsoCFrame,LeftUpperArmCFrame)
        self:SetTransform("LeftElbow","LeftElbowRigAttachment","LeftUpperArm","LeftLowerArm",LeftUpperArmCFrame,LeftLowerArmCFrame)
        self:SetTransform("LeftWrist","LeftWristRigAttachment","LeftLowerArm","LeftHand",LeftLowerArmCFrame,LeftHandCFrame)
        
        --Change real motor's transforms, too!
        for Name,Motor in pairs(self.Motors) do
            self.RealMotors[Name].Transform = Motor.Transform
        end
        
        if Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel then
            self.ReplicationCFrames = {HeadControllerCFrame,LeftHandControllerCFrame,RightHandControllerCFrame}
        end
    end

    function Character:UpdateFromInputsSeated(HeadControllerCFrame,LeftHandControllerCFrame,RightHandControllerCFrame)
        --Return if the humanoid is dead.
        --[[
        if self.Humanoid.Health <= 0 then
            return
        end
        ]]

        --Get the CFrames.
        local HeadCFrame = self.Head:GetHeadCFrame(HeadControllerCFrame)
        local NeckCFrame = self.Head:GetNeckCFrame(HeadControllerCFrame,0)
        local LowerTorsoCFrame,UpperTorsoCFrame = self.Torso:GetTorsoCFrames(NeckCFrame)
        local JointCFrames = self.Torso:GetAppendageJointCFrames(LowerTorsoCFrame,UpperTorsoCFrame)
        local LeftUpperArmCFrame,LeftLowerArmCFrame,LeftHandCFrame = self.LeftArm:GetAppendageCFrames(JointCFrames["LeftShoulder"],LeftHandControllerCFrame)
        local RightUpperArmCFrame,RightLowerArmCFrame,RightHandCFrame = self.RightArm:GetAppendageCFrames(JointCFrames["RightShoulder"],RightHandControllerCFrame)
        local EyesOffset = self.Head:GetEyesOffset()
        local HeightOffset = CFrame.new(0,(CFrame.new(0,EyesOffset.Y,0) * (HeadControllerCFrame * EyesOffset:Inverse())).Y,0)
    
        --Set the head, toros, and arm CFrames.
        self:SetCFrameProperty(self.Motors.Root,"Transform",HeightOffset * CFrame.new(0,-LowerTorsoCFrame.Y,0) * LowerTorsoCFrame)
        self:SetTransform("Neck","NeckRigAttachment","UpperTorso","Head",UpperTorsoCFrame,HeadCFrame)
        self:SetTransform("Waist","WaistRigAttachment","LowerTorso","UpperTorso",LowerTorsoCFrame,UpperTorsoCFrame)
        self:SetTransform("RightShoulder","RightShoulderRigAttachment","UpperTorso","RightUpperArm",UpperTorsoCFrame,RightUpperArmCFrame)
        self:SetTransform("RightElbow","RightElbowRigAttachment","RightUpperArm","RightLowerArm",RightUpperArmCFrame,RightLowerArmCFrame)
        self:SetTransform("RightWrist","RightWristRigAttachment","RightLowerArm","RightHand",RightLowerArmCFrame,RightHandCFrame)
        self:SetTransform("LeftShoulder","LeftShoulderRigAttachment","UpperTorso","LeftUpperArm",UpperTorsoCFrame,LeftUpperArmCFrame)
        self:SetTransform("LeftElbow","LeftElbowRigAttachment","LeftUpperArm","LeftLowerArm",LeftUpperArmCFrame,LeftLowerArmCFrame)
        self:SetTransform("LeftWrist","LeftWristRigAttachment","LeftLowerArm","LeftHand",LeftLowerArmCFrame,LeftHandCFrame)
    
        --Set the legs to be sitting.
        self.Motors.RightHip.Transform = CFrame.Angles(math.pi/2,0,math.rad(5))
        self.Motors.LeftHip.Transform = CFrame.Angles(math.pi/2,0,math.rad(-5))
        self.Motors.RightKnee.Transform = CFrame.Angles(math.rad(-10),0,0)
        self.Motors.LeftKnee.Transform = CFrame.Angles(math.rad(-10),0,0)
        self.Motors.RightAnkle.Transform = CFrame.Angles(0,0,0)
        self.Motors.LeftAnkle.Transform = CFrame.Angles(0,0,0)
    
        --Replicate the changes to the server.
        if Players.LocalPlayer and Players.LocalPlayer.Character == self.CharacterModel then
            self.ReplicationCFrames = {HeadControllerCFrame,LeftHandControllerCFrame,RightHandControllerCFrame}
        end
    end

    return Character
end



return char