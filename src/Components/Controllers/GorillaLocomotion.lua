
local THUMBSTICK_INPUT_START_RADIUS = 0.4
local THUMBSTICK_INPUT_RELEASE_RADIUS = 0.2
local THUMBSTICK_MANUAL_ROTATION_ANGLE = math.rad(22.5)
local THUMBSTICK_DEADZONE_RADIUS = 0.1

local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local sauceVR = script:FindFirstAncestor("sauceVR")
local BaseController = require(sauceVR.Components.Controllers.BaseController)
local Utils = require(sauceVR.Util.Utils)

local GorillaLocomotionController = {}
GorillaLocomotionController.super = BaseController
GorillaLocomotionController.oldHeadScale = workspace.CurrentCamera.HeadScale
GorillaLocomotionController.oldGravity = workspace.Gravity

GorillaLocomotionController.partOffsets = {
    ["RightUpperLeg"] = {Part = "RUA", Offset = Vector3.new(0,.5,0)},
    ["RightLowerLeg"] = {Part = "RUA", Offset = Vector3.new(0,-.5,0)},
    ["RightUpperArm"] = {Part = "RLA", Offset = Vector3.new(0,.5,0)},
    ["RightLowerArm"] = {Part = "RLA", Offset = Vector3.new(0,-.5,0)},
    ["LeftUpperLeg"] = {Part = "LUA", Offset = Vector3.new(0,.5,0)},
    ["LeftLowerLeg"] = {Part = "LUA", Offset = Vector3.new(0,-.5,0)},
    ["LeftUpperArm"] = {Part = "LLA", Offset = Vector3.new(0,.5,0)},
    ["LeftLowerArm"] = {Part = "LLA", Offset = Vector3.new(0,-.5,0)},
    ["LeftFoot"] = {Part = "RUA", Offset = Vector3.new(0,0,0)},
    ["RightFoot"] = {Part = "LUA", Offset = Vector3.new(0,0,0)},

    ["Right Leg"] = {Part = "RUA", Offset = Vector3.new(0,-0,0)},
    ["Right Arm"]  = {Part = "RLA", Offset = Vector3.new(0,-0,0)},
    ["Left Leg"] = {Part = "LUA", Offset = Vector3.new(0,-0,0)},
    ["Left Arm"]  = {Part = "LLA", Offset = Vector3.new(0,-0,0)},
}

function GorillaLocomotionController:solveIK(originCF, targetPos, l1, l2)	
	local localized = originCF:pointToObjectSpace(targetPos)
	local localizedUnit = localized.unit
	local l3 = localized.magnitude
	local axis = Vector3.new(0, 0, -1):Cross(localizedUnit)
	local angle = math.acos(-localizedUnit.Z)
	local planeCF = originCF * CFrame.fromAxisAngle(axis, angle)
	if l3 < math.max(l2, l1) - math.min(l2, l1) then
		return planeCF * CFrame.new(0, 0,  math.max(l2, l1) - math.min(l2, l1) - l3), -math.pi/2, math.pi
	elseif l3 > l1 + l2 then
		return planeCF, math.pi/2, 0
	else
		local a1 = -math.acos((-(l2 * l2) + (l1 * l1) + (l3 * l3)) / (2 * l1 * l3))
		local a2 = math.acos(((l2  * l2) - (l1 * l1) + (l3 * l3)) / (2 * l2 * l3))
		return planeCF, a1 + math.pi/2, a2 - a1
	end
end

function GorillaLocomotionController:Enable()
    if not self.Connections then self.Connections = {} end
    self.Events = {}
    self.super.Character = self.Character
    self.super:Enable()
    self.JoystickState = { Thumbstick = Enum.KeyCode.Thumbstick2 }

    workspace.CurrentCamera.HeadScale = 1.7
    workspace.Gravity = 90

    if not self.Character then
        return
    end

    --Storing Values
    self.HandSize = self.Character.PhysicalLeftHand.Size
    self.HandPhysicalProperties = self.Character.PhysicalLeftHand.CustomPhysicalProperties

    self.RootPhysicalProperties = self.Character.Humanoid.RootPart.CustomPhysicalProperties 

    --Change Hand and RootPart Properties 
    self.Character.PhysicalLeftHand.Size = Vector3.new(1,1,.5)
    self.Character.PhysicalRightHand.Size = Vector3.new(1,1,.5)

    self.Character.PhysicalLeftHand.CustomPhysicalProperties = PhysicalProperties.new(10, 1000, -100, 100,100)
    self.Character.PhysicalRightHand.CustomPhysicalProperties = PhysicalProperties.new(10, 1000, -100, 100,100)

    self.Character.Humanoid.RootPart.CustomPhysicalProperties = PhysicalProperties.new(17, 100, 0, 100,100)

    --Create parts for gorilla arms
    self.Parts = Instance.new("Folder")
    self.Parts.Name = "Gorilla Parts"
    self.Parts.Parent = self.Character.Model

    
    local RUA, RLA, LUA, LLA, RH, LH = Instance.new("Part"), Instance.new("Part"), Instance.new("Part"), Instance.new("Part"), Instance.new("Part"), Instance.new("Part") do
        RUA.Name = "RUA"; RUA.Size = Vector3.new(1, 2, 1); RUA.CanCollide = false; RUA.Parent = self.Parts
        RLA.Name = "RLA"; RLA.Size = Vector3.new(1, 2, 1); RLA.CanCollide = false; RLA.Parent = self.Parts
        LUA.Name = "LUA"; LUA.Size = Vector3.new(1, 2, 1); LUA.CanCollide = false; LUA.Parent = self.Parts
        LLA.Name = "LLA"; LLA.Size = Vector3.new(1, 2, 1); LLA.CanCollide = false; LLA.Parent = self.Parts
        RH.Name = "RH"; RH.Size = Vector3.new(0.7, 0.7, 0.7); RH.CanCollide = false; RH.Parent = self.Parts
        LH.Name = "LH"; LH.Size = Vector3.new(0.7, 0.7, 0.7); LH.CanCollide = false;  LH.Parent = self.Parts
    end

    local torso = self.Character.Parts.UpperTorso

    local rightShoulder, RSHOULDER_C0_CACHE = Utils:createMotor(torso, RUA, self.Character.Attachments.UpperTorso.RightShoulderRigAttachment.CFrame, CFrame.new(0,1,0), "RS");
    local rightElbow, RELBOW_C0_CACHE = Utils:createMotor(RUA, RLA, CFrame.new(0,-1,0), CFrame.new(0,1,0), "RE");
    local rightWrist = Utils:createMotor(RLA, RH, CFrame.new(0,-0.5,0), CFrame.new(0,0.5,0), "RW");
    local leftShoulder, LSHOULDER_C0_CACHE = Utils:createMotor(torso, LUA, self.Character.Attachments.UpperTorso.LeftShoulderRigAttachment.CFrame, CFrame.new(0,1,0), "LS");
    local leftElbow, LELBOW_C0_CACHE = Utils:createMotor(LUA, LLA, CFrame.new(0,-1,0), CFrame.new(0,1,0), "LE");
    local leftWrist = Utils:createMotor(LLA, LH, CFrame.new(0,-0.5,0), CFrame.new(0,0.5,0), "LW");

    local RUPPER_LENGTH	= math.abs(rightShoulder.C1.Y) + math.abs(rightElbow.C0.Y)
    local RLOWER_LENGTH = math.abs(rightElbow.C1.Y) + math.abs(rightWrist.C0.Y) + math.abs(rightWrist.C1.Y)
    local LUPPER_LENGTH = math.abs(leftShoulder.C1.Y) + math.abs(leftElbow.C0.Y)
    local LLOWER_LENGTH = math.abs(leftElbow.C1.Y) + math.abs(leftWrist.C0.Y) + math.abs(leftWrist.C1.Y)

    --Handle inverse kinematics for arms
    table.insert(self.Events, RunService.Heartbeat:Connect(function()
        local RshoulderCFrame = torso.CFrame * RSHOULDER_C0_CACHE
        local RplaneCF, RshoulderAngle, RelbowAngle = self:solveIK(RshoulderCFrame, self.Character.PhysicalRightHand.Position, RUPPER_LENGTH, RLOWER_LENGTH)
        local LshoulderCFrame = torso.CFrame * LSHOULDER_C0_CACHE
        local LplaneCF, LshoulderAngle, LelbowAngle = self:solveIK(LshoulderCFrame, self.Character.PhysicalLeftHand.Position, LUPPER_LENGTH, LLOWER_LENGTH)
        rightShoulder.C0 = torso.CFrame:toObjectSpace(RplaneCF) * CFrame.Angles(RshoulderAngle, 0, 0)
        rightElbow.C0 = RELBOW_C0_CACHE * CFrame.Angles(RelbowAngle, 0, 0)
        leftShoulder.C0 = torso.CFrame:toObjectSpace(LplaneCF) * CFrame.Angles(LshoulderAngle, 0, 0)
        leftElbow.C0 = LELBOW_C0_CACHE * CFrame.Angles(LelbowAngle, 0, 0)
    end))
    
    table.insert(self.Events, RunService.Stepped:Connect(function()
        rightShoulder.Transform = CFrame.new()
        rightElbow.Transform = CFrame.new()
        rightWrist.Transform = CFrame.new()
        leftShoulder.Transform = CFrame.new()
        leftElbow.Transform = CFrame.new()
        leftWrist.Transform = CFrame.new()
    end))

    table.insert(self.Events, RunService.Stepped:Connect(function()
        self.Character.Humanoid.RootPart.CanCollide = true
    end))

    --Hide unwanted parts
    for _,part in pairs(self.Character.RealCharacter:GetChildren()) do
        if part:IsA("BasePart") and self.partOffsets[part.Name] then
            part.Transparency = 0
        end
    end

    for _,part in pairs(self.Character.RenderCharacter:GetChildren()) do
        if part:IsA("BasePart") and self.partOffsets[part.Name] then
            part.Transparency = 1
        end
    end

    for name,align in pairs(self.Character.Aligns) do
        if self.partOffsets[name] then
            align.Part1 = self.Parts[self.partOffsets[name].Part]
            align.offset = self.partOffsets[name].Offset
        end
    end
end

function GorillaLocomotionController:Disable()
    self.super:Disable()
    self.JoystickState = nil

    workspace.CurrentCamera.HeadScale = self.oldHeadScale
    workspace.Gravity = self.oldGravity

    if self.Events then
        for _,Event in pairs(self.Events) do
            Event:Disconnect()
        end
        self.Events = {}
    end

    if not self.Character then
        return
    end

    --Revert properties
    if self.Character.PhysicalLeftHand and self.Character.PhysicalRightHand then
        self.Character.PhysicalLeftHand.Size = self.HandSize
        self.Character.PhysicalRightHand.Size = self.HandSize

        self.Character.PhysicalLeftHand.CustomPhysicalProperties = self.HandPhysicalProperties
        self.Character.PhysicalRightHand.CustomPhysicalProperties = self.HandPhysicalProperties

        self.Character.Humanoid.RootPart.CustomPhysicalProperties = self.RootPhysicalProperties

        --Realign parts
        for name,align in pairs(self.Character.Aligns) do
            if self.partOffsets[name] then
                align.Reset()
            end
        end
    end

    self.Parts:Destroy()
    self.Character.Humanoid.PlatformStand = false

    for _,part in pairs(self.Character.RealCharacter:GetChildren()) do
        if part:IsA("BasePart") and self.partOffsets[part.Name] then
            part.Transparency = 1
        end
    end

    for _,part in pairs(self.Character.RenderCharacter:GetChildren()) do
        if part:IsA("BasePart") and self.partOffsets[part.Name] then
            part.Transparency = 0
        end
    end
end

function GorillaLocomotionController:UpdateVehicleSeat()
    local SeatPart = self.Character:GetHumanoidSeatPart()
    if not SeatPart or not SeatPart:IsA("VehicleSeat") then
        return
    end

    local ThumbstickPosition = VRInputService:GetThumbstickPosition(Enum.KeyCode.Thumbstick1)
    if ThumbstickPosition.Magnitude < THUMBSTICK_DEADZONE_RADIUS then
        ThumbstickPosition = Vector3.new(0,0,0)
    end
    local ForwardDirection = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0) + ThumbstickPosition.Y
    local SideDirection = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + ThumbstickPosition.X

    SeatPart.ThrottleFloat = ForwardDirection
    SeatPart.SteerFloat = SideDirection
end


function GorillaLocomotionController:UpdateCharacter()
    --Update the base character.
    if not self.Character then
        return
    end

    self.super:UpdateCharacter()
    
    if not self.ClimbingRight and not self.ClimbingLeft and not self.Character.Humanoid.Sit then
        self.Character.Humanoid.PlatformStand = true
    else
        self.Character.Humanoid.PlatformStand = false
    end

    --Snap rotate the character.
    --Update and fetch the right joystick's state.
    local DirectionState, RadiusState, StateChange = self.super:GetJoystickState(self.JoystickState)
    
    --Snap rotate the character.
    local TurnGyro = self.Character.Parts.HumanoidRootPart:FindFirstChild("TurnGyro")
    local HumanoidRootPart =  self.Character.Parts.HumanoidRootPart


    if StateChange == "Extended" then
        if not self.Character.Humanoid.Sit then
            if DirectionState == "Left" then
                --Turn the player to the left
                TurnGyro.MaxTorque = Vector3.new(0,0,0)

                local goalCF = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame) do
                    local goalTween = TweenService:Create(HumanoidRootPart,TweenInfo.new(0.1),{["CFrame"] = goalCF})
                    goalTween:Play()
                    goalTween.Completed:Wait()
                end
            elseif DirectionState == "Right" then
                --Turn the player to the right.
                TurnGyro.MaxTorque = Vector3.new(0,0,0)

                local goalCF = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, -THUMBSTICK_MANUAL_ROTATION_ANGLE, 0) * (CFrame.new(-HumanoidRootPart.Position) * HumanoidRootPart.CFrame) do
                    local goalTween = TweenService:Create(HumanoidRootPart,TweenInfo.new(0.1),{["CFrame"] = goalCF})
                    goalTween:Play()
                    goalTween.Completed:Wait()
                end
            end
            TurnGyro.MaxTorque = Vector3.new(9e9,2000,9e9)
        else
            if DirectionState == "Forward" then
                self.Character.Humanoid.Jump = true
            end
        end
    end


    --Update the vehicle seat.
    self:UpdateVehicleSeat()
end




return GorillaLocomotionController