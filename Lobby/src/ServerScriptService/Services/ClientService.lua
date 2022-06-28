local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local SerServices = ServerScriptService.Services
local BanService = require(SerServices.BanService)

local Database = ReplicatedStorage.Database
local GunData = require(Database.GunData)

local Utility = ReplicatedStorage.Utility
local SharedFunctions = require(Utility.SharedFunctions)
local GunFunctions = require(Utility.GunFunctions)
local PlayerChecks = require(Utility.PlayerChecks)
local PlayerValues = require(Utility.PlayerValues)
local PlayerCooldowns = require(Utility.PlayerCooldowns)

local Remotes = ReplicatedStorage.Remotes
local ClientInputRemote = Remotes.ClientInput

local ClientService = {}
ClientInputRemote.OnServerEvent:Connect(function(client, action, tool, clickPoint, startTime, args)
    if action == "use-tool" then
        ClientService:UseTool(client, tool, clickPoint, startTime, args)
    elseif action == "stop-tool" then
        ClientService:StopTool(client, tool, clickPoint, startTime, args)
    elseif action == "equip-tool" then
        ClientService:EquipTool(client, tool, args)
    elseif action == "unequip-tool" then
        ClientService:UnequipTool(client, tool, args)
    end
end)

function ClientService:UseTool(player, tool, clickPoint, startTime)
    if PlayerChecks:CanUseTool(player, tool) then
        local gunData = GunData[tool]
        local timeDifference = math.clamp(SharedFunctions:GetTime() - startTime, 0, 2)

        PlayerCooldowns:Cooldown(player, tool)
        task.delay(gunData.cooldown - timeDifference, function()
            PlayerCooldowns:RemoveCooldown(player, tool)
        end)

        local gunScript = GunFunctions:GetGunScript(tool)
        if gunScript and gunScript["ServerFire"] then
            task.spawn(gunScript.ServerFire, self, player, clickPoint, startTime)
        end
    end
end

function ClientService:StopTool(player, tool, clickPoint, startTime)
    if PlayerChecks:IsAlive(player) then
        local gunScript = GunFunctions:GetGunScript(tool)
        if gunScript and gunScript["ServerStop"] then
            task.spawn(gunScript.ServerStop, self, player, clickPoint, startTime)
        end
    end
end
function ClientService:EquipTool(player, tool)
    if PlayerChecks:IsAlive(player) then
        local gunScript = GunFunctions:GetGunScript(tool)
        if gunScript and gunScript["Equip"] then
            task.spawn(gunScript.Equip, self, player)
        end
    end
end

function ClientService:UnequipTool(player, tool)
    if PlayerChecks:IsAlive(player) then
        local gunScript = GunFunctions:GetGunScript(tool)
        if gunScript and gunScript["Unequip"] then
            task.spawn(gunScript.Unequip, self, player)
        end
    end
end

function ClientService.InitializeClient(player, profile)
    PlayerValues:SyncProperty(player, "Team")
end

return ClientService