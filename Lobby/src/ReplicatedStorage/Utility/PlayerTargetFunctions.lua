local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local PlayerValues = require(Utility:WaitForChild("PlayerValues"))

local function isAlive(player)
    return player.Character
    and player.Character:FindFirstChild("Humanoid")
    and player.Character.Humanoid.Health > 0
    and player.Character.PrimaryPart ~= nil
end

local function isOnTeam(player, team)
    local playerTeam = PlayerValues:GetValue(player, "Team")
    if not playerTeam then return false end

    return playerTeam == team
end

local function checkPlayer(player, properties)
    if player == properties.excludePlayer then
        return false
    end

    if properties.ignorePlayers and properties.ignorePlayers[player] then
        return false
    end

    if not properties.includeTeam and not properties.teamOnly and isOnTeam(player, properties.team) then
        if player ~= properties.includeSelf then
            return false
        end
    end

    if properties.teamOnly and not isOnTeam(player, properties.team) then
        if player ~= properties.includeSelf then
            return false
        end
    end

    if PlayerValues:GetValue(player, "invulnerable") then
        return false
    end

    if not isAlive(player) then
        return false
    end

    return true
end

local function checkLineOfSight(from, to, raycastParams)
    local direction = (to - from).Unit * (from - to).Magnitude

    local raycastResult = workspace:Raycast(from, direction, raycastParams)

    if raycastResult and raycastResult.Instance then
        return false
    end

    return true
end

local PlayerTargetFunctions = {}

function PlayerTargetFunctions:GetClosestPlayer(position, radius, properties)
    local currentPlayers = Players:GetChildren()
    local closestPlayer = nil

    if not properties then properties = {} end

    for _,player in pairs(currentPlayers) do
        if checkPlayer(player, properties) then
            local lineOfSightProperties = properties.lineOfSight
            if not lineOfSightProperties or (lineOfSightProperties and checkLineOfSight(position + (lineOfSightProperties.offset or Vector3.new(0,0,0)), player.Character:GetPivot().Position, lineOfSightProperties.raycastParams)) then
                local playerDistance = (player.Character:GetPivot().Position - position).Magnitude
                if playerDistance <= radius then
                    if not closestPlayer then
                        if not PlayerValues:GetValue(player, "invisible") then
                            closestPlayer = player.Character
                        end
                    elseif (closestPlayer:GetPivot().Position - position).Magnitude > playerDistance then
                        if not PlayerValues:GetValue(player, "invisible") then
                            closestPlayer = player.Character
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

function PlayerTargetFunctions:GetPlayersInRadius(position, radius, properties)
    local currentPlayers = Players:GetChildren()
    local playersInRadius = {}

    radius += 2 --limbs

    if not properties then properties = {} end

    for _,player in pairs(currentPlayers) do
        if checkPlayer(player, properties) then
            if (player.Character.PrimaryPart.Position - position).Magnitude <= radius then
                table.insert(playersInRadius, player)
            end
        end
    end

    return playersInRadius
end

function PlayerTargetFunctions:GetPlayersInSize(cframe, size, properties)
    local currentPlayers = Players:GetChildren()
    local playersInSize = {}

    size += Vector3.new(4, 4, 4) --limbs

    if not properties then properties = {} end

    for _,player in pairs(currentPlayers) do
        if checkPlayer(player, properties) then
            local relativePoint = cframe:Inverse() * player.Character.PrimaryPart.Position
            local isInsideHitbox = true
            for _,axis in ipairs{"X","Y","Z"} do
                if math.abs(relativePoint[axis]) > size[axis]/2 then
                    isInsideHitbox = false
                    break
                end
            end

            if isInsideHitbox then
                table.insert(playersInSize, player)
            end
        end
    end

    return playersInSize
end

return PlayerTargetFunctions