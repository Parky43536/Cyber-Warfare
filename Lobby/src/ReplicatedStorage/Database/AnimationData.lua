local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Database = ReplicatedStorage:WaitForChild("Database")
local GunData = require(Database:WaitForChild("GunData"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))

local SetupRig = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Rigs"):WaitForChild("R15Rig"):Clone()
SetupRig:SetPrimaryPartCFrame(CFrame.new(1000000, 10, 10))
SetupRig.Parent = workspace

local LoadedAnimations = {}
local WaitCount = 0

local function loadAnimation(temporaryAnimation, animationId, keyframes)
    temporaryAnimation.AnimationId = "rbxassetid://"..animationId
			
    WaitCount += 1
    task.spawn(function()
        local animator = SetupRig.Humanoid:FindFirstChild("Animator") or SetupRig.Humanoid
        local track = animator:LoadAnimation(temporaryAnimation)
        repeat task.wait() until track.Length > 0
        
        local animationObject = {keyframes = {}, length = track.Length}
        for _,keyframe in pairs(keyframes) do
            table.insert(animationObject.keyframes, {name = keyframe, t = track:GetTimeOfKeyframe(keyframe)})
        end
        
        LoadedAnimations[animationId] = animationObject
        WaitCount -= 1
    end)
end

task.spawn(function()
	local temporaryAnimation = Instance.new("Animation")
	for _,gun in pairs(GunData) do
		for animation,info in pairs(gun.animations or {}) do
			loadAnimation(temporaryAnimation, tostring(info.id), info.keyframes)
		end
	end
    
	repeat task.wait() until WaitCount == 0
end)

local AnimationData = {}

function AnimationData:GetData()
	return LoadedAnimations
end

function AnimationData:WaitForAnimationKeyframe(startTime, id, keyframe, multi)
    local timeDifference = SharedFunctions:GetTime() - startTime
    local keyframeTime = AnimationData:GetAnimationKeyframeTime(id, keyframe)

    keyframeTime -= timeDifference

    task.wait(keyframeTime * (multi or 1))
end

function AnimationData:GetAnimationKeyframeTime(id, keyframe)
    local animationData = LoadedAnimations[tostring(id)]
    if animationData then
        for _,keyframeData in pairs(animationData.keyframes) do
            if keyframeData.name == keyframe then
                return keyframeData.t
            end
        end
    end

    return 0
end

function AnimationData:GetAnimationTrackLength(id)
    local animationData = LoadedAnimations[tostring(id)]
    if animationData then
        return animationData.length
    end

    return 0
end

return AnimationData