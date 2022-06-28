local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local Database = ReplicatedStorage:WaitForChild("Database")
local GunData = require(Database:WaitForChild("GunData"))
local MouseIconData = require(Database:WaitForChild("MouseIconData"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local PlayerRemoteService = require(Utility:WaitForChild("PlayerRemoteService"))
local PlayerValues = require(Utility:WaitForChild("PlayerValues"))
local AudioService = require(Utility:WaitForChild("AudioService"))
local TweenService = require(Utility:WaitForChild("TweenService"))

local RepServices = ReplicatedStorage:WaitForChild("Services")
local AnimationService = require(RepServices:WaitForChild("AnimationService"))

local Assets = ReplicatedStorage:WaitForChild("Assets")

local GunService = {}

local LocalPlayer

if not IsServer then
    LocalPlayer = Players.LocalPlayer
end

function GunService:Equip(player, gun)
    local SelfData = GunData[gun.Name]

    if IsServer then
        PlayerRemoteService:FireAllClientsExclude(gun.Signal, player, "equip", player)
    else
        GunService:UnequipGunCosmetic(player, gun)

        if not gun.PlayerAnimations[player] then gun.PlayerAnimations[player] = {} end
        if not gun.PlayerTracks[player] then gun.PlayerTracks[player] = {} end

        GunService:EquipGunCosmetic(player, gun)

        for animationName, properties in pairs(SelfData.animations or {}) do
            if animationName == "idle" then
                local track, connection1, connection2, connection3 = AnimationService.addAnimation(player.Character.Humanoid, properties.id, animationName)
                gun.PlayerTracks[player][animationName] = track
                table.insert(gun.PlayerConnections[player], connection1)
                table.insert(gun.PlayerConnections[player], connection2)
                table.insert(gun.PlayerConnections[player], connection3)
            elseif animationName == "run" then
                local track, leftArmTrack, connection1, connection2, connection3, connection4 = AnimationService.addAnimation(player.Character.Humanoid, properties.id, animationName, properties.walkspeedScale)
                gun.PlayerTracks[player][animationName] = track
                gun.PlayerTracks[player][animationName.."leftArm"] = leftArmTrack
                table.insert(gun.PlayerConnections[player], connection1)
                table.insert(gun.PlayerConnections[player], connection2)
                table.insert(gun.PlayerConnections[player], connection3)
                table.insert(gun.PlayerConnections[player], connection4)
            else
                local animation = AnimationService.addAnimation(player.Character.Humanoid, properties.id, animationName)
                gun.PlayerAnimations[player][animationName] = animation
            end
        end
    end
end

function GunService:Unequip(player, gun, replicateToOwner)
    if IsServer then
        if not replicateToOwner then
            PlayerRemoteService:FireAllClientsExclude(gun.Signal, player, "unequip", player)
        else
            PlayerRemoteService:FireAllClients(gun.Signal, "unequip", player)
        end
    else
        GunService:UnequipGunCosmetic(player, gun)

        local playerTracks = gun.PlayerTracks[player] or {}

        for _,track in pairs(playerTracks) do
            track:Stop()
        end
    end
end

function GunService:EquipGunCosmetic(player, gun)

end

function GunService:UnequipGunCosmetic(player, gun)

end

function GunService:VerifyCast(playerPosition, direction, castParams)
    local raycastResult = workspace:Raycast(playerPosition, direction, castParams)

    if raycastResult and raycastResult.Instance then
        return raycastResult
    end
end

local mouseTicks = {}
local hitTime = 0.35
function GunService:LocalHit(fromPlayer, mouse)
    AudioService:Create(12814239, fromPlayer, {Volume = 0.6, Pitch = 2, TimePosition = 0.03})

    local icon = string.gsub(mouse.Icon, "rbxassetid://", "")
    for _, data in pairs(MouseIconData) do
        if tostring(data.icon) == tostring(icon) then
            mouse.Icon = "rbxassetid://"..data.hitIcon
            break
        end
    end

    local currentTick = tick()
    mouseTicks[fromPlayer] = currentTick

    task.delay(hitTime, function()
        if mouse and mouseTicks[fromPlayer] == currentTick then
            local icon = string.gsub(mouse.Icon, "rbxassetid://", "")
            for _, data in pairs(MouseIconData) do
                if tostring(data.hitIcon) == tostring(icon) then
                    mouse.Icon = "rbxassetid://"..data.icon
                    break
                end
            end
        end
    end)
end

function GunService:VisualEffect(fromPlayer, effectType, args)
    if not args then args = {} end
    local hitPoint = args.hitPoint
    local normal = args.normal

    if effectType == "Shockwave" then
        local effect = Assets.Effects.Shockwave:Clone()
        effect.CFrame = CFrame.new(hitPoint, hitPoint + normal) * CFrame.Angles(math.rad(90),0,0)
        effect.CFrame += effect.CFrame.UpVector * -1
        effect.Parent = workspace.Dynamic

        for _,particle in pairs(effect:GetDescendants()) do
            if particle.ClassName == "ParticleEmitter" then
                particle.Speed = NumberRange.new(particle.Speed.Min * args.size/15, particle.Speed.Max * args.size/25)
                particle:Emit(15)
            end
        end

        AudioService:Create(152768025, args.hitPoint, {Volume = 1})

        local size = args.size
        local growsize = Vector3.new(size, 4, size)
        local goal = {Size = growsize, Transparency = 1}
        local properties = {Time = 0.3}
        TweenService.tween(effect, goal, properties)

        game.Debris:AddItem(effect, 2)
    end
end

local spins = {}
function GunService:PartVisualEffect(fromPlayer, part, effectType, args)
    if not args then args = {} end
    local spinTime = args.spinTime
    local spinVector3 = args.spinVector3

    if effectType == "Spin" then
        if not spins[part] then
            task.spawn(function()
                spins[part] = true

                while part.Parent ~= nil do
                    local goal = {Orientation = Vector3.new(part.Orientation.X + spinVector3.X, part.Orientation.Y + spinVector3.Y, part.Orientation.Z + spinVector3.Z)}
                    local properties = {Time = spinTime}
                    self.currentTween = TweenService.tween(part, goal, properties)
                    task.wait(spinTime)
                end

                spins[part] = nil
            end)
        end
    end
end

function GunService:Leap(player, position, args)
    if not args then args = {} end
    local character = player.Character

    if not args.arrivalTime then
        args.arrivalTime = SharedFunctions:ArrivalTime(character.HumanoidRootPart.Position, position)
    end

    --heightMulti is weird, negative makes it go higher
    local g = Vector3.new(0, -game.Workspace.Gravity, 0)
    local x0 = character.HumanoidRootPart.CFrame * Vector3.new(0, args.heightMulti or 2, -2)
    local v0 = (position - x0 - 0.5 * g * args.arrivalTime * args.arrivalTime) / args.arrivalTime

    character.Humanoid.PlatformStand = true
    character.HumanoidRootPart.Velocity = v0

    local bodyPos = position * Vector3.new(1, 0.001, 1)

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Parent = character.HumanoidRootPart
    bodyGyro.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
    bodyGyro.CFrame = CFrame.new(character.HumanoidRootPart.Position, bodyPos + Vector3.new(0, character.HumanoidRootPart.Position.Y, 0))

    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()

    character.HumanoidRootPart.Velocity = v0

    if not args.freeMovement then
        if character.Humanoid.AutoRotate then
            character:PivotTo(CFrame.new(character.HumanoidRootPart.Position, position))
        end
    else
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()

        if not PlayerValues:GetValue(player, "freeze") then
            character.Humanoid.PlatformStand = false
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end

        bodyGyro:Destroy()
        bodyGyro = nil
    end

    task.delay(args.arrivalTime - args.arrivalTime/10, function()
        if not args.freeMovement then
            if not PlayerValues:GetValue(player, "freeze") then
                character.Humanoid.PlatformStand = false
                character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end

            if bodyGyro then
                bodyGyro:Destroy()
            end
        end
    end)
end

function GunService:PositionVisual(placement, args)
    if RunService:IsStudio() then
        if not args then args = {} end

        local part = Instance.new("Part")
        part.Size = args.size or Vector3.new(1,1,1)
        part.BrickColor = BrickColor.new("Bright red")
        part.Anchored = true
        part.CanCollide = false
        part.Parent = workspace
        if typeof(placement) == "Vector3" then
            part.Position = placement
        else
            part.CFrame = placement
        end
    end
end

return GunService