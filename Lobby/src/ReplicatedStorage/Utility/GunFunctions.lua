local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guns = {}
local GunsFolder = ReplicatedStorage:WaitForChild("Guns")
for _,gun in pairs(GunsFolder:GetChildren()) do
    task.spawn(function()
        Guns[gun.Name] = require(gun)
    end)
end

local GunFunctions = {}

function GunFunctions:GetGunScript(gun)
	if Guns[gun] then
		return Guns[gun]
	end
end

return GunFunctions