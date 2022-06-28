local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local Signal
if IsServer then
    Signal = Instance.new("RemoteEvent")
    Signal.Name = "Signal"
    Signal.Parent = script
else
    Signal = script:WaitForChild("Signal")
end

local PlayerCooldowns = {}
PlayerCooldowns.Cooldowns = {}

function PlayerCooldowns:Clear(player)
    if IsServer then 
        Signal:FireAllClients("Clear", player)
    end

    PlayerCooldowns.Cooldowns[player] = nil
end

function PlayerCooldowns:Cooldown(player, cooldown, id)
    if not PlayerCooldowns.Cooldowns[player] then
        PlayerCooldowns.Cooldowns[player] = {}
    end

    if not PlayerCooldowns.Cooldowns[player][cooldown] then
        PlayerCooldowns.Cooldowns[player][cooldown] = {ready = false, id = id}
    end

    PlayerCooldowns.Cooldowns[player][cooldown].ready = false
    PlayerCooldowns.Cooldowns[player][cooldown].id = id
end

function PlayerCooldowns:RemoveCooldown(player, cooldown, id)
    if PlayerCooldowns.Cooldowns[player] and PlayerCooldowns.Cooldowns[player][cooldown] and PlayerCooldowns.Cooldowns[player][cooldown].id == id then
        PlayerCooldowns.Cooldowns[player][cooldown].ready = true
    end
end

function PlayerCooldowns:IsReady(player, cooldown)
    return not PlayerCooldowns.Cooldowns[player] or not PlayerCooldowns.Cooldowns[player][cooldown] or (PlayerCooldowns.Cooldowns[player][cooldown] and PlayerCooldowns.Cooldowns[player][cooldown].ready)
end

if not IsServer then
    Signal.OnClientEvent:Connect(function(action, ...)
        PlayerCooldowns[action](nil, ...)
    end)
end

return PlayerCooldowns