local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage.Utility
local PlayerCooldowns = require(Utility.PlayerCooldowns)

local function isPointWithinRegion(point, regionObject, range)
    local distance = 10
    if range then distance = range/2 end

    return regionObject ~= nil and (point - regionObject.Position).Magnitude <= distance
end

local PlayerChecks = {}

function PlayerChecks:CanUseTool(player, tool)
    if not PlayerChecks:PlayerHasTool(player, tool) then
        return false
    end

    if not PlayerCooldowns:IsReady(player, tool) then
        return false
    end

    if not PlayerChecks:IsAlive(player) then
        return false
    end

    return true
end

local lastHits = {}
function PlayerChecks:VerifyHit(player, tool, hitPart, hitPoint, args)
    if not args then args = {} end

    if not PlayerChecks:PlayerHasTool(player, tool) then
        return false
    end

    if not args then
        if not isPointWithinRegion(hitPoint, hitPart, args.range) then
            return false
        end
    end

    if not PlayerChecks:IsAlive(player) and (not args or not args.effectServiceDamage) then
        return false
    end

    return true
end

function PlayerChecks:PlayerHasTool(player, tool)
    --[[local playerTools = PlayerValues:GetValue(player, "Tools") or {}
    local playerConsumed = PlayerValues:GetValue(player, "Consumed") or {}

    if not playerTools[tool] and not playerConsumed[tool] then
        return false
    end]]

    return true
end

function PlayerChecks:IsRagdolled(player)
    return CollectionService:HasTag(player.Character, "__Ragdoll_Active")
end

function PlayerChecks:IsAlive(player)
    return player
    and player.Character
    and player.Character:FindFirstChild("Humanoid")
    and player.Character.Humanoid.Health > 0
end

return PlayerChecks