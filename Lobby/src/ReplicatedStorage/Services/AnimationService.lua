local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))

local Database = ReplicatedStorage:WaitForChild("Database")
local AnimationData = require(Database:WaitForChild("AnimationData"))
local GunData = require(Database:WaitForChild("GunData"))

local AnimationService = {}

function AnimationService.addAnimation(humanoid, id, animationType, walkspeedScale)
    if not walkspeedScale then walkspeedScale = 16 end
    local animator = humanoid:WaitForChild("Animator")

    if animationType == "idle" then
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..id
        local track = animator:LoadAnimation(animation)

        local idleConnection = humanoid.Running:Connect(function(speed)
            if speed >= 1 then
                track:Stop()
            else
                track:Play()
            end
        end)

        local jumpConnection = humanoid.Jumping:Connect(function(jump)
            if jump == true then
                track:Stop()
            end
        end)

        local upConnection = humanoid.GettingUp:Connect(function(up)
            if up == true then
                track:Play()
            end
        end)

        if humanoid.MoveDirection.Magnitude <= 0.01 and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            track:Play()
        end

        return track, idleConnection, jumpConnection, upConnection
    elseif animationType == "run" then
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..id
        local track = animator:LoadAnimation(animation)

        local animation2 = Instance.new("Animation")
        animation2.AnimationId = "rbxassetid://"..9104207955
        local leftArmAnimation = animator:LoadAnimation(animation2)

        local movementConnection = humanoid.Running:Connect(function(speed)
            if speed >= 1 then
                track:Play(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
                leftArmAnimation:Play(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
            else
                track:Stop()
                leftArmAnimation:Stop()
            end
        end)

        local jumpConnection = humanoid.Jumping:Connect(function(jump)
            if jump == true then
                track:Play(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
                leftArmAnimation:Stop()
            end
        end)

        local upConnection = humanoid.GettingUp:Connect(function(up)
            if up == true then
                track:Stop()
                leftArmAnimation:Stop()
            end
        end)

        local walkSpeedConnect = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            track:AdjustSpeed(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
            leftArmAnimation:AdjustSpeed(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
        end)

        if humanoid.MoveDirection.Magnitude > 0 or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            track:Play(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                leftArmAnimation:Stop()
            else
                leftArmAnimation:Play(0.1, 1, humanoid.WalkSpeed / walkspeedScale)
            end
        end

        return track, leftArmAnimation, movementConnection, jumpConnection, upConnection, walkSpeedConnect
    else
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://"..id

        return animation
    end
end

function AnimationService.playAnimation(humanoid, player, Gun, args)
    local animator = humanoid:WaitForChild("Animator")

    if Gun.PlayerTracks[player] and Gun.PlayerTracks[player][args.name] then
        Gun.PlayerTracks[player][args.name]:Stop()
        Gun.PlayerTracks[player][args.name] = nil
    end

    local track = animator:LoadAnimation(Gun.PlayerAnimations[player][args.name])
    Gun.PlayerTracks[player][args.name] = track

    if args.speed and args.adjustSpeed then
        local length = AnimationData:GetAnimationTrackLength(GunData[Gun.Name].animations[args.name].id)
        track:Play(0.1, 1, length/args.speed)
    elseif args.speed then
        track:Play(0.1, 1, args.speed)
    else
        track:Play()
    end

    if args.duration then
        task.delay(args.duration, function()
            track:Stop()
            if Gun.PlayerTracks[player] and Gun.PlayerTracks[player][args.name] then
                Gun.PlayerTracks[player][args.name] = nil
            end
        end)
    end

    return track
end

function AnimationService.playAnimationSimple(humanoid, id)
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://"..id

    local animator = humanoid:WaitForChild("Animator")
    local track = animator:LoadAnimation(animation)

    track:Play()

    return track
end

return AnimationService