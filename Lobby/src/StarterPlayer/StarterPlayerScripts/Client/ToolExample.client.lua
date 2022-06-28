local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Database = ReplicatedStorage:WaitForChild("Database")
local GunData = require(Database:WaitForChild("GunData"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClientInputRemote = Remotes:WaitForChild("ClientInput")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local GunFunctions = require(Utility:WaitForChild("GunFunctions"))
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))
local PlayerChecks = require(Utility:WaitForChild("PlayerChecks"))
local PlayerCooldowns = require(Utility:WaitForChild("PlayerCooldowns"))

local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local PlrServices = PlayerScripts:WaitForChild("Services")
local MouseService = require(PlrServices:WaitForChild("MouseService"))

local Tool = script.Parent
if Tool.ClassName ~= "Tool" then return false end

local LocalPlayer = Players.LocalPlayer
local Firing = false
local Equipped = false
local Focused = true

local GunScript = GunFunctions:GetGunScript(Tool.Name)

local function isAlive()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0
end

local function useTool()
    local character = LocalPlayer.Character
    if character and isAlive() then
        if PlayerChecks:CanUseTool(LocalPlayer, Tool.Name) then
            local id = tick()
            local startTime = SharedFunctions:GetTime()
            local clickPoint = MouseService:Blacklist({character})

            PlayerCooldowns:Cooldown(LocalPlayer, Tool.Name, id)

            local args = {}
            if GunScript["PreClientFire"] then
                args = GunScript:PreClientFire(LocalPlayer, clickPoint) or {}

                if not Equipped or args.dontUse then
                    PlayerCooldowns:RemoveCooldown(LocalPlayer, Tool.Name, id)
                    return false
                end
            end

            task.delay(GunData[Tool.Name].cooldown, function()
                PlayerCooldowns:RemoveCooldown(LocalPlayer, Tool.Name, id)
            end)

            clickPoint = args.overrideclickPoint or MouseService:Blacklist({character})

            ClientInputRemote:FireServer("use-tool", Tool.Name, clickPoint, startTime, args)
            if GunScript["ClientFire"] then
                task.spawn(GunScript.ClientFire, nil, LocalPlayer, clickPoint, startTime, args)
            end
        end
    end
end

local function stopTool()
    local character = LocalPlayer.Character
    local startTime = SharedFunctions:GetTime()
    local clickPoint = MouseService:Blacklist({character})

    ClientInputRemote:FireServer("stop-tool", Tool.Name, clickPoint, startTime)
    if GunScript["ClientStop"] then
        task.spawn(GunScript.ClientStop, nil, LocalPlayer, clickPoint, startTime)
    end
end

local function fireLoop()
    while isAlive() and Focused and Firing do
        useTool()
        task.wait()
    end

    stopTool()
end

Tool.Activated:Connect(function()
    if not Firing then
        Firing = true
        fireLoop()
    end
end)

Tool.Deactivated:Connect(function()
    if Firing then
        Firing = false
        ClientInputRemote:FireServer("stop-tool", Tool.Name)
        if GunScript["ClientStop"] then
            task.spawn(GunScript.ClientStop, nil, LocalPlayer)
        end
    end
end)

Tool.Equipped:Connect(function()
    Equipped = true
    ClientInputRemote:FireServer("equip-tool", Tool.Name)
    if GunScript["Equip"] then
        task.spawn(GunScript.Equip, nil, LocalPlayer)
    end
end)

Tool.Unequipped:Connect(function()
    Equipped = false
    ClientInputRemote:FireServer("unequip-tool", Tool.Name)
    if GunScript["Unequip"] then
        task.spawn(GunScript.Unequip, nil, LocalPlayer)
    end
end)

UserInputService.WindowFocused:Connect(function()
    Focused = true
end)

UserInputService.WindowFocusReleased:Connect(function()
    Focused = false
end)