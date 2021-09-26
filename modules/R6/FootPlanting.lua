local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local AirTime = 0.09
local MaxDistance = 0.75
local TravelDistance = 1.2


local RH = CFrame.new(0.5,-1,0)
local LH = CFrame.new(-0.5,-1,0)
local Up = Vector3.new(1,0,1)


local Info = TweenInfo.new
local EasingStyle = Enum.EasingStyle.Linear
local EasingDirection = Enum.EasingDirection.Out

local New = Vector3.new


local LeftStep = false
local RightStep = false
local R2 = Instance.new("Vector3Value",workspace.Terrain)
local L2 = Instance.new("Vector3Value",workspace.Terrain)


local Ignore = {Players.LocalPlayer.Character, VRCharacter}



function RayCast(RayCastData)
	local HitResult, PositionResult = workspace:FindPartOnRayWithIgnoreList(RayCastData, Ignore)
	
	
	if HitResult and not HitResult.CanCollide then
		table.insert(Ignore, HitResult)
		local NewRayCastData = Ray.new(PositionResult, RayCastData.Direction)
		return RayCast(NewRayCastData)
	end
	
	return HitResult,PositionResult
end




function CanStep(Dist1, Dist2)
	return ((Dist1 > MaxDistance) or (Dist2 > MaxDistance)) and (not RightStep and not LeftStep)
end


function SolveIK(OriginCF, TargetPos, LegY, Character, RawCrouch)	
	local Localized = OriginCF:pointToObjectSpace(TargetPos)
	local LocalizedUnit = Localized.Unit
	local Mag = Localized.Magnitude
	local PlaneCF = OriginCF * CFrame.fromAxisAngle(Vector3.new(0, 0, -1):Cross(LocalizedUnit), math.acos(-LocalizedUnit.Z))
	local IsSitting = Character.Humanoid.Sit


	local StepCFrame = PlaneCF * CFrame.new(0, 0, LegY - (Mag)+math.max(0,Mag-(LegY)))
	local SitCFrame = math.pi / 2
	local LayCFrame = -(math.pi / 2) * (1 - (RawCrouch * 1.25))

	return IsSitting and OriginCF or RawCrouch > 0 and OriginCF or StepCFrame, RawCrouch > 0 and -SitCFrame * (1 - (RawCrouch * 1.25)) or SitCFrame
end






function TweenTargets(Character)
	local RightFooting = R2
	local LeftFooting = L2

	local Torso = Character.Torso
	local RightDistance = ((RightFooting.Value - (Torso.CFrame*RH).p)*Up).Magnitude
	local LeftDistance = ((LeftFooting.Value - (Torso.CFrame*LH).p)*Up).Magnitude
	
	if CanStep(RightDistance, LeftDistance) then
		local Velocity = Torso.Velocity
		local Move = (Velocity * Up) / (Character.Humanoid.WalkSpeed / 2.6) * TravelDistance
		local ThisAirTime = AirTime-((Velocity*Up).Magnitude/800)


		if RightDistance > LeftDistance then -- // Right Foot
			coroutine.wrap(function()
				local RayCastData = Ray.new((Torso.CFrame*RH).p + Move,New(0,-12,0))
				local HitResult, PositionResult = RayCast(RayCastData)
				RightStep = true
				TweenService:Create(RightFooting, Info(ThisAirTime,EasingStyle,EasingDirection), {Value = PositionResult}):Play()
				wait(ThisAirTime)
				TweenService:Create(RightFooting, Info(ThisAirTime,EasingStyle,EasingDirection), {Value = PositionResult}):Play()
				wait(ThisAirTime)
				RightStep = false
			end)()
		else -- // Left Foot
			coroutine.wrap(function()
				local RayCastData = Ray.new((Torso.CFrame*LH).p + Move,New(0,-12,0))
				local HitResult, PositionResult = RayCast(RayCastData)
				LeftStep = true
				TweenService:Create(LeftFooting, Info(ThisAirTime,EasingStyle,EasingDirection), {Value = PositionResult}):Play()
				wait(ThisAirTime)
				TweenService:Create(LeftFooting, Info(ThisAirTime,EasingStyle,EasingDirection), {Value = PositionResult}):Play()
				wait(ThisAirTime)
				LeftStep = false
			end)()
		end
	end
end






function UpdateLocal(RightAtt, LeftAtt, RawCrouch)
	local LocalPlayer = Players.LocalPlayer
	local Character = LocalPlayer.Character
	
	if not Character then
		return
	end


	local Torso = Character:FindFirstChild("Torso")



	local RightLeg = Character:FindFirstChild("Right Leg")
	local LeftLeg = Character:FindFirstChild("Left Leg")


	RawCrouch = RawCrouch or 0
	local RPlane,RAxis = SolveIK(Torso.CFrame * RH, R2.Value, 2, Character, RawCrouch)
	local LPlane,LAxis = SolveIK(Torso.CFrame * LH, L2.Value, 2, Character, RawCrouch)

	RightAtt.WorldCFrame = RPlane * CFrame.Angles(RAxis or 0,0,0) * CFrame.new(New(0,-1,0))
	LeftAtt.WorldCFrame = LPlane * CFrame.Angles(LAxis or 0,0,0) * CFrame.new(New(0,-1,0)) 

	TweenTargets(Character)
end




return UpdateLocal