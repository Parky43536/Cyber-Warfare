local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()
local IsClient = not IsServer
local Injections = ReplicatedStorage:WaitForChild("Injections")
local GunInjections = require(Injections:WaitForChild("GunInjections"))
local SelfData = GunInjections.GunData[script.name]
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Caster = GunInjections.FastCast.new()

print'wrthyj'

--Signal Setup--

local Signal
if IsServer then
    Signal = Instance.new("RemoteEvent")
    Signal.Name = "Signal"
    Signal.Parent = script
else
    Signal = script:WaitForChild("Signal")
end

local SerServices
local PlayerDamageService
local SelfModelAssets
local LocalPlayer
local Mouse

if IsServer then
    SerServices = ServerScriptService.Services
    PlayerDamageService = require(SerServices.PlayerDamageService)
else
    LocalPlayer = Players.LocalPlayer
    Mouse = LocalPlayer:GetMouse()
end

if Assets.GunAssets:FindFirstChild(script.Name) then
    SelfModelAssets = Assets.GunAssets:FindFirstChild(script.Name)
end

--Core--

local Gun = {}
Gun.Name = script.Name
Gun.Signal = Signal
Gun.PlayerAnimations = {}
Gun.PlayerTracks = {}

function Gun:ClientHitAlert(fromPlayer)
    assert(IsClient, "This function can only be run on the client")

    GunInjections.GunService:LocalHit(fromPlayer, Mouse)
end

function Gun:ClientHitEffect(fromPlayer, hitPart, hitPoint, direction, normal)
    local effect = SelfModelAssets.Effect:Clone()
    effect:PivotTo(CFrame.new(hitPoint, hitPoint + direction))
    effect.Parent = workspace.Dynamic

    local size = SelfData.explosionSize * 2
    local growsize = Vector3.new(size, size, size)
    local goal = {Size = growsize, Transparency = 1}
    local properties = {Time = 0.3}
    GunInjections.TweenService.tween(effect.Effect, goal, properties)

    local size = SelfData.explosionSize * 2.25
    local growsize = Vector3.new(size, size, size)
    local goal = {Size = growsize, Transparency = 0.9}
    local properties = {Time = 0.3}
    GunInjections.TweenService.tween(effect.Swirl, goal, properties)

    task.delay(0.3, function()
        for _,particle in pairs(effect:GetDescendants()) do
            if particle.ClassName == "ParticleEmitter" then
                particle.Enabled = false
            end
        end

        local size = SelfData.explosionSize * 2.5
        local growsize = Vector3.new(size, size, size)
        local goal = {Size = growsize,Transparency = 1}
        local properties = {Time = 0.2}
        GunInjections.TweenService.tween(effect.Swirl, goal, properties)
    end)

    GunInjections.AudioService:Create(SelfData.sounds.explosion.id, hitPoint, SelfData.sounds.explosion.properties)
    GunInjections.GunService:PartVisualEffect(fromPlayer, effect.Swirl, "Spin", {spinTime = 1, spinVector3 = Vector3.new(0, 360, 0)})
    game.Debris:AddItem(effect, 2)

    local size = SelfData.explosionSize * 2
    GunInjections.GunService:VisualEffect(fromPlayer, "Shockwave", {
        hitPoint = hitPoint,
        normal = normal,
        size = size + size/2
    })
end

local function callFastCast(player, character, clickPoint)
    local CastParams = RaycastParams.new()
    CastParams.FilterDescendantsInstances = {character}
    CastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local CastBehavior = GunInjections.FastCast.newBehavior()
    CastBehavior.RaycastParams = CastParams
    CastBehavior.MaxDistance = SelfData.range
    CastBehavior.HighFidelityBehavior = GunInjections.FastCast.HighFidelityBehavior.Default
    CastBehavior.Acceleration = Vector3.new(0, 0, 0)
    CastBehavior.AutoIgnoreContainer = false

    local firePosition = character:GetPivot().Position
    local direction = (clickPoint - firePosition).Unit * SelfData.range
    local speed = SelfData.projectileSpeed
    GunInjections.AudioService:Create(SelfData.sounds.fire.id, firePosition, SelfData.sounds.fire.properties)

    CastBehavior.CosmeticBulletTemplate = SelfModelAssets.Effect:Clone()
    CastBehavior.CosmeticBulletContainer = workspace.Projectiles

    --[[Dont need to check preHit if the firePosition is centered
    local playerPosition = character:GetPivot().Position
    local checkDirection = (firePosition - playerPosition).Unit * (playerPosition - firePosition).Magnitude
    local preHit = GunInjections.GunService:VerifyCast(character.PrimaryPart.Position, checkDirection, CastParams)
    if preHit then
        firePosition = playerPosition
        direction = (preHit.Position - firePosition).Unit * SelfData.range
    else
        CastBehavior.CosmeticBulletTemplate = projectile:Clone()
        CastBehavior.CosmeticBulletContainer = workspace.Projectiles
    end]]

    local castInfo = Caster:Fire(firePosition, direction, direction * speed, CastBehavior, {
        player = player,
        team = GunInjections.PlayerValues:GetValue(player, "Team"),
        damage = SelfData.damage,
        --preHit = preHit,
    })
end

function Gun:PreClientFire(player)
    assert(IsClient, "This function can only be run on the client")

    local character = player.Character
    if character then
        GunInjections.AnimationService.playAnimation(character.Humanoid, player, Gun, {
            name = "fire",
        })

        GunInjections.AnimationData:WaitForAnimationKeyframe(GunInjections.SharedFunctions:GetTime(), SelfData.animations.fire.id, "Fire")
    end
end

function Gun:ClientFire(player, clickPoint)
    assert(IsClient, "This function can only be run on the client")

    local character = player.Character
    if character then
        callFastCast(player, character, clickPoint)
    end
end

function Gun:ServerFire(player, clickPoint)
    GunInjections.PlayerRemoteService:FireAllClientsExcludeWithAction(Signal, "use", player, player, clickPoint)
end

function Gun:OnHit(fromPlayer, hitPart, hitPoint, segmentVelocity, normal)
    local hitAlert = false

    local closePlayers = GunInjections.PlayerTargetFunctions:GetPlayersInRadius(hitPoint, SelfData.explosionSize, {
        team = GunInjections.PlayerValues:GetValue(fromPlayer, "Team"),
        --excludePlayer = fromPlayer,
    })

    for _,hitPlayer in ipairs(closePlayers) do
        PlayerDamageService:Damage(hitPlayer, fromPlayer, Gun.Name, SelfData.damage, hitPart, hitPoint, {
            deathForce = segmentVelocity.Unit * SelfData.damage,
            ragdoll = {duration = 3, push = segmentVelocity.Unit * SelfData.damage, force = segmentVelocity.Unit * SelfData.damage},
            range = SelfData.explosionSize,
        })

        hitAlert = true
    end

    if hitAlert then
        GunInjections.PlayerRemoteService:FireClient(Signal, fromPlayer, "hitAlert", fromPlayer)
    end

    GunInjections.PlayerRemoteService:FireAllClientsExcludeWithAction(Signal, "hitEffect", fromPlayer, fromPlayer, hitPart, hitPoint, segmentVelocity.Unit, normal)
end

--FastCast Connections--

local function OnRayHit(cast, raycastResult, segmentVelocity)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
    local normal = raycastResult.Normal

    if not IsServer then
        if cast.StateInfo.CalledFrom == LocalPlayer and not cast.StateInfo.CustomArgs.Hit then
            cast.StateInfo.CustomArgs.Hit = true
            cast.StateInfo.DistanceCovered += SelfData.range
            Signal:FireServer("OnHit", hitPart, hitPoint, segmentVelocity.Unit, normal)
            Gun:ClientHitEffect(LocalPlayer, hitPart, hitPoint, segmentVelocity.Unit, normal)
        end
    end
end

local function OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
    if cast.StateInfo.CustomArgs.preHit then return nil end
    if cosmeticBulletObject == nil then return end

    GunInjections.GunService:PartVisualEffect(cast.StateInfo.CalledFrom, cosmeticBulletObject.Swirl, "Spin", {spinTime = 1, spinVector3 = Vector3.new(-360, 0, 0)})

    local size = cosmeticBulletObject:GetExtentsSize()

    local bulletLength = size.Z / 2
    local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
    cosmeticBulletObject:PivotTo(baseCFrame * CFrame.new(0, 0, -(length - bulletLength)))

    local closePlayers = GunInjections.PlayerTargetFunctions:GetPlayersInSize(cosmeticBulletObject:GetPivot(), size, {
        team = GunInjections.PlayerValues:GetValue(cast.StateInfo.CalledFrom, "Team"),
        excludePlayer = cast.StateInfo.CustomArgs.player,
    })

    for _,hitPlayer in ipairs(closePlayers) do
        local character = hitPlayer.Character
        if character then
            local raycastResult = {
                ["Instance"] = character.PrimaryPart, 
                ["Position"] = cosmeticBulletObject:GetPivot().Position,
                ["Normal"] = segmentVelocity.Unit,
            }
            OnRayHit(cast, raycastResult, segmentVelocity)
        end
    end
end

local function OnRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
        for _,obj in pairs(cosmeticBullet:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Transparency = 1
            end
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            end
        end
        game.Debris:AddItem(cosmeticBullet, 2)
	end
end

Caster.RayHit:Connect(OnRayHit)
Caster.LengthChanged:Connect(OnRayUpdated)
Caster.CastTerminating:Connect(OnRayTerminated)

--Equipping--

function Gun:Equip(player)
    if IsServer or (player == LocalPlayer) then
        GunInjections.GunService:Equip(player, Gun)

        if not IsServer and SelfData.mouseIcon then
            Mouse.Icon = "rbxassetid://"..GunInjections.MouseIconData[SelfData.mouseIcon or "Default"].icon
        end
    else
        GunInjections.GunService:EquipGunCosmetic(player, Gun)
    end
end

function Gun:Unequip(player, replicateToOwner)
    if IsServer or (player == LocalPlayer) then
        GunInjections.GunService:Unequip(player, Gun, replicateToOwner)

        if not IsServer and SelfData.mouseIcon then
            Mouse.Icon = ""
        end
    else
        GunInjections.GunService:UnequipGunCosmetic(player, Gun)
    end
end

if IsServer then
    Signal.OnServerEvent:Connect(function(client, action, ...)
        if GunInjections.PlayerChecks:PlayerHasTool(client, Gun.Name) then
            if action == "ServerFire" then
                GunInjections.BanService:BanPlayer(client, "Auto Moderation", "Illegally Fired ServerFire", {
                    should = false,
                    was = true
                }, 86400 * 365 * 1000)
            else
                if Gun[action] then
                    Gun[action](nil, client, ...)
                end
            end
        end
    end)
else
    Signal.OnClientEvent:Connect(function(action, ...)
        action = GunInjections.PlayerRemoteService:GetActionFromId(action)
        if action == "equip" then
            Gun:Equip(...)
        elseif action == "unequip" then
            Gun:Unequip(...)
        elseif action == "use" then
            Gun:ClientFire(...)
        elseif action == "hitEffect" then
            Gun:ClientHitEffect(...)
        elseif action == "hitAlert" then
            Gun:ClientHitAlert(...)
        end
    end)
end

print'thgegr'
return Gun