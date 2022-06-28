local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local SharedFunctions = require(Utility:WaitForChild("SharedFunctions"))

local BanStore = DataStoreService:GetDataStore("Bans2")

local function kickPlayer(player, banInfo)
    player:Kick("You are banned from the game"
        ..".\nYour ban expires in: "..SharedFunctions:ToDHMS(banInfo.expirationTime - SharedFunctions:GetTime(true))
    )
end

local BanService = {}
function BanService:CheckPlayer(player)
    task.spawn(function()
        local playerBanInfo = BanStore:GetAsync(player.UserId)
        if playerBanInfo then
            if SharedFunctions:GetTime(true) >= playerBanInfo.expirationTime then
                BanStore:RemoveAsync(player.UserId)
            else
                kickPlayer(player, playerBanInfo)
            end
        end
    end)
end

-- by: auto, moderatorName,
-- reason: speed hacking
-- logic: walkspeed should be 25, was 60
-- expirationTime: utc + banTime
function BanService:BanPlayer(player, by, reason, logic, duration)
    local banInfo = {
        by = by,
        reason = reason,
        logic = logic,
        expirationTime = SharedFunctions:GetTime(true) + duration
    }

    kickPlayer(player, banInfo)
    BanStore:SetAsync(player.UserId, banInfo)
end

return BanService